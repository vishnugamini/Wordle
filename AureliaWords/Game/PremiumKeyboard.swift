import SwiftUI

struct PremiumKeyboard: View {
    let states: [Character: LetterState]
    var removedLetters: Set<Character> = []
    var colorBlindMode: Bool = false
    var simplifiedAppearance: Bool = false
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
                        key(String(letter), state: states[letter] ?? .unknown, isRemoved: removedLetters.contains(letter)) {
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

    private func key(_ title: String, state: LetterState, isRemoved: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AureliaTheme.body(keyFontSize, weight: .bold))
                .foregroundStyle(isRemoved || state != .unknown ? .white : AureliaTheme.unknownKeyText)
                .shadow(
                    color: .black.opacity(simplifiedAppearance || (!isRemoved && state == .unknown) ? 0 : 0.22),
                    radius: simplifiedAppearance || (!isRemoved && state == .unknown) ? 0 : 2,
                    y: simplifiedAppearance ? 0 : 1
                )
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background {
                    keyBackground(state, isRemoved: isRemoved)
                }
                .overlay(alignment: .topLeading) {
                    if (isRemoved || state != .unknown) && !simplifiedAppearance {
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
                .overlay(RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous).stroke(.white.opacity(isRemoved || state != .unknown ? 0.24 : 0.13), lineWidth: 1))
                .shadow(
                    color: simplifiedAppearance ? .clear : keyShadow(state, isRemoved: isRemoved),
                    radius: simplifiedAppearance || (!isRemoved && state == .unknown) ? 0 : 7,
                    x: 0,
                    y: simplifiedAppearance || (!isRemoved && state == .unknown) ? 0 : 5
                )
        }
        .accessibilityIdentifier("keyboard.key.\(title)")
        .accessibilityLabel(title)
        .accessibilityValue(isRemoved ? "Removed wrong letter" : state.accessibilityDescription)
        .accessibilityHint(isRemoved ? "This wrong letter has been removed" : "Adds \(title) to the current guess")
        .disabled(isRemoved)
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
                .foregroundStyle(AureliaTheme.actionText)
                .frame(width: width, height: keyHeight)
                .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if !simplifiedAppearance {
                        RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.38), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
                .shadow(color: simplifiedAppearance ? .clear : AureliaTheme.champagne.opacity(0.2), radius: simplifiedAppearance ? 0 : 8, x: 0, y: simplifiedAppearance ? 0 : 5)
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
    private func keyBackground(_ state: LetterState, isRemoved: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)

        if isRemoved {
            shape
                .fill(
                    LinearGradient(
                        colors: [AureliaTheme.cobalt, AureliaTheme.slate, AureliaTheme.charcoal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    if !simplifiedAppearance {
                        shape
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.14), .clear],
                                    center: .topLeading,
                                    startRadius: 2,
                                    endRadius: keyHeight * 0.9
                                )
                            )
                    }
                }
        } else {
            switch state {
        case .unknown:
            shape
                .fill(AureliaTheme.unknownKeyFill.opacity(simplifiedAppearance ? 0.92 : 1))
        case .absent:
            shape
                .fill(
                    LinearGradient(
                        colors: AureliaTheme.absentKeyGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    if !simplifiedAppearance {
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
                }
        case .present:
            shape
                .fill(
                    LinearGradient(
                        colors: state.gradientColors(colorBlindMode: colorBlindMode) ?? AureliaTheme.presentGradient(colorBlindMode: colorBlindMode),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .correct:
            shape
                .fill(
                    LinearGradient(
                        colors: state.gradientColors(colorBlindMode: colorBlindMode) ?? AureliaTheme.correctGradient(colorBlindMode: colorBlindMode),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }

    private func keyShadow(_ state: LetterState, isRemoved: Bool) -> Color {
        if isRemoved {
            return AureliaTheme.cobalt.opacity(0.22)
        }

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
    var pressedScale: CGFloat = 0.975

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
