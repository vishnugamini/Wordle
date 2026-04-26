import SwiftData
import SwiftUI

struct AppView: View {
    private enum Screen {
        case home
        case game
    }

    private enum AppSheet: String, Identifiable {
        case dailyStats
        case practiceStats
        case reverseStats
        case achievements
        case store
        case settings
        case howToPlay
        case about

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var context
    @State private var selectedMode: PuzzleMode = .daily
    @State private var screen: Screen = .home
    @State private var activeSheet: AppSheet?
    @State private var didAppear = false
    @State private var settingsStore: AppSettingsStore?
    @State private var viewModel: GameViewModel?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AureliaTheme.background.ignoresSafeArea()
                ornamentalBackdrop

                if let viewModel, let settingsStore {
                    Group {
                        switch screen {
                        case .home:
                            HomeView(
                                selectedMode: selectedMode,
                                stats: viewModel.stats,
                                coins: settingsStore.coins,
                                onModeSelected: { mode in
                                    selectedMode = mode
                                },
                                onPlay: {
                                    if viewModel.mode != selectedMode {
                                        viewModel.switchMode(selectedMode)
                                    }
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                        screen = .game
                                    }
                                },
                                onShowStats: {
                                    activeSheet = statsSheet(for: selectedMode)
                                },
                                onOpenAchievements: { activeSheet = .achievements },
                                onOpenStore: { activeSheet = .store },
                                onOpenSettings: { activeSheet = .settings },
                                onOpenHowToPlay: { activeSheet = .howToPlay },
                                onOpenAbout: { activeSheet = .about }
                            )

                        case .game:
                            VStack(spacing: 6) {
                                topBar
                                modePicker(viewModel)
                                    .padding(.bottom, 12)
                                GameView(
                                    viewModel: viewModel,
                                    settings: settingsStore,
                                    isOverlayPresented: activeSheet != nil
                                )
                                    .frame(maxHeight: .infinity)
                            }
                            .padding(.horizontal, 6)
                            .padding(.top, max(proxy.safeAreaInsets.top - 48, 4))
                            .padding(.bottom, 0)
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                        }
                    }
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 14)
                    .animation(.easeOut(duration: 0.35), value: didAppear)
                }
            }
        }
        .task {
            guard viewModel == nil, settingsStore == nil else { return }
            let settings = AppSettingsStore(context: context)
            settingsStore = settings
            viewModel = GameViewModel(context: context, settings: settings)
            settings.claimDailyCheckInIfNeeded()
            if !settings.hasSeenHowToPlay {
                settings.markHowToPlaySeen()
                activeSheet = .howToPlay
            }
            didAppear = true
        }
        .sheet(item: $activeSheet) { sheet in
            if let viewModel, let settingsStore {
                switch sheet {
                case .dailyStats:
                    StatsView(mode: .daily, snapshot: viewModel.stats[.daily])
                case .practiceStats:
                    StatsView(mode: .practice, snapshot: viewModel.stats[.practice])
                case .reverseStats:
                    StatsView(mode: .reverse, snapshot: viewModel.stats[.reverse])
                case .achievements:
                    AchievementsView(
                        stats: viewModel.stats,
                        unlockedAchievementIDs: settingsStore.unlockedAchievementIDs,
                        coins: settingsStore.coins
                    )
                case .store:
                    StoreView(
                        settings: settingsStore,
                        inventoryEnabled: screen == .game,
                        gameMode: screen == .game ? viewModel.mode : nil,
                        isGameComplete: screen == .game ? viewModel.session.isComplete : false,
                        onUseItem: screen == .game ? { itemID in
                            switch itemID {
                            case .revealLetter:
                                return viewModel.useRevealLetter()
                            case .removeWrongLetters:
                                return viewModel.useRemoveWrongLetters()
                            }
                        } : nil
                    )
                case .settings:
                    SettingsView(settings: settingsStore)
                case .howToPlay:
                    HowToPlayView(settings: settingsStore)
                case .about:
                    AboutSupportView()
                }
            } else {
                EmptyView()
            }
        }
    }

    private var topBar: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: -4) {
                if screen == .game {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            screen = .home
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                            Text("Salon")
                                .font(AureliaTheme.body(13, weight: .bold))
                                .tracking(0.8)
                        }
                        .foregroundStyle(AureliaTheme.champagne)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.06), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .accessibilityIdentifier("app.backHome")
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }

                VStack(alignment: .leading, spacing: -4) {
                    Text("AURELIA")
                        .font(AureliaTheme.body(9, weight: .heavy))
                        .tracking(3)
                        .foregroundStyle(AureliaTheme.champagne)
                    Text("Words")
                        .font(AureliaTheme.display(24, weight: .semibold))
                        .foregroundStyle(AureliaTheme.parchment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, -10)

            HStack(spacing: 10) {
                if let currentViewModel = viewModel, screen == .game, selectedMode == .reverse {
                    topBarButton(
                        systemName: "arrow.clockwise",
                        identifier: "app.reverseRefresh",
                        accessibilityLabel: "New reverse puzzle",
                        size: 36
                    ) {
                        currentViewModel.startFreshReverse()
                    }
                }

                topBarButton(
                    systemName: "bag",
                    identifier: "app.store",
                    accessibilityLabel: "Atelier"
                ) {
                    activeSheet = .store
                }

                topBarButton(
                    systemName: "questionmark.circle",
                    identifier: "app.help",
                    accessibilityLabel: "How to play"
                ) {
                    activeSheet = .howToPlay
                }

                topBarButton(
                    systemName: "gearshape",
                    identifier: "app.settings",
                    accessibilityLabel: "Settings"
                ) {
                    activeSheet = .settings
                }

                statsButton
            }
            .offset(y: -8)
        }
        .padding(.bottom, 2)
    }

    private func topBarButton(
        systemName: String,
        identifier: String,
        accessibilityLabel: String,
        size: CGFloat = 42,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)
                .frame(width: size, height: size)
                .background(.white.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
        }
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
    }

    private var statsButton: some View {
        Button {
            activeSheet = statsSheet(for: selectedMode)
        } label: {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AureliaTheme.ink)
                .frame(width: 44, height: 44)
                .background(AureliaTheme.hero, in: Circle())
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.42), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: AureliaTheme.champagne.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .accessibilityIdentifier("app.stats")
        .accessibilityLabel("\(selectedMode.title) statistics")
        .buttonStyle(.plain)
    }

    private func modePicker(_ viewModel: GameViewModel) -> some View {
        HStack(spacing: 8) {
            ForEach(PuzzleMode.allCases) { mode in
                Button {
                    selectedMode = mode
                    viewModel.switchMode(mode)
                } label: {
                    VStack(spacing: 3) {
                        Text(mode.title)
                            .font(AureliaTheme.body(16, weight: .bold))
                        Text(modePickerSubtitle(for: mode))
                            .font(AureliaTheme.body(11, weight: .semibold))
                            .opacity(0.72)
                    }
                    .foregroundStyle(selectedMode == mode ? AureliaTheme.ink : AureliaTheme.parchment)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(selectedMode == mode ? AnyShapeStyle(AureliaTheme.hero) : AnyShapeStyle(.white.opacity(0.07)), in: Capsule())
                }
                .accessibilityIdentifier("game.mode.\(mode.rawValue)")
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 8)
    }

    private func statsSheet(for mode: PuzzleMode) -> AppSheet {
        switch mode {
        case .daily:
            return .dailyStats
        case .practice:
            return .practiceStats
        case .reverse:
            return .reverseStats
        }
    }

    private func modePickerSubtitle(for mode: PuzzleMode) -> String {
        switch mode {
        case .daily:
            return "Today"
        case .practice:
            return "Unlimited"
        case .reverse:
            return "Rebuild"
        }
    }

    private var ornamentalBackdrop: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AureliaTheme.champagne.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 230, height: 230)
                .offset(x: 130, y: -260)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AureliaTheme.ruby.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -130, y: 280)
        }
    }
}

private struct AchievementsView: View {
    let stats: ModeStatsSnapshot
    let unlockedAchievementIDs: Set<String>
    let coins: Int

    private var earnedAchievementIDs: Set<String> {
        Achievement.earnedAchievementIDs(
            unlockedAchievementIDs: unlockedAchievementIDs,
            stats: stats
        )
    }

    private var earnedAchievements: [Achievement] {
        Achievement.all.filter { earnedAchievementIDs.contains($0.id) }
    }

    private var visibleRemainingAchievements: [Achievement] {
        Achievement.visibleLockedAchievements(
            earnedAchievementIDs: earnedAchievementIDs,
            stats: stats
        )
    }

    private var hiddenAchievementCount: Int {
        Achievement.all.count - earnedAchievements.count - visibleRemainingAchievements.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AureliaTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        sectionCard(
                            title: "Achievements Earned",
                            subtitle: earnedAchievements.isEmpty ? "No achievements unlocked yet." : "\(earnedAchievements.count) completed so far.",
                            achievements: earnedAchievements,
                            isEarned: true
                        )
                        sectionCard(
                            title: "Up Next",
                            subtitle: visibleRemainingAchievements.isEmpty
                                ? "You have completed everything."
                                : hiddenAchievementCount > 0
                                    ? "\(visibleRemainingAchievements.count) goals are active now. \(hiddenAchievementCount) more will appear as you progress."
                                    : "\(visibleRemainingAchievements.count) goals are still in play.",
                            achievements: visibleRemainingAchievements,
                            isEarned: false
                        )
                    }
                    .padding(20)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Track what you have earned and what is left to unlock.")
                .font(AureliaTheme.body(15, weight: .medium))
                .foregroundStyle(.white.opacity(0.76))

            HStack(spacing: 12) {
                summaryPill(value: "\(coins)", title: "Coins")
                summaryPill(value: "\(earnedAchievements.count)", title: "Earned")
                summaryPill(value: "\(visibleRemainingAchievements.count)", title: "Up Next")
            }
        }
        .sheetCard()
    }

    private func summaryPill(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(AureliaTheme.display(26, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)
            Text(title.uppercased())
                .font(AureliaTheme.body(10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func sectionCard(
        title: String,
        subtitle: String,
        achievements: [Achievement],
        isEarned: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(subtitle)
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if achievements.isEmpty {
                Text(isEarned ? "Win a few rounds to start collecting rewards." : "Every achievement is already complete.")
                    .font(AureliaTheme.body(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        achievementRow(achievement, isEarned: isEarned)
                    }
                }
            }
        }
        .sheetCard()
    }

    private func achievementRow(_ achievement: Achievement, isEarned: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isEarned ? AnyShapeStyle(AureliaTheme.hero) : AnyShapeStyle(.white.opacity(0.08)))

                Image(systemName: isEarned ? "checkmark.seal.fill" : "seal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isEarned ? AureliaTheme.ink : AureliaTheme.champagne)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(AureliaTheme.body(16, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)

                Text(achievement.summary)
                    .font(AureliaTheme.body(13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Text(isEarned ? "Completed" : achievement.progressText(stats: stats))
                    .font(AureliaTheme.body(11, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(isEarned ? AureliaTheme.emerald : AureliaTheme.champagne)
            }

            Spacer(minLength: 12)

            Text("+\(achievement.reward)")
                .font(AureliaTheme.body(13, weight: .heavy))
                .foregroundStyle(isEarned ? AureliaTheme.ink : AureliaTheme.parchment)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isEarned ? AnyShapeStyle(AureliaTheme.hero) : AnyShapeStyle(.white.opacity(0.08)),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isEarned ? 0.0 : 0.14), lineWidth: 1)
                )
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct SlideUpOverlay<Content: View>: View {
    let onDismiss: () -> Void
    var maxHeightRatio: CGFloat = 0.78
    var fillsScreen = false
    var isDraggable = false
    @ViewBuilder let content: () -> Content
    @State private var settledOffset: CGFloat = 0
    @GestureState private var activeDragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let bottomExtension = max(proxy.safeAreaInsets.bottom, 48)
            let availableHeight = proxy.size.height - proxy.safeAreaInsets.top - 12
            let sheetHeight = fillsScreen
                ? proxy.size.height
                : max(360, availableHeight * min(maxHeightRatio, 1)) + bottomExtension
            let cornerRadius: CGFloat = fillsScreen ? 0 : 34
            let visibleTop = proxy.size.height - sheetHeight + (fillsScreen ? 0 : bottomExtension)
            let upwardLimit = fillsScreen ? 0 : min(0, proxy.safeAreaInsets.top + 12 - visibleTop)
            let downwardLimit = fillsScreen ? 0 : sheetHeight * 0.42
            let sheetOffset = clampedSheetOffset(
                settledOffset + activeDragOffset,
                upwardLimit: upwardLimit,
                downwardLimit: downwardLimit
            )

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Capsule()
                            .fill(.white.opacity(0.22))
                            .frame(width: 42, height: 5)

                        Spacer()
                    }
                    .frame(height: 29)
                    .contentShape(Rectangle())
                    .gesture(sheetDragGesture(upwardLimit: upwardLimit, downwardLimit: downwardLimit))

                    content()
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, fillsScreen ? 0 : bottomExtension)
                }
                .frame(maxWidth: .infinity)
                .frame(height: sheetHeight, alignment: .top)
                .background(AureliaTheme.sheetBackground, in: UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius))
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.32), radius: 26, x: 0, y: -6)
                .offset(y: (fillsScreen ? 0 : bottomExtension) + sheetOffset)
                .padding(.top, fillsScreen ? 0 : 12)
                .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: settledOffset)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func clampedSheetOffset(
        _ offset: CGFloat,
        upwardLimit: CGFloat,
        downwardLimit: CGFloat
    ) -> CGFloat {
        min(max(offset, upwardLimit), downwardLimit)
    }

    private func sheetDragGesture(upwardLimit: CGFloat, downwardLimit: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($activeDragOffset) { value, state, _ in
                guard isDraggable else { return }
                state = value.translation.height
            }
            .onEnded { value in
                guard isDraggable else { return }

                let nextOffset = clampedSheetOffset(
                    settledOffset + value.translation.height,
                    upwardLimit: upwardLimit,
                    downwardLimit: downwardLimit
                )

                if value.translation.height > 120 || value.predictedEndTranslation.height > 220 {
                    onDismiss()
                } else {
                    settledOffset = nextOffset
                }
            }
    }
}
