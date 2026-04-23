import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let metrics = GameLayoutMetrics(size: proxy.size)

            VStack(spacing: metrics.mainSpacing) {
                header(metrics)
                board(metrics)

                Text(viewModel.message.text)
                    .font(AureliaTheme.body(metrics.messageFontSize, weight: .semibold))
                    .foregroundStyle(AureliaTheme.champagne)
                    .frame(height: metrics.messageHeight)
                    .opacity(viewModel.message.text.isEmpty ? 0 : 1)
                    .transition(.opacity.combined(with: .scale))

                Spacer(minLength: 0)

                PremiumKeyboard(
                    states: viewModel.keyboardStates,
                    keyHeight: metrics.keyboardKeyHeight,
                    rowSpacing: metrics.keyboardRowSpacing,
                    keySpacing: metrics.keyboardKeySpacing,
                    horizontalPadding: 0,
                    onLetter: viewModel.append,
                    onDelete: viewModel.deleteLetter,
                    onSubmit: viewModel.submit
                )
                .padding(.bottom, metrics.keyboardBottomPadding)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.78), value: viewModel.session.guesses.count)
        .sheet(isPresented: Binding(get: { viewModel.session.result != nil }, set: { _ in })) {
            ResultSheet(viewModel: viewModel)
                .presentationDetents([.height(360)])
                .presentationCornerRadius(34)
        }
    }

    private func header(_ metrics: GameLayoutMetrics) -> some View {
        VStack(spacing: metrics.headerSpacing) {
            Text(viewModel.mode.title.uppercased())
                .font(AureliaTheme.body(metrics.eyebrowFontSize, weight: .bold))
                .tracking(2.4)
                .foregroundStyle(AureliaTheme.champagne)

            Text(viewModel.mode == .daily ? "The Daily Cut" : "Atelier Practice")
                .font(AureliaTheme.display(metrics.titleFontSize, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(viewModel.mode.subtitle)
                .font(AureliaTheme.body(metrics.subtitleFontSize))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private func board(_ metrics: GameLayoutMetrics) -> some View {
        VStack(spacing: metrics.tileGap) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: metrics.tileGap) {
                    ForEach(0..<5, id: \.self) { column in
                        TileView(
                            tile: tile(row: row, column: column),
                            delay: Double(column) * 0.07,
                            size: metrics.tileSize
                        )
                    }
                }
            }
        }
        .padding(.top, metrics.boardTopPadding)
    }

    private func tile(row: Int, column: Int) -> TileState {
        if row < viewModel.session.guesses.count {
            let guess = viewModel.session.guesses[row]
            return TileState(letter: Array(guess.guess.uppercased())[column], state: guess.states[column])
        }

        if row == viewModel.session.guesses.count {
            let letters = Array(viewModel.session.currentGuess)
            return TileState(letter: column < letters.count ? letters[column] : nil, state: .unknown)
        }

        return TileState(letter: nil, state: .unknown)
    }
}

private struct TileView: View {
    let tile: TileState
    let delay: Double
    let size: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(tile.state.color.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(tile.letter == nil ? .white.opacity(0.12) : AureliaTheme.champagne.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: tile.state == .unknown ? .clear : tile.state.color.opacity(0.28), radius: 14, y: 8)

            Text(tile.letter.map(String.init) ?? "")
                .font(AureliaTheme.display(size.height * 0.45, weight: .bold))
                .foregroundStyle(tile.state == .unknown ? AureliaTheme.parchment : .white)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(tile.letter == nil ? 0.98 : 1)
        .rotation3DEffect(.degrees(tile.state == .unknown || reduceMotion ? 0 : 360), axis: (x: 1, y: 0, z: 0))
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.72).delay(delay), value: tile.state)
    }
}

private struct GameLayoutMetrics {
    let size: CGSize

    var compactness: CGFloat {
        if size.height < 560 { return 1 }
        if size.height > 690 { return 0 }
        return (690 - size.height) / 130
    }

    var mainSpacing: CGFloat { interpolate(from: 18, to: 8) }
    var headerSpacing: CGFloat { interpolate(from: 6, to: 3) }
    var boardTopPadding: CGFloat { interpolate(from: 8, to: 2) }
    var tileGap: CGFloat { interpolate(from: 9, to: 5) }
    var keyboardRowSpacing: CGFloat { interpolate(from: 9, to: 5) }
    var keyboardKeySpacing: CGFloat { interpolate(from: 7, to: 4) }
    var keyboardBottomPadding: CGFloat { interpolate(from: 2, to: 0) }
    var messageHeight: CGFloat { interpolate(from: 22, to: 18) }
    var eyebrowFontSize: CGFloat { interpolate(from: 12, to: 10) }
    var titleFontSize: CGFloat { interpolate(from: 32, to: 25) }
    var subtitleFontSize: CGFloat { interpolate(from: 14, to: 12) }
    var messageFontSize: CGFloat { interpolate(from: 13, to: 11) }
    var keyboardKeyHeight: CGFloat { interpolate(from: 48, to: 38) }

    var tileSize: CGSize {
        let maxWidth = (size.width - tileGap * 4) / 5
        let heightBudget = size.height
            - headerHeight
            - keyboardHeight
            - messageHeight
            - boardTopPadding
            - mainSpacing * 4
            - keyboardBottomPadding
        let maxHeight = (heightBudget - tileGap * 5) / 6
        let tileHeight = min(interpolate(from: 62, to: 46), maxHeight)
        let tileWidth = min(interpolate(from: 57, to: 43), maxWidth, tileHeight * 0.93)
        return CGSize(width: max(39, tileWidth), height: max(43, tileHeight))
    }

    private var headerHeight: CGFloat {
        eyebrowFontSize + titleFontSize + subtitleFontSize + headerSpacing * 2 + 12
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
                        .buttonStyle(SecondaryPremiumButtonStyle())

                    if viewModel.mode == .practice {
                        Button("Next Word") {
                            dismiss()
                            viewModel.startFreshPractice()
                        }
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
