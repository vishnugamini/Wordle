import SwiftUI

struct PremiumKeyboard: View {
    let states: [Character: LetterState]
    var keyHeight: CGFloat = 48
    var rowSpacing: CGFloat = 9
    var keySpacing: CGFloat = 7
    var horizontalPadding: CGFloat = 10
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: keySpacing) {
                    if index == 2 {
                        actionKey("Enter", width: actionKeyWidth(58), action: onSubmit)
                    }

                    ForEach(Array(row), id: \.self) { letter in
                        key(String(letter), state: states[letter] ?? .unknown) {
                            onLetter(letter)
                        }
                    }

                    if index == 2 {
                        actionKey("⌫", width: actionKeyWidth(46), action: onDelete)
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    private func key(_ title: String, state: LetterState, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AureliaTheme.body(keyFontSize, weight: .bold))
                .foregroundStyle(state == .unknown ? AureliaTheme.parchment : .white)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(keyBackground(state), in: RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func actionKey(_ title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AureliaTheme.body(max(11, keyFontSize - 2), weight: .bold))
                .foregroundStyle(AureliaTheme.ink)
                .frame(width: width, height: keyHeight)
                .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var keyFontSize: CGFloat {
        keyHeight < 44 ? 13 : 15
    }

    private var keyCornerRadius: CGFloat {
        min(13, keyHeight * 0.28)
    }

    private func actionKeyWidth(_ width: CGFloat) -> CGFloat {
        width * (keyHeight / 48)
    }

    private func keyBackground(_ state: LetterState) -> some ShapeStyle {
        switch state {
        case .unknown:
            return AnyShapeStyle(.white.opacity(0.08))
        case .absent:
            return AnyShapeStyle(AureliaTheme.slate.gradient)
        case .present:
            return AnyShapeStyle(AureliaTheme.champagne.gradient)
        case .correct:
            return AnyShapeStyle(AureliaTheme.emerald.gradient)
        }
    }
}
