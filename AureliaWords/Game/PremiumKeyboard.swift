import SwiftUI

struct PremiumKeyboard: View {
    let states: [Character: LetterState]
    var colorBlindMode: Bool = false
    var keyHeight: CGFloat = 52
    var rowSpacing: CGFloat = 9
    var keySpacing: CGFloat = 6
    var horizontalPadding: CGFloat = 6
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: keySpacing) {
                    if index == 2 {
                        actionKey(
                            "Enter",
                            width: actionKeyWidth(66),
                            identifier: "keyboard.enter",
                            accessibilityLabel: "Submit guess",
                            action: onSubmit
                        )
                    }

                    ForEach(Array(row), id: \.self) { letter in
                        key(String(letter), state: states[letter] ?? .unknown) {
                            onLetter(letter)
                        }
                    }

                    if index == 2 {
                        actionKey(
                            "⌫",
                            width: actionKeyWidth(54),
                            identifier: "keyboard.delete",
                            accessibilityLabel: "Delete letter",
                            action: onDelete
                        )
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 6)
    }

    private func key(_ title: String, state: LetterState, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AureliaTheme.body(keyFontSize, weight: .bold))
                .foregroundStyle(state == .unknown ? AureliaTheme.parchment : .white)
                .shadow(color: .black.opacity(state == .unknown ? 0 : 0.22), radius: state == .unknown ? 0 : 2, y: 1)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background {
                    keyBackground(state)
                }
                .overlay(alignment: .topLeading) {
                    if state != .unknown {
                        RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.16), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous).stroke(.white.opacity(state == .unknown ? 0.13 : 0.24), lineWidth: 1))
                .shadow(color: keyShadow(state), radius: state == .unknown ? 0 : 7, x: 0, y: state == .unknown ? 0 : 5)
        }
        .accessibilityIdentifier("keyboard.key.\(title)")
        .accessibilityLabel(title)
        .accessibilityValue(state.accessibilityDescription)
        .accessibilityHint("Adds \(title) to the current guess")
        .buttonStyle(PremiumKeyButtonStyle())
    }

    private func actionKey(
        _ title: String,
        width: CGFloat,
        identifier: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AureliaTheme.body(max(11, keyFontSize - 2), weight: .bold))
                .foregroundStyle(AureliaTheme.ink)
                .frame(width: width, height: keyHeight)
                .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous))
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.38), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
                .shadow(color: AureliaTheme.champagne.opacity(0.2), radius: 8, x: 0, y: 5)
        }
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(PremiumKeyButtonStyle(pressedScale: 0.94))
    }

    private var keyFontSize: CGFloat {
        keyHeight < 48 ? 14 : 16
    }

    private var keyCornerRadius: CGFloat {
        min(15, keyHeight * 0.28)
    }

    private func actionKeyWidth(_ width: CGFloat) -> CGFloat {
        width * (keyHeight / 52)
    }

    @ViewBuilder
    private func keyBackground(_ state: LetterState) -> some View {
        let shape = RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)

        switch state {
        case .unknown:
            shape
                .fill(AureliaTheme.panelDeep.opacity(0.78))
        case .absent:
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.19, blue: 0.22),
                            Color(red: 0.46, green: 0.13, blue: 0.16),
                            Color(red: 0.24, green: 0.07, blue: 0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.10), .clear],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: keyHeight * 0.9
                            )
                        )
                }
        case .present:
            shape
                .fill(
                    LinearGradient(
                        colors: state.gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.champagne, AureliaTheme.bronze],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .correct:
            shape
                .fill(
                    LinearGradient(
                        colors: state.gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.mint, AureliaTheme.emerald],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func keyShadow(_ state: LetterState) -> Color {
        switch state {
        case .unknown:
            return .clear
        case .absent:
            return AureliaTheme.ruby.opacity(0.16)
        case .present:
            return state.color(colorBlindMode: colorBlindMode).opacity(0.18)
        case .correct:
            return state.color(colorBlindMode: colorBlindMode).opacity(0.2)
        }
    }
}

private struct PremiumKeyButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
