import SwiftUI

struct StatsView: View {
    let mode: PuzzleMode
    let snapshot: StatsSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AureliaTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(mode.title) Ledger")
                            .font(AureliaTheme.display(38, weight: .semibold))
                            .foregroundStyle(AureliaTheme.parchment)

                        Text(statsSubtitle)
                            .font(AureliaTheme.body(13, weight: .semibold))
                            .foregroundStyle(AureliaTheme.champagne.opacity(0.85))
                    }

                    Spacer()

                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("stats.close")
                        .buttonStyle(SecondaryPremiumButtonStyle())
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Played", value: "\(snapshot.played)")
                    StatCard(title: "Win Rate", value: "\(snapshot.winRate)%")
                    StatCard(title: mode == .daily ? "Streak" : "Wins", value: mode == .daily ? "\(snapshot.currentStreak)" : "\(snapshot.wins)")
                    StatCard(title: "Best", value: mode == .daily ? "\(snapshot.bestStreak)" : "\(snapshot.guessDistribution.keys.max() ?? 0)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Guess Distribution")
                        .font(AureliaTheme.body(14, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AureliaTheme.champagne)

                    ForEach(1...6, id: \.self) { attempt in
                        let count = snapshot.guessDistribution[attempt, default: 0]
                        HStack {
                            Text("\(attempt)")
                                .font(AureliaTheme.body(13, weight: .bold))
                                .foregroundStyle(AureliaTheme.parchment)
                                .frame(width: 20)

                            GeometryReader { proxy in
                                let maxCount = max(snapshot.guessDistribution.values.max() ?? 1, 1)
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AureliaTheme.hero)
                                    .frame(width: max(CGFloat(count) / CGFloat(maxCount) * proxy.size.width, count == 0 ? 8 : 28))
                                    .overlay(alignment: .trailing) {
                                        Text("\(count)")
                                            .font(AureliaTheme.body(11, weight: .bold))
                                            .foregroundStyle(AureliaTheme.ink)
                                            .padding(.trailing, 8)
                                    }
                            }
                            .frame(height: 22)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Attempt \(attempt)")
                        .accessibilityValue("\(count) wins")
                    }
                }
                .sheetCard()
            }
            .padding(24)
        }
        .presentationBackground(AureliaTheme.sheetBackground)
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }

    private var statsSubtitle: String {
        switch mode {
        case .daily:
            return "Daily puzzle results only"
        case .practice:
            return "Practice round results only"
        case .reverse:
            return "Reverse reconstruction results only"
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AureliaTheme.display(32, weight: .bold))
                .foregroundStyle(AureliaTheme.hero)
            Text(title.uppercased())
                .font(AureliaTheme.body(11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(AureliaTheme.tertiaryText.opacity(0.76))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheetCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
