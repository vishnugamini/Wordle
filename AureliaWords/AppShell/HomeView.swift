import SwiftUI

struct HomeView: View {
    let selectedMode: PuzzleMode
    let stats: ModeStatsSnapshot
    let coins: Int
    let onModeSelected: (PuzzleMode) -> Void
    let onPlay: () -> Void
    let onShowStats: () -> Void
    let onOpenAchievements: () -> Void
    let onOpenStore: () -> Void
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
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    tag("Daily Word Puzzle")
                    tag("Unlimited Practice")
                    tag("Reverse Chain")
                }
            }
            .padding(24)

            VStack {
                HStack {
                    Spacer()
                    coinBalanceWidget
                }
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 300)
        .shadow(color: .black.opacity(0.3), radius: 26, x: 0, y: 18)
    }

    private var statRibbon: some View {
        let snapshot = stats[selectedMode]

        return HStack(spacing: 10) {
            statPill(value: "\(snapshot.played)", title: "Played")
            statPill(value: "\(snapshot.winRate)%", title: "Win Rate")
            statPill(
                value: selectedMode == .daily ? "\(snapshot.currentStreak)" : "\(snapshot.wins)",
                title: selectedMode == .daily ? "Streak" : "Wins"
            )

            Button(action: onShowStats) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 18, weight: .bold))
                    Text(selectedMode.title)
                        .font(AureliaTheme.body(11, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundStyle(AureliaTheme.actionText)
                .frame(width: 66, height: 70)
                .background(AureliaTheme.hero, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .accessibilityIdentifier("home.stats")
            .accessibilityLabel("\(selectedMode.title) statistics")
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

                    Image(systemName: iconName(for: mode))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isSelected ? AureliaTheme.actionText : AureliaTheme.champagne)
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
                                .foregroundStyle(AureliaTheme.actionText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AureliaTheme.hero, in: Capsule())
                        }
                    }

                    Text(mode.subtitle)
                        .font(AureliaTheme.body(14, weight: .medium))
                        .foregroundStyle(AureliaTheme.secondaryText.opacity(0.8))

                    Text(modeDescription(for: mode))
                        .font(AureliaTheme.body(12, weight: .semibold))
                        .foregroundStyle(isSelected ? AureliaTheme.champagne : AureliaTheme.tertiaryText.opacity(0.72))
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
            Text(actionTitle)
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(actionSubtitle)
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))

            Button(action: onPlay) {
                HStack {
                    Text(playButtonTitle)
                        .font(AureliaTheme.body(16, weight: .heavy))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(AureliaTheme.actionText)
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

    private func iconName(for mode: PuzzleMode) -> String {
        switch mode {
        case .daily:
            return "sun.max.fill"
        case .practice:
            return "sparkles"
        case .reverse:
            return "arrow.uturn.backward.circle.fill"
        }
    }

    private func modeDescription(for mode: PuzzleMode) -> String {
        switch mode {
        case .daily:
            return "A single curated puzzle for today."
        case .practice:
            return "Jump into as many fresh rounds as you like."
        case .reverse:
            return "Start from the answer and reconstruct the hidden ladder upward."
        }
    }

    private var actionTitle: String {
        switch selectedMode {
        case .daily:
            return "Play today’s featured word."
        case .practice:
            return "Practice with unlimited fresh rounds."
        case .reverse:
            return "Trace the hidden guesses in reverse."
        }
    }

    private var actionSubtitle: String {
        switch selectedMode {
        case .daily:
            return "A new daily word puzzle is ready every day."
        case .practice:
            return "Practice mode keeps you guessing for as long as you want to play."
        case .reverse:
            return "See the answer first, then solve the hidden chain one row at a time."
        }
    }

    private var playButtonTitle: String {
        switch selectedMode {
        case .daily:
            return "Play Daily Puzzle"
        case .practice:
            return "Start Practice Round"
        case .reverse:
            return "Start Reverse Round"
        }
    }

    private var quickActionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ready for launch")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                quickActionButton(
                    title: "Atelier",
                    systemImage: "bag",
                    identifier: "home.store",
                    action: onOpenStore
                )
                quickActionButton(
                    title: "Achievements",
                    systemImage: "rosette",
                    identifier: "home.achievements",
                    action: onOpenAchievements
                )
                quickActionButton(
                    title: "Settings",
                    systemImage: "gearshape",
                    identifier: "home.settings",
                    action: onOpenSettings
                )
                quickActionButton(
                    title: "How to Play",
                    systemImage: "questionmark.circle",
                    identifier: "home.howToPlay",
                    action: onOpenHowToPlay
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

    private var coinBalanceWidget: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.92, blue: 0.54),
                                Color(red: 0.89, green: 0.64, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)

                Text("G")
                    .font(AureliaTheme.body(12, weight: .heavy))
                    .foregroundStyle(Color(red: 0.42, green: 0.25, blue: 0.02))
            }
            .frame(width: 26, height: 26)
            .shadow(color: Color(red: 0.76, green: 0.54, blue: 0.08).opacity(0.38), radius: 8, x: 0, y: 4)

            Text("\(coins)")
                .font(AureliaTheme.body(15, weight: .heavy))
                .foregroundStyle(AureliaTheme.parchment)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AureliaTheme.coinCapsuleFill, in: Capsule())
        .overlay(
            Capsule()
                .stroke(AureliaTheme.coinCapsuleStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gold")
        .accessibilityValue("\(coins)")
    }
}
