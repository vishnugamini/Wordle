import Foundation
import SwiftData

@Model
final class StoredGame {
    @Attribute(.unique) var id: String
    var modeRaw: String
    var puzzleID: String
    var answer: String
    var guessesBlob: String
    var completed: Bool
    var won: Bool
    var attempts: Int
    var createdAt: Date
    var completedAt: Date?

    init(id: String, mode: PuzzleMode, puzzleID: String, answer: String, guesses: [String] = [], completed: Bool = false, won: Bool = false, attempts: Int = 0, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.modeRaw = mode.rawValue
        self.puzzleID = puzzleID
        self.answer = answer
        self.guessesBlob = guesses.joined(separator: ",")
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
}

@Model
final class StoredSettings {
    @Attribute(.unique) var id: String
    var hapticsEnabled: Bool
    var colorBlindMode: Bool
    var reduceMotion: Bool

    init(id: String = "settings", hapticsEnabled: Bool = true, colorBlindMode: Bool = false, reduceMotion: Bool = false) {
        self.id = id
        self.hapticsEnabled = hapticsEnabled
        self.colorBlindMode = colorBlindMode
        self.reduceMotion = reduceMotion
    }
}
