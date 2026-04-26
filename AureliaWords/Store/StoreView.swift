import SwiftUI

struct StoreView: View {
    private enum StoreTab: String, CaseIterable, Identifiable {
        case skins = "Skins"
        case helpers = "Helpers"
        case inventory = "Inventory"

        var id: String { rawValue }
    }

    @Bindable var settings: AppSettingsStore
    let inventoryEnabled: Bool
    let gameMode: PuzzleMode?
    let isGameComplete: Bool
    let onUseItem: ((StoreItemID) -> StoreConsumeResult)?
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var selectedTab: StoreTab = .skins

    private var ownedItems: [StoreItem] {
        settings.storeCatalog.filter { settings.ownedCount(for: $0.id) > 0 }
    }

    private var ownedSkinCount: Int {
        settings.skinCatalog.filter { settings.ownsSkin($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AureliaTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        tabBar
                        activeTabCard

                        if !feedbackText.isEmpty {
                            Text(feedbackText)
                                .font(AureliaTheme.body(14, weight: .semibold))
                                .foregroundStyle(AureliaTheme.champagne)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Atelier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundStyle(AureliaTheme.parchment)
                }
            }
        }
    }

    private var availableTabs: [StoreTab] {
        inventoryEnabled ? StoreTab.allCases : [.skins, .helpers]
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(inventoryEnabled ? "Buy permanent skins and puzzle helpers with achievement coins, then use helpers from your inventory during a live puzzle." : "Spend achievement coins on permanent skins and keep helper items ready for your next game.")
                .font(AureliaTheme.body(15, weight: .medium))
                .foregroundStyle(AureliaTheme.secondaryText.opacity(0.82))

            HStack(spacing: 12) {
                summaryPill(value: "\(settings.coins)", title: "Coins")
                summaryPill(value: "\(ownedSkinCount)", title: "Skins")
                summaryPill(value: "\(ownedItems.reduce(0) { $0 + settings.ownedCount(for: $1.id) })", title: "Helpers")
            }
        }
        .sheetCard()
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            ForEach(availableTabs) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(AureliaTheme.body(13, weight: .bold))
                        .foregroundStyle(selectedTab == tab ? AureliaTheme.actionText : AureliaTheme.parchment)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule().fill(AureliaTheme.hero)
                                } else {
                                    Capsule().fill(.white.opacity(0.05))
                                }
                            }
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(selectedTab == tab ? 0 : 0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("store.tab.\(tab.id.lowercased())")
            }
        }
        .padding(6)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var activeTabCard: some View {
        switch selectedTab {
        case .skins:
            skinCatalogCard
        case .helpers:
            helperCatalogCard
        case .inventory:
            if inventoryEnabled {
                inventoryCard
            }
        }
    }

    private var skinCatalogCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Skins")
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            VStack(spacing: 12) {
                ForEach(settings.skinCatalog) { skin in
                    skinRow(skin)
                }
            }
        }
        .sheetCard()
    }

    private var helperCatalogCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Helpers")
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            VStack(spacing: 12) {
                ForEach(settings.storeCatalog) { item in
                    itemRow(
                        item: item,
                        quantity: settings.ownedCount(for: item.id),
                        actionTitle: "Buy",
                        actionIdentifier: "store.buy.\(item.id.rawValue)",
                        isActionEnabled: settings.coins >= item.price,
                        onAction: { purchase(item) }
                    )
                }
            }
        }
        .sheetCard()
    }

    private var inventoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Inventory")
                .font(AureliaTheme.display(28, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            if ownedItems.isEmpty {
                Text("Purchased helper items will show up here once you own them.")
                    .font(AureliaTheme.body(14, weight: .medium))
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.78))
            } else {
                VStack(spacing: 12) {
                    ForEach(ownedItems) { item in
                        itemRow(
                            item: item,
                            quantity: settings.ownedCount(for: item.id),
                            actionTitle: "Use",
                            actionIdentifier: "inventory.use.\(item.id.rawValue)",
                            isActionEnabled: canUse(item),
                            onAction: { use(item.id) }
                        )
                    }
                }
            }

            if let inventoryFootnote, !inventoryFootnote.isEmpty {
                Text(inventoryFootnote)
                    .font(AureliaTheme.body(13, weight: .medium))
                    .foregroundStyle(AureliaTheme.champagne.opacity(0.9))
                    .padding(.top, 2)
            }
        }
        .sheetCard()
    }

    private func itemRow(
        item: StoreItem,
        quantity: Int,
        actionTitle: String,
        actionIdentifier: String,
        isActionEnabled: Bool,
        onAction: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AureliaTheme.hero)

                Image(systemName: item.systemImage)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AureliaTheme.actionText)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(AureliaTheme.body(16, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)

                Text(item.summary)
                    .font(AureliaTheme.body(13, weight: .medium))
                    .foregroundStyle(AureliaTheme.secondaryText.opacity(0.8))

                HStack(spacing: 10) {
                    capsuleLabel("+\(item.price) coin cost")
                    capsuleLabel("Owned: \(quantity)")
                }
            }

            Spacer(minLength: 12)

            actionButton(
                title: actionTitle,
                identifier: actionIdentifier,
                isPrimary: actionTitle == "Buy",
                isEnabled: isActionEnabled,
                action: onAction
            )
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func skinRow(_ skin: Skin) -> some View {
        let isOwned = settings.ownsSkin(skin.id)
        let isSelected = settings.selectedSkin.id == skin.id
        let actionState = skinActionState(for: skin, isOwned: isOwned, isSelected: isSelected)

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(skin.palette.hero)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )

                Image(systemName: skin.systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(skin.palette.actionText)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 8) {
                Text(skin.name)
                    .font(AureliaTheme.body(16, weight: .bold))
                    .foregroundStyle(AureliaTheme.parchment)

                HStack(spacing: 10) {
                    capsuleLabel(skin.id == .default ? "Free" : "\(skin.price) coins")
                    capsuleLabel(isSelected ? "Equipped" : (isOwned ? "Owned" : "Locked"))
                }
            }

            Spacer(minLength: 12)

            actionButton(
                title: actionState.title,
                identifier: "store.skin.\(skin.id.rawValue)",
                isPrimary: actionState.isPrimary,
                isEnabled: actionState.isEnabled,
                action: {
                    switch actionState.kind {
                    case .none:
                        break
                    case .buy:
                        purchaseSkin(skin)
                    case .equip:
                        equipSkin(skin.id)
                    }
                }
            )
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    skin.palette.panel.opacity(0.86),
                    skin.palette.panelDeep.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isSelected ? skin.palette.selectedGlow.opacity(0.6) : skin.palette.champagne.opacity(0.18),
                    lineWidth: 1
                )
        )
    }

    private func summaryPill(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(AureliaTheme.display(26, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)
            Text(title.uppercased())
                .font(AureliaTheme.body(10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(AureliaTheme.tertiaryText.opacity(0.74))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func capsuleLabel(_ title: String) -> some View {
        Text(title)
            .font(AureliaTheme.body(11, weight: .bold))
            .foregroundStyle(AureliaTheme.parchment)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.08), in: Capsule())
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        identifier: String,
        isPrimary: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(title, action: action)
            .accessibilityIdentifier(identifier)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.48)

        if isPrimary {
            button.buttonStyle(PrimaryPremiumButtonStyle())
        } else {
            button.buttonStyle(SecondaryPremiumButtonStyle())
        }
    }

    private func purchase(_ item: StoreItem) {
        switch settings.purchase(item) {
        case .success:
            feedbackText = "\(item.name) purchased."
        case .insufficientCoins:
            feedbackText = "You need \(item.price) coins to buy \(item.name)."
        }
    }

    private func purchaseSkin(_ skin: Skin) {
        switch settings.purchaseSkin(skin) {
        case .success:
            settings.equipSkin(skin.id)
            feedbackText = "\(skin.name) unlocked and equipped."
        case .insufficientCoins:
            feedbackText = "You need \(skin.price) coins to buy \(skin.name)."
        case .alreadyOwned:
            feedbackText = "\(skin.name) is already in your collection."
        }
    }

    private func equipSkin(_ skinID: SkinID) {
        guard settings.equipSkin(skinID) else { return }
        feedbackText = "\(settings.selectedSkin.name) equipped."
    }

    private func use(_ itemID: StoreItemID) {
        guard let onUseItem else { return }
        switch onUseItem(itemID) {
        case .success:
            feedbackText = switch itemID {
            case .revealLetter:
                "A letter was revealed in your current puzzle."
            case .removeWrongLetters:
                "Wrong letters were removed from your keyboard."
            }
        case .unsupportedMode:
            feedbackText = "\(itemName(for: itemID)) works only in Daily and Practice."
        case .unavailable:
            feedbackText = "That item cannot be used right now."
        }
    }

    private func canUse(_ item: StoreItem) -> Bool {
        guard inventoryEnabled, settings.ownedCount(for: item.id) > 0 else { return false }
        guard !isGameComplete else { return false }
        guard let gameMode else { return false }
        return gameMode == .daily || gameMode == .practice
    }

    private var inventoryFootnote: String? {
        guard inventoryEnabled else { return nil }
        guard let gameMode else { return nil }
        if gameMode == .reverse {
            return "Helper items can be purchased here, but they can only be used in Daily and Practice."
        }
        return "Helper items stay separate from your permanent skin collection."
    }

    private func itemName(for itemID: StoreItemID) -> String {
        settings.storeCatalog.first { $0.id == itemID }?.name ?? "That helper"
    }

    private func skinActionState(for skin: Skin, isOwned: Bool, isSelected: Bool) -> SkinActionState {
        if isSelected {
            return SkinActionState(title: "Selected", isPrimary: false, isEnabled: false, kind: .none)
        }
        if isOwned {
            return SkinActionState(title: "Equip", isPrimary: false, isEnabled: true, kind: .equip)
        }
        if skin.id == .default {
            return SkinActionState(title: "Equip", isPrimary: false, isEnabled: true, kind: .equip)
        }
        return SkinActionState(title: "Buy", isPrimary: true, isEnabled: settings.coins >= skin.price, kind: .buy)
    }
}

private struct SkinActionState {
    enum Kind {
        case none
        case buy
        case equip
    }

    let title: String
    let isPrimary: Bool
    let isEnabled: Bool
    let kind: Kind
}
