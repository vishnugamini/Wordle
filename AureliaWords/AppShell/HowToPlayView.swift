import SwiftUI

struct HowToPlayView: View {
    @Bindable var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AureliaTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Daily and Practice ask you to find the hidden five-letter word in six tries. Reverse gives you the answer first and asks you to rebuild the hidden path upward.")
                            .font(AureliaTheme.body(15, weight: .medium))
                            .foregroundStyle(AureliaTheme.secondaryText.opacity(0.82))

                        rulesCard
                        meaningsCard
                        modesCard
                    }
                    .padding(24)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("help.close")
                }
            }
        }
        .presentationBackground(AureliaTheme.sheetBackground)
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rules")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            rule("Each guess must be a valid five-letter word.")
            rule("Use the tile colors to refine your next guess.")
            rule("Daily gives you one featured puzzle each day.")
            rule("Practice lets you keep playing with unlimited local rounds.")
            rule("Reverse shows the answer and color stack first, and each row only reveals when you find its exact hidden word.")
        }
        .sheetCard()
    }

    private var meaningsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tile Meanings")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            meaningRow(letter: "A", state: .absent, title: "Absent", detail: "The letter is not in the answer.")
            meaningRow(letter: "R", state: .present, title: "Present", detail: "The letter is in the answer, but in a different position.")
            meaningRow(letter: "E", state: .correct, title: "Correct", detail: "The letter is in the answer and in the correct position.")
        }
        .sheetCard()
    }

    private var modesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Launch Positioning")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            Text(AppMetadata.descriptionOpening)
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.8))

            Text("Subtitle: \(AppMetadata.subtitle)")
                .font(AureliaTheme.body(13, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            Text("Reverse mode reveals the final answer on the last row and keeps the earlier words hidden behind their colors until you reconstruct them in reverse order.")
                .font(AureliaTheme.body(13, weight: .medium))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))
        }
        .sheetCard()
    }

    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AureliaTheme.champagne)
                .padding(.top, 4)

            Text(text)
                .font(AureliaTheme.body(14))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.8))
        }
    }

    private func meaningRow(letter: String, state: LetterState, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tileFill(for: state))
                .frame(width: 62, height: 62)
                .overlay(
                    Text(letter)
                        .font(AureliaTheme.display(28, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AureliaTheme.body(15, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)
                Text(detail)
                    .font(AureliaTheme.body(13))
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))
            }
        }
    }

    private func tileFill(for state: LetterState) -> some ShapeStyle {
        if let colors = state.gradientColors(colorBlindMode: settings.colorBlindMode) {
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }

        return AnyShapeStyle(state == .absent ? AureliaTheme.charcoal : AureliaTheme.panelDeep)
    }
}
