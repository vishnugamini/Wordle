import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AureliaTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Tune the experience for accessibility, comfort, and launch-ready polish.")
                            .font(AureliaTheme.body(15, weight: .medium))
                            .foregroundStyle(AureliaTheme.secondaryText.opacity(0.8))

                        VStack(spacing: 14) {
                            toggleCard(
                                title: "Haptics",
                                description: "Use subtle taps for typing, warnings, and win or loss feedback.",
                                isOn: $settings.hapticsEnabled,
                                identifier: "settings.haptics"
                            )

                            toggleCard(
                                title: "Color-Blind Palette",
                                description: "Swap the tile palette to a high-contrast orange and blue pairing.",
                                isOn: $settings.colorBlindMode,
                                identifier: "settings.colorBlindMode"
                            )

                            toggleCard(
                                title: "Reduce Motion",
                                description: "Always simplify tile animations. The app also follows the system Reduce Motion setting.",
                                isOn: $settings.reduceMotion,
                                identifier: "settings.reduceMotion"
                            )
                        }

                        palettePreview

                        Text("Metadata Focus")
                            .font(AureliaTheme.body(13, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(AureliaTheme.champagne)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppMetadata.appName)
                                .font(AureliaTheme.display(24, weight: .semibold))
                                .foregroundStyle(AureliaTheme.parchment)
                            Text(AppMetadata.subtitle)
                                .font(AureliaTheme.body(15, weight: .semibold))
                                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.84))
                            Text(AppMetadata.keywords)
                                .font(AureliaTheme.body(13))
                                .foregroundStyle(AureliaTheme.tertiaryText.opacity(0.76))
                        }
                        .sheetCard()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("settings.close")
                }
            }
        }
        .presentationBackground(AureliaTheme.sheetBackground)
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }

    private var palettePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palette Preview")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            HStack(spacing: 10) {
                legendTile(title: "Miss", state: .absent)
                legendTile(title: "Present", state: .present)
                legendTile(title: "Correct", state: .correct)
            }
        }
        .sheetCard()
    }

    private func toggleCard(
        title: String,
        description: String,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(AureliaTheme.body(16, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)
            }
            .tint(AureliaTheme.champagne)
            .accessibilityIdentifier(identifier)

            Text(description)
                .font(AureliaTheme.body(13))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))
        }
        .sheetCard()
    }

    private func legendTile(title: String, state: LetterState) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tileFill(for: state))
                .frame(width: 72, height: 72)
                .overlay(
                    Text(String(title.prefix(1)))
                        .font(AureliaTheme.display(30, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text(title)
                .font(AureliaTheme.body(12, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)
        }
        .frame(maxWidth: .infinity)
    }

    private func tileFill(for state: LetterState) -> some ShapeStyle {
        if let colors = state.gradientColors(colorBlindMode: settings.colorBlindMode) {
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }

        return AnyShapeStyle(state == .absent ? AureliaTheme.charcoal : AureliaTheme.panelDeep)
    }
}
