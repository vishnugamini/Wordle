import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Bindable var settings: AppSettingsStore
    let isOverlayPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var rowShakeTrigger = 0
    @State private var shakenRow: Int?
    @State private var enteredTile: EnteredTile?
    @State private var enteredTileID = 0
    @State private var revealedRow: RevealedRow?
    @State private var revealedRowID = 0
    @State private var displayedKeyboardStates: [Character: LetterState] = [:]
    @State private var showResultSheet = false
    @State private var inputLocked = false
    private let resultSheetDelayNanoseconds: UInt64 = 120_000_000

    var body: some View {
        GeometryReader { proxy in
            let metrics = GameLayoutMetrics(size: proxy.size)

            ZStack(alignment: .bottom) {
                VStack(spacing: metrics.mainSpacing) {
                    board(metrics)

                    Text(viewModel.message.text)
                        .font(AureliaTheme.body(metrics.messageFontSize, weight: .semibold))
                        .foregroundStyle(AureliaTheme.champagne)
                        .frame(height: metrics.messageHeight)
                        .opacity(viewModel.message.text.isEmpty ? 0 : 1)
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, metrics.messageTopPadding)
                        .padding(.bottom, metrics.messageBottomPadding)
                        .accessibilityIdentifier("game.message")
                        .accessibilityLabel(viewModel.message.text.isEmpty ? "Game status" : viewModel.message.text)

                    PremiumKeyboard(
                        states: displayedKeyboardStates,
                        removedLetters: viewModel.session.removedLetters,
                        colorBlindMode: settings.colorBlindMode,
                        simplifiedAppearance: isOverlayPresented || showResultSheet,
                        keyHeight: metrics.keyboardKeyHeight,
                        rowSpacing: metrics.keyboardRowSpacing,
                        keySpacing: metrics.keyboardKeySpacing,
                        horizontalPadding: 0,
                        onLetter: appendLetter,
                        onDelete: deleteLetter,
                        onSubmit: submitGuess
                    )
                    .allowsHitTesting(!inputLocked)
                    .opacity(inputLocked ? 0.92 : 1)
                    .padding(.bottom, metrics.keyboardBottomPadding)

                    Spacer(minLength: metrics.bottomFlexSpacing)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                if showResultSheet, viewModel.session.result != nil {
                    SlideUpOverlay(onDismiss: dismissResultSheet, maxHeightRatio: 0.88, isDraggable: true) {
                        ResultSheet(viewModel: viewModel, onClose: dismissResultSheet)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(1)
                }
            }
        }
        .onAppear {
            syncPresentationState()
        }
        .onChange(of: viewModel.session.puzzleID) { _, _ in
            syncPresentationState()
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.9), value: showResultSheet)
    }

    private func board(_ metrics: GameLayoutMetrics) -> some View {
        let model = BoardRenderModel(session: viewModel.session)

        return VStack(spacing: metrics.tileGap) {
            ForEach(model.rows, id: \.rowID) { row in
                GuessRowView(
                    tiles: row.tiles,
                    row: row.rowID,
                    currentRow: viewModel.session.activeBoardRow,
                    tileGap: metrics.tileGap,
                    tileSize: metrics.tileSize,
                    shakeTrigger: rowShakeTrigger,
                    shakenRow: shakenRow,
                    revealedRow: revealedRow,
                    enteredTile: enteredTile,
                    reduceMotionEnabled: effectiveReduceMotion,
                    colorBlindMode: settings.colorBlindMode,
                    simplifiedAppearance: isOverlayPresented
                )
            }
        }
        .padding(.top, metrics.boardTopPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle board")
    }

    private func appendLetter(_ letter: Character) {
        guard !inputLocked else { return }
        let before = viewModel.session.currentGuess.count
        guard let row = viewModel.session.activeBoardRow else { return }
        viewModel.append(letter)

        guard viewModel.session.currentGuess.count > before else { return }
        enteredTileID += 1
        enteredTile = EnteredTile(id: enteredTileID, row: row, column: before)
    }

    private func deleteLetter() {
        guard !inputLocked else { return }
        viewModel.deleteLetter()
    }

    private func submitGuess() {
        guard !inputLocked else { return }
        let before = viewModel.session.guesses.count
        guard let inputRowBeforeSubmit = viewModel.session.activeBoardRow else { return }
        viewModel.submit()
        let after = viewModel.session.guesses.count

        guard after > before else {
            shakenRow = inputRowBeforeSubmit
            rowShakeTrigger += 1
            return
        }

        shakenRow = nil
        let revealedIndex = viewModel.session.isReverseMode
            ? inputRowBeforeSubmit
            : after - 1
        let nextKeyboardStates = viewModel.keyboardStates
        let shouldShowResult = viewModel.session.result != nil
        let puzzleID = viewModel.session.puzzleID

        if shouldShowResult {
            let refreshDelay = effectiveReduceMotion
                ? resultSheetDelayNanoseconds
                : revealDurationNanoseconds(tileCount: 5) + resultSheetDelayNanoseconds
            viewModel.scheduleStatsRefresh(after: refreshDelay)
        }

        if effectiveReduceMotion {
            displayedKeyboardStates = nextKeyboardStates
            if shouldShowResult {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: resultSheetDelayNanoseconds)
                    guard viewModel.session.puzzleID == puzzleID else { return }
                    showResultSheet = true
                }
            } else {
                showResultSheet = false
            }
            return
        }

        inputLocked = true
        revealedRowID += 1
        revealedRow = RevealedRow(id: revealedRowID, row: revealedIndex)
        let revealToken = revealedRowID

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: revealDurationNanoseconds(tileCount: 5))
            guard revealedRow?.id == revealToken, viewModel.session.puzzleID == puzzleID else { return }
            displayedKeyboardStates = nextKeyboardStates
            inputLocked = false
            if shouldShowResult {
                try? await Task.sleep(nanoseconds: resultSheetDelayNanoseconds)
                guard revealedRow?.id == revealToken, viewModel.session.puzzleID == puzzleID else { return }
                showResultSheet = true
            }
        }
    }

    private func syncPresentationState() {
        displayedKeyboardStates = viewModel.keyboardStates
        showResultSheet = viewModel.session.result != nil
        inputLocked = false
        shakenRow = nil
        enteredTile = nil
        revealedRow = nil
    }

    private var effectiveReduceMotion: Bool {
        settings.effectiveReduceMotion(systemReduceMotion: systemReduceMotion)
    }

    private func revealDurationNanoseconds(tileCount: Int) -> UInt64 {
        let tileDelay = 0.18
        let anticipation = 0.07
        let flipOut = 0.2
        let rebound = 0.24
        let settle = 0.14
        let total = max(0, Double(tileCount - 1)) * tileDelay + anticipation + flipOut + rebound + settle
        return UInt64(total * 1_000_000_000)
    }

    private func dismissResultSheet() {
        showResultSheet = false
    }
}

private struct BoardRenderModel {
    let rows: [RenderRow]

    init(session: GameSession) {
        rows = session.isReverseMode
            ? Self.makeReverseRows(session: session)
            : Self.makeStandardRows(session: session)
    }

    private static func makeStandardRows(session: GameSession) -> [RenderRow] {
        let currentRow = session.activeBoardRow

        return (0..<6).map { row in
            let tiles: [RenderTile]

            if row < session.guesses.count {
                let guess = session.guesses[row]
                let letters = Array(guess.guess.uppercased())
                tiles = (0..<5).map { column in
                    RenderTile(
                        row: row,
                        column: column,
                        letter: letters[column],
                        state: guess.states[column],
                        isActive: false,
                        isHinted: false
                    )
                }
            } else {
                tiles = (0..<5).map { column in
                    let isHinted = row == currentRow && session.revealedHintIndices.contains(column)
                    return RenderTile(
                        row: row,
                        column: column,
                        letter: row == currentRow ? session.currentGuessLetter(at: column) : nil,
                        state: isHinted ? .correct : .unknown,
                        isActive: row == currentRow,
                        isHinted: isHinted
                    )
                }
            }

            return RenderRow(rowID: row, tiles: tiles)
        }
    }

    private static func makeReverseRows(session: GameSession) -> [RenderRow] {
        let hiddenWords = session.reverseHiddenChain
        let answerLetters = Array(session.answer.uppercased())
        let currentLetters = Array(session.currentGuess)
        let activeRow = session.reverseActiveRow

        return (0..<6).map { row in
            let tiles: [RenderTile]

            if row == 5 {
                tiles = (0..<5).map { column in
                    RenderTile(
                        row: row,
                        column: column,
                        letter: answerLetters[column],
                        state: .correct,
                        isActive: false,
                        isHinted: false
                    )
                }
            } else if hiddenWords.indices.contains(row) {
                let hiddenWord = hiddenWords[row]
                let solvedEvaluation = session.reverseGuess(forRow: row)
                let isSolved = solvedEvaluation != nil
                let evaluation = solvedEvaluation ?? GameEngine(maxGuesses: 6, wordLength: 5, validator: PreviewValidator()).evaluate(guess: hiddenWord, answer: session.answer)
                let letters = Array((solvedEvaluation?.guess ?? hiddenWord).uppercased())

                tiles = (0..<5).map { column in
                    let draftLetter = activeRow == row && column < currentLetters.count ? currentLetters[column] : nil
                    return RenderTile(
                        row: row,
                        column: column,
                        letter: isSolved ? letters[column] : draftLetter,
                        state: evaluation.states[column],
                        isActive: activeRow == row,
                        isHinted: false
                    )
                }
            } else {
                tiles = (0..<5).map { column in
                    RenderTile(
                        row: row,
                        column: column,
                        letter: nil,
                        state: .unknown,
                        isActive: false,
                        isHinted: false
                    )
                }
            }

            return RenderRow(rowID: row, tiles: tiles)
        }
    }
}

private struct RenderRow: Equatable {
    let rowID: Int
    let tiles: [RenderTile]
}

private struct RenderTile: Identifiable, Equatable {
    let row: Int
    let column: Int
    let letter: Character?
    let state: LetterState
    let isActive: Bool
    let isHinted: Bool

    var id: Int { row * 10 + column }
}

private struct EnteredTile: Equatable {
    let id: Int
    let row: Int
    let column: Int
}

private struct RevealedRow: Equatable {
    let id: Int
    let row: Int
}

private struct GuessRowView: View, Equatable {
    let tiles: [RenderTile]
    let row: Int
    let currentRow: Int?
    let tileGap: CGFloat
    let tileSize: CGSize
    let shakeTrigger: Int
    let shakenRow: Int?
    let revealedRow: RevealedRow?
    let enteredTile: EnteredTile?
    let reduceMotionEnabled: Bool
    let colorBlindMode: Bool
    let simplifiedAppearance: Bool

    nonisolated static func == (lhs: GuessRowView, rhs: GuessRowView) -> Bool {
        guard lhs.tiles == rhs.tiles,
              lhs.row == rhs.row,
              lhs.currentRow == rhs.currentRow
        else {
            return false
        }

        if lhs.row == lhs.shakenRow || rhs.row == rhs.shakenRow {
            guard lhs.shakeTrigger == rhs.shakeTrigger else { return false }
        }

        guard lhs.shakenRow == rhs.shakenRow else { return false }

        let lhsReveal = lhs.revealedRow?.row == lhs.row ? lhs.revealedRow : nil
        let rhsReveal = rhs.revealedRow?.row == rhs.row ? rhs.revealedRow : nil
        guard lhsReveal == rhsReveal else { return false }

        let lhsEntry = lhs.enteredTile?.row == lhs.row ? lhs.enteredTile : nil
        let rhsEntry = rhs.enteredTile?.row == rhs.row ? rhs.enteredTile : nil
        return lhsEntry == rhsEntry
    }

    var body: some View {
        HStack(spacing: tileGap) {
            ForEach(tiles) { tile in
                AnimatedTileView(
                    tile: tile,
                    size: tileSize,
                    entryTrigger: enteredTile?.row == tile.row && enteredTile?.column == tile.column ? enteredTile : nil,
                    revealTrigger: revealedRow?.row == tile.row ? revealedRow : nil,
                    reduceMotionEnabled: reduceMotionEnabled,
                    colorBlindMode: colorBlindMode,
                    simplifiedAppearance: simplifiedAppearance
                )
                .equatable()
            }
        }
        .modifier(ShakeEffect(shakes: row == shakenRow ? CGFloat(shakeTrigger) : 0))
        .animation(reduceMotionEnabled ? nil : .linear(duration: 0.26), value: shakeTrigger)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Guess row \(row + 1)")
    }
}

private struct AnimatedTileView: View, Equatable {
    let tile: RenderTile
    let size: CGSize
    let entryTrigger: EnteredTile?
    let revealTrigger: RevealedRow?
    let reduceMotionEnabled: Bool
    let colorBlindMode: Bool
    let simplifiedAppearance: Bool
    @State private var entryScale: CGFloat = 1
    @State private var flipAngle: Double = 0
    @State private var flipScale: CGFloat = 1
    @State private var flipYOffset: CGFloat = 0
    @State private var displayedState: LetterState = .unknown

    nonisolated static func == (lhs: AnimatedTileView, rhs: AnimatedTileView) -> Bool {
        lhs.tile == rhs.tile &&
            lhs.size == rhs.size &&
            lhs.entryTrigger == rhs.entryTrigger &&
            lhs.revealTrigger == rhs.revealTrigger
    }

    var body: some View {
        let content = ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tileFill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderStyle, lineWidth: borderWidth)
                )
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(highlight)
                        .opacity(highlightOpacity)
                        .allowsHitTesting(false)
                }
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)

            Text(tile.letter.map(String.init) ?? "")
                .font(AureliaTheme.display(size.height * 0.62, weight: .black))
                .foregroundStyle(displayedState == .unknown ? AureliaTheme.parchment : .white)
                .minimumScaleFactor(0.7)
                .shadow(
                    color: .black.opacity(simplifiedAppearance ? 0 : (displayedState == .unknown ? 0.12 : 0.26)),
                    radius: simplifiedAppearance || tile.letter == nil ? 0 : 2,
                    y: simplifiedAppearance ? 0 : 1
                )
        }
        content.modifier(tileMotion)
    }

    private var tileMotion: some ViewModifier {
        TileMotionModifier(
            size: size,
            entryScale: entryScale,
            flipScale: flipScale,
            flipYOffset: flipYOffset,
            flipAngle: flipAngle,
            accessibilityValue: accessibilityValue,
            row: tile.row,
            column: tile.column,
            tileState: tile.state,
            displayedState: displayedState,
            reduceMotionEnabled: reduceMotionEnabled,
            entryTrigger: entryTrigger,
            revealTrigger: revealTrigger,
            simplifiedAppearance: simplifiedAppearance,
            onAppear: { displayedState = tile.state },
            onTileStateChange: { newState in
                if shouldAnimateReveal(to: newState) {
                    return
                }

                if abs(flipAngle) < 1 {
                    displayedState = newState
                }
            },
            onEntryTrigger: {
                runEntryAnimation()
            },
            onRevealTrigger: { trigger in
                runRevealAnimation(triggerID: trigger.id)
            }
        )
    }

    private var tileFill: some ShapeStyle {
        switch displayedState {
        case .unknown:
            let baseOpacity = tile.letter == nil ? 0.58 : 0.88
            let entryBoost = tile.letter == nil ? 0 : max(0, entryScale - 1) * 0.18
            return AnyShapeStyle(AureliaTheme.unknownTile.opacity(baseOpacity + entryBoost))
        case .absent:
            return AnyShapeStyle(AureliaTheme.absentTile)
        case .present:
            return AnyShapeStyle(
                LinearGradient(
                    colors: displayedState.gradientColors(colorBlindMode: colorBlindMode) ?? AureliaTheme.presentGradient(colorBlindMode: colorBlindMode),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .correct:
            return AnyShapeStyle(
                LinearGradient(
                    colors: displayedState.gradientColors(colorBlindMode: colorBlindMode) ?? AureliaTheme.correctGradient(colorBlindMode: colorBlindMode),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var cornerRadius: CGFloat {
        min(20, size.height * 0.25)
    }

    private var highlight: some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white.opacity(tile.letter == nil ? 0.03 : 0.14),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var highlightOpacity: CGFloat {
        guard !simplifiedAppearance else { return 0 }
        let base: CGFloat = tile.letter == nil ? 0.75 : 1
        return base + revealDepth * 0.42 + max(0, entryScale - 1) * 0.32
    }

    private var borderStyle: some ShapeStyle {
        if tile.isActive {
            return AnyShapeStyle(AureliaTheme.activeTileBorder)
        }
        if displayedState != .unknown {
            return AnyShapeStyle(.white.opacity(0.24))
        }
        return AnyShapeStyle(tile.letter == nil ? .white.opacity(0.12) : AureliaTheme.unknownTileBorder)
    }

    private var borderWidth: CGFloat {
        if tile.isActive {
            return 2
        }
        return tile.letter == nil && displayedState == .unknown ? 1 : 1.35
    }

    private var shadowColor: Color {
        guard !simplifiedAppearance else { return .clear }
        switch displayedState {
        case .unknown:
            return .black.opacity(tile.letter == nil ? 0 : 0.2)
        case .absent:
            return .black.opacity(0.24)
        case .present:
            return displayedState.color(colorBlindMode: colorBlindMode).opacity(0.2)
        case .correct:
            return displayedState.color(colorBlindMode: colorBlindMode).opacity(0.22)
        }
    }

    private var shadowRadius: CGFloat {
        guard !simplifiedAppearance else { return 0 }
        if tile.letter == nil && displayedState == .unknown { return 0 }
        let base: CGFloat = displayedState == .unknown ? 1.5 : 8
        return base + revealDepth * 8
    }

    private var shadowY: CGFloat {
        guard !simplifiedAppearance else { return 0 }
        let base: CGFloat = displayedState == .unknown ? 1 : 5
        return base + revealDepth * 4
    }

    private var revealDepth: CGFloat {
        min(1, CGFloat(abs(flipAngle) / 94))
    }

    private func shouldAnimateReveal(to newState: LetterState) -> Bool {
        guard !reduceMotionEnabled, newState != .unknown else { return false }
        return revealTrigger?.row == tile.row
    }

    private var accessibilityValue: String {
        if let letter = tile.letter {
            if tile.isHinted {
                return "\(String(letter)), revealed hint"
            }
            if displayedState == .unknown {
                return "\(String(letter)), entered"
            }
            return "\(String(letter)), \(displayedState.accessibilityDescription)"
        }

        return tile.isActive ? "Empty tile" : "Unused tile"
    }

    private func runEntryAnimation() {
        entryScale = 0.9
        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.63, blendDuration: 0.02)) {
            entryScale = 1
        }
    }

    private func runRevealAnimation(triggerID: Int) {
        let tileDelay = UInt64(Double(tile.column) * 0.18 * 1_000_000_000)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: tileDelay)
            guard revealTrigger?.id == triggerID else { return }

            withAnimation(.easeInOut(duration: 0.07)) {
                flipScale = 1.015
                flipYOffset = -2
            }

            try? await Task.sleep(nanoseconds: 70_000_000)
            guard revealTrigger?.id == triggerID else { return }

            withAnimation(.timingCurve(0.3, 0.03, 0.67, 1, duration: 0.2)) {
                flipAngle = -94
                flipScale = 0.965
                flipYOffset = -7
            }

            try? await Task.sleep(nanoseconds: 200_000_000)
            guard revealTrigger?.id == triggerID else { return }
            displayedState = tile.state

            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                flipAngle = 7
                flipScale = 1.01
                flipYOffset = 0
            }

            try? await Task.sleep(nanoseconds: 140_000_000)
            guard revealTrigger?.id == triggerID else { return }

            withAnimation(.spring(response: 0.24, dampingFraction: 0.92)) {
                flipAngle = 0
                flipScale = 1
                flipYOffset = 0
            }
        }
    }
}

private struct PreviewValidator: WordValidator {
    func isValid(_ word: String) -> Bool { true }
}

private struct TileMotionModifier: ViewModifier {
    let size: CGSize
    let entryScale: CGFloat
    let flipScale: CGFloat
    let flipYOffset: CGFloat
    let flipAngle: Double
    let accessibilityValue: String
    let row: Int
    let column: Int
    let tileState: LetterState
    let displayedState: LetterState
    let reduceMotionEnabled: Bool
    let entryTrigger: EnteredTile?
    let revealTrigger: RevealedRow?
    let simplifiedAppearance: Bool
    let onAppear: () -> Void
    let onTileStateChange: (LetterState) -> Void
    let onEntryTrigger: () -> Void
    let onRevealTrigger: (RevealedRow) -> Void

    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .scaleEffect(entryScale * flipScale)
            .offset(y: flipYOffset)
            .rotation3DEffect(.degrees(flipAngle), axis: (x: 1, y: 0.06, z: 0), perspective: 0.78)
            .modifier(TileCompositingModifier(isEnabled: !simplifiedAppearance))
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("game.tile.\(row).\(column)")
            .accessibilityLabel("Row \(row + 1), column \(column + 1)")
            .accessibilityValue(accessibilityValue)
            .onAppear {
                onAppear()
            }
            .onChange(of: tileState) { _, newState in
                onTileStateChange(newState)
            }
            .onChange(of: entryTrigger) { _, newValue in
                guard newValue != nil, !reduceMotionEnabled else { return }
                onEntryTrigger()
            }
            .onChange(of: revealTrigger) { _, newValue in
                guard let trigger = newValue, !reduceMotionEnabled else {
                    onTileStateChange(displayedState)
                    return
                }
                onRevealTrigger(trigger)
            }
    }
}

private struct TileCompositingModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.compositingGroup()
        } else {
            content
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(shakes * .pi * 6) * 8, y: 0))
    }
}

private struct GameLayoutMetrics {
    let size: CGSize

    var compactness: CGFloat {
        if size.height < 560 { return 1 }
        if size.height > 690 { return 0 }
        return (690 - size.height) / 130
    }

    var mainSpacing: CGFloat { interpolate(from: 8, to: 5) }
    var boardTopPadding: CGFloat { interpolate(from: 1, to: 0) }
    var tileGap: CGFloat { interpolate(from: 6, to: 4) }
    var keyboardRowSpacing: CGFloat { interpolate(from: 8, to: 6) }
    var keyboardKeySpacing: CGFloat { interpolate(from: 5, to: 4) }
    var keyboardBottomPadding: CGFloat { interpolate(from: 0, to: 0) }
    var messageHeight: CGFloat { interpolate(from: 16, to: 12) }
    var messageTopPadding: CGFloat { interpolate(from: 1, to: 0) }
    var messageBottomPadding: CGFloat { interpolate(from: 1, to: 0) }
    var bottomFlexSpacing: CGFloat { 0 }
    var messageFontSize: CGFloat { interpolate(from: 13, to: 11) }
    var keyboardKeyHeight: CGFloat { interpolate(from: 60, to: 46) }

    var tileSize: CGSize {
        let maxWidth = (size.width - tileGap * 4) / 5
        let heightBudget = size.height
            - keyboardHeight
            - messageHeight
            - messageTopPadding
            - messageBottomPadding
            - boardTopPadding
            - mainSpacing * 4
            - keyboardBottomPadding
            - bottomFlexSpacing
        let maxHeight = (heightBudget - tileGap * 5) / 6
        let tileHeight = min(interpolate(from: 96, to: 58), maxHeight)
        let tileWidth = min(interpolate(from: 84, to: 54), maxWidth, tileHeight * 0.96)
        return CGSize(width: max(52, tileWidth), height: max(54, tileHeight))
    }

    private var keyboardHeight: CGFloat {
        keyboardKeyHeight * 3 + keyboardRowSpacing * 2
    }

    private func interpolate(from expanded: CGFloat, to compact: CGFloat) -> CGFloat {
        expanded + (compact - expanded) * compactness
    }
}

private struct ResultSheet: View {
    @Bindable var viewModel: GameViewModel
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            resultBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    resultHero

                    if showsAnswer {
                        answerCard
                    }

                    if let resultSummary, !showsAnswer {
                        summaryCard(resultSummary)
                    }

                    if showsAnswer {
                        definitionSection
                    }

                    actionBar
                }
                .padding(.horizontal, 20)
                .padding(.top, 42)
                .padding(.bottom, 56)
            }

            closeButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground(AureliaTheme.sheetBackground)
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AureliaTheme.parchment)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.10), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(AureliaTheme.champagne.opacity(0.18), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Close")
                .accessibilityIdentifier("result.close")
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.top, 14)
        .padding(.horizontal, 18)
    }

    private var resultTitle: String {
        if viewModel.mode == .reverse, viewModel.session.result?.won == true {
            return "Exquisite, completed in \(viewModel.completedSessionMinutesText)"
        }

        return viewModel.session.result?.won == true ? "Exquisite." : "The word was"
    }

    private var showsAnswer: Bool {
        !(viewModel.mode == .reverse && viewModel.session.result?.won == true)
    }

    private var resultSummary: String? {
        if viewModel.mode == .reverse, viewModel.session.result?.won == true {
            return nil
        }

        if viewModel.session.result?.won == true {
            if viewModel.mode == .reverse {
                return "Reconstructed in \(viewModel.session.result?.attempts ?? 0) rows."
            }
            return "Solved in \(viewModel.session.result?.attempts ?? 0)."
        }

        return viewModel.mode == .reverse ? "Another hidden chain is ready." : "A new puzzle awaits in practice."
    }

    private var resultBackdrop: some View {
        ZStack(alignment: .top) {
            AureliaTheme.sheetBackground

            LinearGradient(
                colors: [
                    heroAccent.opacity(isWin ? 0.24 : 0.16),
                    AureliaTheme.panelDeep.opacity(0.12),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
            .frame(maxHeight: .infinity, alignment: .top)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.10),
                            .clear,
                            .black.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)
                .opacity(0.45)
        }
        .ignoresSafeArea()
    }

    private var resultHero: some View {
        VStack(spacing: 14) {
            statusPill

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.white.opacity(0.07))
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(heroAccent.opacity(0.30), lineWidth: 1)
                            .rotationEffect(.degrees(45))
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [heroAccent.opacity(0.34), Color.clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: 56
                        )
                    )
                    .frame(width: 86, height: 86)

                Circle()
                    .fill(heroBadgeFill)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.32), lineWidth: 1)
                    )
                    .shadow(color: heroShadowColor.opacity(0.24), radius: 14, x: 0, y: 8)

                Image(systemName: heroSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(heroSymbolStyle)
            }

            VStack(spacing: 10) {
                Text(resultTitle)
                    .font(AureliaTheme.display(40, weight: .semibold))
                    .foregroundStyle(AureliaTheme.parchment)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                Text(heroSubtitle)
                    .font(AureliaTheme.body(16, weight: .medium))
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: heroSymbol)
                .font(.system(size: 12, weight: .bold))

            Text(statusText)
                .font(AureliaTheme.body(11, weight: .heavy))
                .textCase(.uppercase)
        }
        .foregroundStyle(AureliaTheme.actionText)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(AureliaTheme.hero, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.26), lineWidth: 1))
        .shadow(color: heroShadowColor.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private var answerCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(answerEyebrow)
                    .font(AureliaTheme.body(12, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(AureliaTheme.champagne)

                Spacer(minLength: 12)

                if let resultSummary {
                    Text(resultSummary)
                        .font(AureliaTheme.body(13, weight: .bold))
                        .foregroundStyle(AureliaTheme.tertiaryText.opacity(0.78))
                        .multilineTextAlignment(.trailing)
                }
            }

            HStack(spacing: 8) {
                ForEach(Array(viewModel.session.answer.uppercased().enumerated()), id: \.offset) { _, letter in
                    Text(String(letter))
                        .font(AureliaTheme.display(34, weight: .black))
                        .foregroundStyle(answerLetterStyle)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(answerTileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(answerTileStroke, lineWidth: 1)
                        )
                        .shadow(color: heroShadowColor.opacity(isWin ? 0.16 : 0.08), radius: 12, x: 0, y: 7)
                }
            }

            HStack(spacing: 10) {
                resultMetric(icon: "line.3.horizontal.decrease.circle.fill", title: "Rows", value: attemptsText)

                Divider()
                    .frame(height: 28)
                    .overlay(AureliaTheme.champagne.opacity(0.22))

                resultMetric(icon: modeIcon, title: "Mode", value: modeText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AureliaTheme.panel.opacity(0.96),
                            AureliaTheme.panelDeep.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AureliaTheme.champagne.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: AureliaTheme.obsidian.opacity(0.22), radius: 24, x: 0, y: 14)
    }

    private func summaryCard(_ summary: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.session.result?.won == true ? "sparkles" : "book.closed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AureliaTheme.champagne)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.08), in: Circle())

            Text(summary)
                .font(AureliaTheme.body(16, weight: .medium))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.84))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(17)
        .background(AureliaTheme.panel.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AureliaTheme.champagne.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var definitionSection: some View {
        switch viewModel.resultDefinitionState {
        case .idle:
            EmptyView()
        case .loading:
            definitionCard(
                title: "Meaning",
                body: "Looking up the dictionary definition...",
                isLoading: true
            )
        case .loaded(let definition):
            VStack(spacing: 12) {
                ForEach(Array(definition.meanings.enumerated()), id: \.offset) { index, meaning in
                    definitionCard(
                        title: meaning.partOfSpeech.map { "Meaning \(index + 1) • \($0.capitalized)" } ?? "Meaning \(index + 1)",
                        body: meaning.text
                    )
                }
            }
        case .unavailable:
            definitionCard(
                title: "Meaning",
                body: "No dictionary definition is available right now."
            )
        }
    }

    private func definitionCard(title: String, body: String, isLoading: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AureliaTheme.champagne.opacity(0.13))
                    .frame(width: 36, height: 36)

                if isLoading {
                    ProgressView()
                        .tint(AureliaTheme.champagne)
                        .scaleEffect(0.78)
                } else {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AureliaTheme.champagne)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(AureliaTheme.body(12, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(AureliaTheme.champagne)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(body)
                    .font(AureliaTheme.body(15, weight: .medium))
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.82))
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .background(AureliaTheme.panel.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AureliaTheme.champagne.opacity(0.14), lineWidth: 1)
        )
    }

    private var actionBar: some View {
        HStack(spacing: 14) {
            if let shareText = viewModel.shareText {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("result.share")
                .buttonStyle(PrimaryPremiumButtonStyle())
            }

            if viewModel.mode != .daily {
                Button {
                    close()
                    if viewModel.mode == .practice {
                        viewModel.startFreshPractice()
                    } else {
                        viewModel.startFreshReverse()
                    }
                } label: {
                    Label(nextButtonTitle, systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("result.nextWord")
                .buttonStyle(PrimaryPremiumButtonStyle())
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private var heroSymbol: String {
        viewModel.session.result?.won == true ? "sparkles" : "book.closed.fill"
    }

    private var isWin: Bool {
        viewModel.session.result?.won == true
    }

    private var statusText: String {
        if viewModel.mode == .reverse, isWin {
            return "Reverse Solved"
        }

        return isWin ? "Victory" : "Reveal"
    }

    private var heroSubtitle: String {
        if viewModel.mode == .reverse, viewModel.session.result?.won == true {
            return "A flawless reconstruction with every hidden rung restored."
        }

        if viewModel.session.result?.won == true {
            return "The board landed beautifully. Here’s the final word and its meaning."
        }

        return "The round is complete. Take the reveal, learn the word, and jump into another."
    }

    private var answerEyebrow: String {
        isWin ? "Final word" : "Answer"
    }

    private var attemptsText: String {
        guard let attempts = viewModel.session.result?.attempts else { return "-" }
        return "\(attempts)/6"
    }

    private var modeText: String {
        switch viewModel.mode {
        case .daily:
            return "Daily"
        case .practice:
            return "Practice"
        case .reverse:
            return "Reverse"
        }
    }

    private var modeIcon: String {
        switch viewModel.mode {
        case .daily:
            return "calendar"
        case .practice:
            return "shuffle"
        case .reverse:
            return "arrow.triangle.2.circlepath"
        }
    }

    private var heroBadgeFill: AnyShapeStyle {
        if viewModel.session.result?.won == true {
            return AnyShapeStyle(AureliaTheme.hero)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [Color(red: 0.34, green: 0.28, blue: 0.24), AureliaTheme.panelDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var heroSymbolStyle: AnyShapeStyle {
        if viewModel.session.result?.won == true {
            return AnyShapeStyle(AureliaTheme.ink)
        }

        return AnyShapeStyle(AureliaTheme.parchment)
    }

    private var heroShadowColor: Color {
        viewModel.session.result?.won == true ? AureliaTheme.champagne : .black
    }

    private var heroAccent: Color {
        viewModel.session.result?.won == true ? AureliaTheme.champagne : AureliaTheme.slate
    }

    private var answerTileFill: AnyShapeStyle {
        if isWin {
            return AnyShapeStyle(AureliaTheme.hero)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    AureliaTheme.panelDeep.opacity(0.96),
                    AureliaTheme.charcoal.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var answerLetterStyle: AnyShapeStyle {
        isWin ? AnyShapeStyle(AureliaTheme.actionText) : AnyShapeStyle(AureliaTheme.parchment)
    }

    private var answerTileStroke: Color {
        isWin ? .white.opacity(0.26) : AureliaTheme.champagne.opacity(0.20)
    }

    private var nextButtonTitle: String {
        viewModel.mode == .reverse ? "Next Reverse" : "Next Word"
    }

    private func resultMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AureliaTheme.champagne)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AureliaTheme.body(10, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(AureliaTheme.tertiaryText.opacity(0.62))

                Text(value)
                    .font(AureliaTheme.body(14, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PrimaryPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AureliaTheme.body(15, weight: .bold))
            .foregroundStyle(AureliaTheme.actionText)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(AureliaTheme.hero, in: Capsule())
            .compositingGroup()
            .shadow(color: .clear, radius: 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct SecondaryPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AureliaTheme.body(15, weight: .bold))
            .foregroundStyle(AureliaTheme.parchment)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
            .compositingGroup()
            .shadow(color: .clear, radius: 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
