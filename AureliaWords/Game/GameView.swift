import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Bindable var settings: AppSettingsStore
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var rowShakeTrigger = 0
    @State private var enteredTile: EnteredTile?
    @State private var enteredTileID = 0
    @State private var revealedRow: RevealedRow?
    @State private var revealedRowID = 0
    @State private var displayedKeyboardStates: [Character: LetterState] = [:]
    @State private var showResultSheet = false
    @State private var inputLocked = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = GameLayoutMetrics(size: proxy.size)

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
                    colorBlindMode: settings.colorBlindMode,
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
        }
        .onAppear {
            syncPresentationState()
        }
        .onChange(of: viewModel.session.puzzleID) { _, _ in
            syncPresentationState()
        }
        .sheet(isPresented: $showResultSheet) {
            if viewModel.session.result != nil {
                ResultSheet(viewModel: viewModel)
                    .presentationDetents([.height(360)])
                    .presentationCornerRadius(34)
            }
        }
    }

    private func board(_ metrics: GameLayoutMetrics) -> some View {
        let model = BoardRenderModel(session: viewModel.session)

        return VStack(spacing: metrics.tileGap) {
            ForEach(model.rows, id: \.rowID) { row in
                GuessRowView(
                    tiles: row.tiles,
                    row: row.rowID,
                    currentRow: viewModel.session.guesses.count,
                    tileGap: metrics.tileGap,
                    tileSize: metrics.tileSize,
                    shakeTrigger: rowShakeTrigger,
                    revealedRow: revealedRow,
                    enteredTile: enteredTile,
                    reduceMotionEnabled: effectiveReduceMotion,
                    colorBlindMode: settings.colorBlindMode
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
        let row = viewModel.session.guesses.count
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
        viewModel.submit()
        let after = viewModel.session.guesses.count

        guard after > before else {
            rowShakeTrigger += 1
            return
        }

        let revealedIndex = after - 1
        let nextKeyboardStates = viewModel.keyboardStates
        let shouldShowResult = viewModel.session.result != nil
        let puzzleID = viewModel.session.puzzleID

        if effectiveReduceMotion {
            displayedKeyboardStates = nextKeyboardStates
            showResultSheet = shouldShowResult
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
                showResultSheet = true
            }
        }
    }

    private func syncPresentationState() {
        displayedKeyboardStates = viewModel.keyboardStates
        showResultSheet = viewModel.session.result != nil
        inputLocked = false
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
}

private struct BoardRenderModel {
    let rows: [RenderRow]

    init(session: GameSession) {
        let currentRow = session.guesses.count
        let currentLetters = Array(session.currentGuess)

        rows = (0..<6).map { row in
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
                        isActive: false
                    )
                }
            } else {
                tiles = (0..<5).map { column in
                    RenderTile(
                        row: row,
                        column: column,
                        letter: row == currentRow && column < currentLetters.count ? currentLetters[column] : nil,
                        state: .unknown,
                        isActive: row == currentRow
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
    let currentRow: Int
    let tileGap: CGFloat
    let tileSize: CGSize
    let shakeTrigger: Int
    let revealedRow: RevealedRow?
    let enteredTile: EnteredTile?
    let reduceMotionEnabled: Bool
    let colorBlindMode: Bool

    nonisolated static func == (lhs: GuessRowView, rhs: GuessRowView) -> Bool {
        guard lhs.tiles == rhs.tiles,
              lhs.row == rhs.row,
              lhs.currentRow == rhs.currentRow
        else {
            return false
        }

        if lhs.row == lhs.currentRow || rhs.row == rhs.currentRow {
            guard lhs.shakeTrigger == rhs.shakeTrigger else { return false }
        }

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
                    colorBlindMode: colorBlindMode
                )
                .equatable()
            }
        }
        .modifier(ShakeEffect(shakes: row == currentRow ? CGFloat(shakeTrigger) : 0))
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
        ZStack {
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
                .shadow(color: .black.opacity(displayedState == .unknown ? 0.12 : 0.26), radius: tile.letter == nil ? 0 : 2, y: 1)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(entryScale * flipScale)
        .offset(y: flipYOffset)
        .rotation3DEffect(.degrees(flipAngle), axis: (x: 1, y: 0.06, z: 0), perspective: 0.78)
        .compositingGroup()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("game.tile.\(tile.row).\(tile.column)")
        .accessibilityLabel("Row \(tile.row + 1), column \(tile.column + 1)")
        .accessibilityValue(accessibilityValue)
        .onAppear {
            displayedState = tile.state
        }
        .onChange(of: tile.state) { _, newState in
            if shouldAnimateReveal(to: newState) {
                return
            }

            if abs(flipAngle) < 1 {
                displayedState = newState
            }
        }
        .onChange(of: entryTrigger) { _, newValue in
            guard newValue != nil, !reduceMotionEnabled else { return }
            runEntryAnimation()
        }
        .onChange(of: revealTrigger) { _, newValue in
            guard let trigger = newValue, !reduceMotionEnabled else {
                displayedState = tile.state
                return
            }
            runRevealAnimation(triggerID: trigger.id)
        }
    }

    private var cornerRadius: CGFloat {
        min(20, size.height * 0.25)
    }

    private var tileFill: some ShapeStyle {
        switch displayedState {
        case .unknown:
            return AnyShapeStyle(tile.letter == nil ? AureliaTheme.panelDeep.opacity(0.58) : AureliaTheme.panelDeep.opacity(0.88))
        case .absent:
            return AnyShapeStyle(AureliaTheme.charcoal)
        case .present:
            return AnyShapeStyle(
                LinearGradient(
                    colors: displayedState.gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.champagne, AureliaTheme.bronze],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .correct:
            return AnyShapeStyle(
                LinearGradient(
                    colors: displayedState.gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.mint, AureliaTheme.emerald],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
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
        let base: CGFloat = tile.letter == nil ? 0.75 : 1
        return base + revealDepth * 0.42
    }

    private var borderStyle: some ShapeStyle {
        if displayedState != .unknown {
            return AnyShapeStyle(.white.opacity(0.24))
        }
        return AnyShapeStyle(tile.letter == nil ? .white.opacity(0.12) : AureliaTheme.champagne.opacity(0.78))
    }

    private var borderWidth: CGFloat {
        tile.letter == nil && displayedState == .unknown ? 1 : 1.35
    }

    private var shadowColor: Color {
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
        if tile.letter == nil && displayedState == .unknown { return 0 }
        let base: CGFloat = displayedState == .unknown ? 3 : 8
        return base + revealDepth * 8
    }

    private var shadowY: CGFloat {
        let base: CGFloat = displayedState == .unknown ? 2 : 5
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
            if displayedState == .unknown {
                return "\(String(letter)), entered"
            }
            return "\(String(letter)), \(displayedState.accessibilityDescription)"
        }

        return tile.isActive ? "Empty tile" : "Unused tile"
    }

    private func runEntryAnimation() {
        entryScale = 0.84
        withAnimation(.spring(response: 0.16, dampingFraction: 0.58)) {
            entryScale = 1.08
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.spring(response: 0.18, dampingFraction: 0.82)) {
                entryScale = 1
            }
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AureliaTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Text(viewModel.session.result?.won == true ? "Exquisite." : "The word was")
                    .font(AureliaTheme.display(36, weight: .semibold))
                    .foregroundStyle(AureliaTheme.parchment)

                Text(viewModel.session.answer.uppercased())
                    .font(AureliaTheme.display(44, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(AureliaTheme.hero)

                Text(viewModel.session.result?.won == true ? "Solved in \(viewModel.session.result?.attempts ?? 0)." : "A new puzzle awaits in practice.")
                    .font(AureliaTheme.body(16))
                    .foregroundStyle(.white.opacity(0.72))

                HStack {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("result.close")
                        .buttonStyle(SecondaryPremiumButtonStyle())

                    if viewModel.mode == .practice {
                        Button("Next Word") {
                            dismiss()
                            viewModel.startFreshPractice()
                        }
                        .accessibilityIdentifier("result.nextWord")
                        .buttonStyle(PrimaryPremiumButtonStyle())
                    }
                }
            }
            .padding(24)
        }
    }
}

struct PrimaryPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AureliaTheme.body(15, weight: .bold))
            .foregroundStyle(AureliaTheme.ink)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(AureliaTheme.hero, in: Capsule())
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
