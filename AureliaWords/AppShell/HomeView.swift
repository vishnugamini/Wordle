import SwiftUI

struct HomeView: View {
    let selectedMode: PuzzleMode
    let stats: StatsSnapshot
    let onModeSelected: (PuzzleMode) -> Void
    let onPlay: () -> Void
    let onShowStats: () -> Void
    let onOpenSettings: () -> Void
    let onOpenHowToPlay: () -> Void
    let onOpenAbout: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroPanel

                    Text("Choose Your Puzzle")
                        .font(AureliaTheme.body(13, weight: .bold))
                        .tracking(1.9)
                        .foregroundStyle(AureliaTheme.champagne)
                        .padding(.horizontal, 4)

                    VStack(spacing: 14) {
                        ForEach(PuzzleMode.allCases) { mode in
                            modeCard(mode)
                        }
                    }

                    actionPanel

                    quickActionsPanel

                    statRibbon
                }
                .padding(.horizontal, 20)
                .padding(.top, max(proxy.safeAreaInsets.top, 24))
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 24, 32))
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var heroPanel: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            AureliaTheme.ruby.opacity(0.14),
                            AureliaTheme.obsidian.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AureliaTheme.champagne.opacity(0.28), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 220, height: 220)
                    .offset(x: 98, y: -72)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AureliaTheme.ruby.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                    .offset(x: 136, y: 72)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("AURELIA")
                    .font(AureliaTheme.body(12, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(AureliaTheme.champagne)

                Text("Words")
                    .font(AureliaTheme.display(52, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)

                Text(AppMetadata.descriptionOpening)
                    .font(AureliaTheme.body(16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    tag("Daily Word Puzzle")
                    tag("Unlimited Practice")
                }
            }
            .padding(24)
        }
        .frame(height: 300)
        .shadow(color: .black.opacity(0.3), radius: 26, x: 0, y: 18)
    }

    private var statRibbon: some View {
        HStack(spacing: 10) {
            statPill(value: "\(stats.played)", title: "Played")
            statPill(value: "\(stats.winRate)%", title: "Win Rate")
            statPill(value: "\(stats.currentStreak)", title: "Streak")

            Button(action: onShowStats) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AureliaTheme.ink)
                    .frame(width: 54, height: 70)
                    .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .accessibilityIdentifier("home.stats")
            .buttonStyle(.plain)
        }
    }

    private func modeCard(_ mode: PuzzleMode) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            onModeSelected(mode)
        } label: {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(AureliaTheme.hero) : AnyShapeStyle(.white.opacity(0.06)))

                    Image(systemName: mode == .daily ? "sun.max.fill" : "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isSelected ? AureliaTheme.ink : AureliaTheme.champagne)
                }
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(mode.title)
                            .font(AureliaTheme.display(26, weight: .semibold))
                            .foregroundStyle(AureliaTheme.parchment)

                        Spacer(minLength: 12)

                        if isSelected {
                            Text("Selected")
                                .font(AureliaTheme.body(11, weight: .bold))
                                .tracking(1.3)
                                .foregroundStyle(AureliaTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AureliaTheme.hero, in: Capsule())
                        }
                    }

                    Text(mode.subtitle)
                        .font(AureliaTheme.body(14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))

                    Text(mode == .daily ? "A single curated puzzle for today." : "Jump into as many fresh rounds as you like.")
                        .font(AureliaTheme.body(12, weight: .semibold))
                        .foregroundStyle(isSelected ? AureliaTheme.champagne : .white.opacity(0.54))
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.09) : .white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(isSelected ? AureliaTheme.champagne.opacity(0.42) : .white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.24 : 0.16), radius: 20, x: 0, y: 12)
        }
        .accessibilityIdentifier("home.mode.\(mode.rawValue)")
        .buttonStyle(.plain)
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedMode == .daily ? "Play today’s featured word." : "Practice with unlimited fresh rounds.")
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(selectedMode == .daily ? "A new daily word puzzle is ready every day." : "Practice mode keeps you guessing for as long as you want to play.")
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))

            Button(action: onPlay) {
                HStack {
                    Text(selectedMode == .daily ? "Play Daily Puzzle" : "Start Practice Round")
                        .font(AureliaTheme.body(16, weight: .heavy))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(AureliaTheme.ink)
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .accessibilityIdentifier("home.play")
            .buttonStyle(.plain)
        }
        .premiumCard()
    }

    private var quickActionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ready for launch")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            HStack(spacing: 10) {
                quickActionButton(
                    title: "How to Play",
                    systemImage: "questionmark.circle",
                    identifier: "home.howToPlay",
                    action: onOpenHowToPlay
                )
                quickActionButton(
                    title: "Settings",
                    systemImage: "gearshape",
                    identifier: "home.settings",
                    action: onOpenSettings
                )
                quickActionButton(
                    title: "About",
                    systemImage: "info.circle",
                    identifier: "home.about",
                    action: onOpenAbout
                )
            }
        }
        .premiumCard()
    }

    private func statPill(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(AureliaTheme.display(24, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(title.uppercased())
                .font(AureliaTheme.body(10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AureliaTheme.champagne)

                Text(title)
                    .font(AureliaTheme.body(13, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .accessibilityIdentifier(identifier)
        .buttonStyle(.plain)
    }

    private func tag(_ title: String) -> some View {
        Text(title)
            .font(AureliaTheme.body(11, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(AureliaTheme.parchment)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}
