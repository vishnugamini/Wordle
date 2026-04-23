import SwiftUI

enum AureliaTheme {
    static let ink = Color(red: 0.05, green: 0.045, blue: 0.04)
    static let obsidian = Color(red: 0.09, green: 0.08, blue: 0.07)
    static let parchment = Color(red: 0.94, green: 0.86, blue: 0.72)
    static let champagne = Color(red: 0.92, green: 0.72, blue: 0.43)
    static let bronze = Color(red: 0.56, green: 0.36, blue: 0.18)
    static let ruby = Color(red: 0.64, green: 0.15, blue: 0.18)
    static let emerald = Color(red: 0.14, green: 0.50, blue: 0.34)
    static let slate = Color(red: 0.29, green: 0.31, blue: 0.32)
    static let panel = Color.white.opacity(0.08)

    static let background = LinearGradient(
        colors: [Color(red: 0.03, green: 0.028, blue: 0.025), Color(red: 0.12, green: 0.095, blue: 0.07), Color(red: 0.04, green: 0.035, blue: 0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hero = LinearGradient(
        colors: [champagne, parchment, Color(red: 0.74, green: 0.47, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct PremiumCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.ultraThinMaterial.opacity(0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 18)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCard())
    }
}
