import Foundation
import SwiftData

@Model
final class StoredGame {
    @Attribute(.unique) var id: String
    var modeRaw: String
    var puzzleID: String
    var answer: String
    var reverseChainBlob: String
    var guessesBlob: String
    var revealedHintIndicesBlob: String
    var removedLettersBlob: String
    var completed: Bool
    var won: Bool
    var attempts: Int
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String,
        mode: PuzzleMode,
        puzzleID: String,
        answer: String,
        reverseChain: [String]? = nil,
        guesses: [String] = [],
        revealedHintIndices: [Int] = [],
        removedLetters: [Character] = [],
        completed: Bool = false,
        won: Bool = false,
        attempts: Int = 0,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.modeRaw = mode.rawValue
        self.puzzleID = puzzleID
        self.answer = answer
        self.reverseChainBlob = reverseChain?.joined(separator: ",") ?? ""
        self.guessesBlob = guesses.joined(separator: ",")
        self.revealedHintIndicesBlob = revealedHintIndices.map(String.init).joined(separator: ",")
        self.removedLettersBlob = String(removedLetters).uppercased()
        self.completed = completed
        self.won = won
        self.attempts = attempts
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var mode: PuzzleMode {
        PuzzleMode(rawValue: modeRaw) ?? .practice
    }

    var guesses: [String] {
        get { guessesBlob.isEmpty ? [] : guessesBlob.split(separator: ",").map(String.init) }
        set { guessesBlob = newValue.joined(separator: ",") }
    }

    var reverseChain: [String]? {
        get {
            reverseChainBlob.isEmpty ? nil : reverseChainBlob.split(separator: ",").map(String.init)
        }
        set {
            reverseChainBlob = newValue?.joined(separator: ",") ?? ""
        }
    }

    var revealedHintIndices: [Int] {
        get {
            revealedHintIndicesBlob.isEmpty
                ? []
                : revealedHintIndicesBlob
                    .split(separator: ",")
                    .compactMap { Int($0) }
        }
        set {
            revealedHintIndicesBlob = newValue.map(String.init).joined(separator: ",")
        }
    }

    var removedLetters: [Character] {
        get { Array(removedLettersBlob.uppercased()) }
        set { removedLettersBlob = String(newValue).uppercased() }
    }
}

@Model
final class StoredSettings {
    @Attribute(.unique) var id: String
    var hapticsEnabled: Bool
    var colorBlindMode: Bool
    var reduceMotion: Bool
    var hasSeenHowToPlay: Bool
    var coins: Int
    var lastCheckInAt: Date?
    var unlockedAchievementIDsBlob: String
    var inventoryCountsBlob: String
    var ownedSkinIDsBlob: String
    var selectedSkinID: String

    init(
        id: String = "settings",
        hapticsEnabled: Bool = true,
        colorBlindMode: Bool = false,
        reduceMotion: Bool = false,
        hasSeenHowToPlay: Bool = false,
        coins: Int = 1000,
        lastCheckInAt: Date? = nil,
        unlockedAchievementIDs: [String] = [],
        inventoryCounts: [String: Int] = [:],
        ownedSkinIDs: [String] = [SkinID.default.rawValue],
        selectedSkinID: String = SkinID.default.rawValue
    ) {
        self.id = id
        self.hapticsEnabled = hapticsEnabled
        self.colorBlindMode = colorBlindMode
        self.reduceMotion = reduceMotion
        self.hasSeenHowToPlay = hasSeenHowToPlay
        self.coins = coins
        self.lastCheckInAt = lastCheckInAt
        self.unlockedAchievementIDsBlob = unlockedAchievementIDs.joined(separator: ",")
        self.inventoryCountsBlob = Self.encodeInventoryCounts(inventoryCounts)
        self.ownedSkinIDsBlob = Self.encodeStringSet(ownedSkinIDs)
        self.selectedSkinID = selectedSkinID
    }

    var unlockedAchievementIDs: [String] {
        get { unlockedAchievementIDsBlob.isEmpty ? [] : unlockedAchievementIDsBlob.split(separator: ",").map(String.init) }
        set { unlockedAchievementIDsBlob = newValue.joined(separator: ",") }
    }

    var inventoryCounts: [String: Int] {
        get { Self.decodeInventoryCounts(inventoryCountsBlob) }
        set { inventoryCountsBlob = Self.encodeInventoryCounts(newValue) }
    }

    var ownedSkinIDs: [String] {
        get { Self.decodeStringSet(ownedSkinIDsBlob) }
        set { ownedSkinIDsBlob = Self.encodeStringSet(newValue) }
    }

    private static func encodeInventoryCounts(_ counts: [String: Int]) -> String {
        counts
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
    }

    private static func decodeInventoryCounts(_ blob: String) -> [String: Int] {
        guard !blob.isEmpty else { return [:] }

        return blob
            .split(separator: ",")
            .reduce(into: [:]) { partialResult, pair in
                let pieces = pair.split(separator: ":", maxSplits: 1).map(String.init)
                guard pieces.count == 2, let count = Int(pieces[1]), count > 0 else { return }
                partialResult[pieces[0]] = count
            }
    }

    private static func encodeStringSet(_ values: [String]) -> String {
        Array(Set(values))
            .sorted()
            .joined(separator: ",")
    }

    private static func decodeStringSet(_ blob: String) -> [String] {
        guard !blob.isEmpty else { return [] }
        return blob.split(separator: ",").map(String.init)
    }
}
