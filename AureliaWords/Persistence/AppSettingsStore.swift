import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppSettingsStore {
    private let context: ModelContext
    @ObservationIgnored private var record: StoredSettings?
    @ObservationIgnored private let calendar = Calendar.current
    private var isLoading = false

    var hapticsEnabled = true {
        didSet { persistIfNeeded() }
    }
    var colorBlindMode = false {
        didSet { persistIfNeeded() }
    }
    var reduceMotion = false {
        didSet { persistIfNeeded() }
    }
    var hasSeenHowToPlay = false {
        didSet { persistIfNeeded() }
    }
    var coins = 1000 {
        didSet { persistIfNeeded() }
    }
    var lastCheckInAt: Date? {
        didSet { persistIfNeeded() }
    }
    var unlockedAchievementIDs: Set<String> = [] {
        didSet { persistIfNeeded() }
    }
    var inventoryCounts: [String: Int] = [:] {
        didSet { persistIfNeeded() }
    }
    var ownedSkinIDs: Set<String> = [SkinID.default.rawValue] {
        didSet { persistIfNeeded() }
    }
    var selectedSkinID = SkinID.default.rawValue {
        didSet {
            AureliaTheme.applySkin(selectedSkin)
            persistIfNeeded()
        }
    }

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func effectiveReduceMotion(systemReduceMotion: Bool) -> Bool {
        systemReduceMotion || reduceMotion
    }

    func markHowToPlaySeen() {
        guard !hasSeenHowToPlay else { return }
        hasSeenHowToPlay = true
    }

    func awardCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
    }

    @discardableResult
    func claimDailyCheckInIfNeeded(now: Date = Date()) -> Bool {
        if let lastCheckInAt, calendar.isDate(lastCheckInAt, inSameDayAs: now) {
            return false
        }

        lastCheckInAt = now
        awardCoins(CoinReward.dailyCheckIn)
        return true
    }

    @discardableResult
    func unlockAchievement(_ achievement: Achievement) -> Bool {
        guard !unlockedAchievementIDs.contains(achievement.id) else { return false }
        unlockedAchievementIDs.insert(achievement.id)
        awardCoins(achievement.reward)
        return true
    }

    func hasUnlockedAchievement(_ achievement: Achievement) -> Bool {
        unlockedAchievementIDs.contains(achievement.id)
    }

    var storeCatalog: [StoreItem] {
        StoreItem.catalog
    }

    var skinCatalog: [Skin] {
        AureliaTheme.availableSkins
    }

    var selectedSkin: Skin {
        let id = SkinID(rawValue: selectedSkinID) ?? .default
        return AureliaTheme.skin(for: id)
    }

    func ownedCount(for itemID: StoreItemID) -> Int {
        inventoryCounts[itemID.rawValue, default: 0]
    }

    func ownsSkin(_ skinID: SkinID) -> Bool {
        skinID == .default || ownedSkinIDs.contains(skinID.rawValue)
    }

    func purchase(_ item: StoreItem) -> StorePurchaseResult {
        guard coins >= item.price else { return .insufficientCoins }
        coins -= item.price
        inventoryCounts[item.id.rawValue, default: 0] += 1
        return .success
    }

    func purchaseSkin(_ skin: Skin) -> SkinPurchaseResult {
        if ownsSkin(skin.id) {
            return .alreadyOwned
        }
        guard coins >= skin.price else { return .insufficientCoins }
        coins -= skin.price
        ownedSkinIDs.insert(skin.id.rawValue)
        return .success
    }

    @discardableResult
    func equipSkin(_ skinID: SkinID) -> Bool {
        guard ownsSkin(skinID) else { return false }
        selectedSkinID = skinID.rawValue
        return true
    }

    func consume(_ itemID: StoreItemID) -> Bool {
        let count = ownedCount(for: itemID)
        guard count > 0 else { return false }
        if count == 1 {
            inventoryCounts.removeValue(forKey: itemID.rawValue)
        } else {
            inventoryCounts[itemID.rawValue] = count - 1
        }
        return true
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<StoredSettings>(predicate: #Predicate { $0.id == "settings" })
        let stored = (try? context.fetch(descriptor).first) ?? nil
        let resolved = stored ?? StoredSettings()

        if stored == nil {
            context.insert(resolved)
            try? context.save()
        }

        record = resolved
        hapticsEnabled = resolved.hapticsEnabled
        colorBlindMode = resolved.colorBlindMode
        reduceMotion = resolved.reduceMotion
        hasSeenHowToPlay = resolved.hasSeenHowToPlay
        coins = resolved.coins
        lastCheckInAt = resolved.lastCheckInAt
        unlockedAchievementIDs = Set(resolved.unlockedAchievementIDs)
        inventoryCounts = resolved.inventoryCounts
        let storedOwnedSkins = Set(resolved.ownedSkinIDs)
        ownedSkinIDs = storedOwnedSkins.union([SkinID.default.rawValue])
        selectedSkinID = SkinID(rawValue: resolved.selectedSkinID) != nil ? resolved.selectedSkinID : SkinID.default.rawValue
        if !ownedSkinIDs.contains(selectedSkinID) {
            selectedSkinID = SkinID.default.rawValue
        }
        AureliaTheme.applySkin(selectedSkin)
    }

    private func persistIfNeeded() {
        guard !isLoading else { return }
        persist()
    }

    private func persist() {
        let current = record ?? StoredSettings()
        current.hapticsEnabled = hapticsEnabled
        current.colorBlindMode = colorBlindMode
        current.reduceMotion = reduceMotion
        current.hasSeenHowToPlay = hasSeenHowToPlay
        current.coins = coins
        current.lastCheckInAt = lastCheckInAt
        current.unlockedAchievementIDs = Array(unlockedAchievementIDs).sorted()
        current.inventoryCounts = inventoryCounts
        current.ownedSkinIDs = Array(ownedSkinIDs.union([SkinID.default.rawValue])).sorted()
        current.selectedSkinID = ownedSkinIDs.contains(selectedSkinID) || selectedSkinID == SkinID.default.rawValue
            ? selectedSkinID
            : SkinID.default.rawValue

        if record == nil {
            context.insert(current)
            record = current
        }

        try? context.save()
    }
}
