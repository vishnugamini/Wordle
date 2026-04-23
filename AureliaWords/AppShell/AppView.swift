import SwiftData
import SwiftUI

struct AppView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedMode: PuzzleMode = .daily
    @State private var showStats = false
    @State private var didAppear = false
    @State private var viewModel: GameViewModel?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AureliaTheme.background.ignoresSafeArea()
                ornamentalBackdrop

                if let viewModel {
                    VStack(spacing: 12) {
                        topBar
                        modePicker(viewModel)
                        GameView(viewModel: viewModel)
                            .frame(maxHeight: .infinity)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, max(proxy.safeAreaInsets.top + 8, 18))
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 8, 14))
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 22)
                    .animation(.easeOut(duration: 0.8), value: didAppear)
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = GameViewModel(context: context)
            didAppear = true
        }
        .sheet(isPresented: $showStats) {
            if let viewModel {
                StatsView(snapshot: viewModel.stats)
                    .presentationDetents([.medium])
                    .presentationCornerRadius(34)
            }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AURELIA")
                    .font(AureliaTheme.body(12, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(AureliaTheme.champagne)
                Text("Words")
                    .font(AureliaTheme.display(34, weight: .semibold))
                    .foregroundStyle(AureliaTheme.parchment)
            }

            Spacer()

            Button {
                viewModel?.refreshStats()
                showStats = true
            } label: {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AureliaTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(AureliaTheme.hero, in: Circle())
            }
            .buttonStyle(.plain)
        }
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
                            .font(AureliaTheme.body(15, weight: .bold))
                        Text(mode == .daily ? "Today" : "Unlimited")
                            .font(AureliaTheme.body(11, weight: .medium))
                            .opacity(0.72)
                    }
                    .foregroundStyle(selectedMode == mode ? AureliaTheme.ink : AureliaTheme.parchment)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedMode == mode ? AnyShapeStyle(AureliaTheme.hero) : AnyShapeStyle(.white.opacity(0.07)), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .premiumCard()
    }

    private var ornamentalBackdrop: some View {
        ZStack {
            Circle()
                .fill(AureliaTheme.champagne.opacity(0.18))
                .blur(radius: 70)
                .frame(width: 230, height: 230)
                .offset(x: 130, y: -260)

            Circle()
                .fill(AureliaTheme.ruby.opacity(0.16))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: -130, y: 280)
        }
    }
}
