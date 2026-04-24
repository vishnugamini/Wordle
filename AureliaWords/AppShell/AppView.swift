import SwiftData
import SwiftUI

struct AppView: View {
    private enum Screen {
        case home
        case game
    }

    private enum AppSheet: String, Identifiable {
        case stats
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
                                    viewModel.refreshStats()
                                    activeSheet = .stats
                                },
                                onOpenSettings: { activeSheet = .settings },
                                onOpenHowToPlay: { activeSheet = .howToPlay },
                                onOpenAbout: { activeSheet = .about }
                            )

                        case .game:
                            VStack(spacing: 6) {
                                topBar
                                modePicker(viewModel)
                                    .padding(.bottom, 12)
                                GameView(viewModel: viewModel, settings: settingsStore)
                                    .frame(maxHeight: .infinity)
                            }
                            .padding(.horizontal, 6)
                            .padding(.top, max(proxy.safeAreaInsets.top - 48, 4))
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom + 4, 8))
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
            if !settings.hasSeenHowToPlay {
                settings.markHowToPlaySeen()
                activeSheet = .howToPlay
            }
            didAppear = true
        }
        .sheet(item: $activeSheet) { sheet in
            if let viewModel, let settingsStore {
                switch sheet {
                case .stats:
                    StatsView(snapshot: viewModel.stats)
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
                        .font(AureliaTheme.body(11, weight: .heavy))
                        .tracking(3.6)
                        .foregroundStyle(AureliaTheme.champagne)
                    Text("Words")
                        .font(AureliaTheme.display(30, weight: .semibold))
                        .foregroundStyle(AureliaTheme.parchment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, -10)

            HStack(spacing: 10) {
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
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
        }
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
    }

    private var statsButton: some View {
        Button {
            viewModel?.refreshStats()
            activeSheet = .stats
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
        .accessibilityLabel("Statistics")
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
                        Text(mode == .daily ? "Today" : "Unlimited")
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
