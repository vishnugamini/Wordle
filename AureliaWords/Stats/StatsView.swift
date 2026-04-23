import SwiftUI

struct StatsView: View {
    let snapshot: StatsSnapshot

    var body: some View {
        ZStack {
            AureliaTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("The Ledger")
                    .font(AureliaTheme.display(38, weight: .semibold))
                    .foregroundStyle(AureliaTheme.parchment)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Played", value: "\(snapshot.played)")
                    StatCard(title: "Win Rate", value: "\(snapshot.winRate)%")
                    StatCard(title: "Streak", value: "\(snapshot.currentStreak)")
                    StatCard(title: "Best", value: "\(snapshot.bestStreak)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Guess Distribution")
                        .font(AureliaTheme.body(14, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AureliaTheme.champagne)

                    ForEach(1...6, id: \.self) { attempt in
                        HStack {
                            Text("\(attempt)")
                                .font(AureliaTheme.body(13, weight: .bold))
                                .foregroundStyle(AureliaTheme.parchment)
                                .frame(width: 20)

                            GeometryReader { proxy in
                                let count = snapshot.guessDistribution[attempt, default: 0]
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
                    }
                }
                .premiumCard()
            }
            .padding(24)
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
                .foregroundStyle(.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard()
    }
}
