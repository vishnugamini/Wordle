import Foundation
import SwiftUI

enum PuzzleMode: String, CaseIterable, Identifiable, Codable {
    case daily
    case practice

    var id: String { rawValue }
    var title: String { self == .daily ? "Daily" : "Practice" }
    var subtitle: String { self == .daily ? "One new word each day" : "Unlimited atelier rounds" }
}

enum LetterState: String, Codable, Comparable {
    case unknown
    case absent
    case present
    case correct

    static func < (lhs: LetterState, rhs: LetterState) -> Bool {
        order(lhs) < order(rhs)
    }

    private static func order(_ state: LetterState) -> Int {
        switch state {
        case .unknown: 0
        case .absent: 1
        case .present: 2
        case .correct: 3
        }
    }

    var color: Color {
        switch self {
        case .unknown: AureliaTheme.panel
        case .absent: AureliaTheme.slate
        case .present: AureliaTheme.champagne
        case .correct: AureliaTheme.emerald
        }
    }
}

struct TileState: Identifiable, Equatable {
    let id = UUID()
    var letter: Character?
    var state: LetterState
}

struct GuessEvaluation: Equatable {
    let guess: String
    let states: [LetterState]
}

struct GameResult: Equatable {
    let won: Bool
    let answer: String
    let attempts: Int
}

struct GameSession {
    let id: String
    let mode: PuzzleMode
    let puzzleID: String
    let answer: String
    var guesses: [GuessEvaluation]
    var currentGuess: String
    var result: GameResult?

    var isComplete: Bool { result != nil }
}

struct StatsSnapshot {
    var played = 0
    var wins = 0
    var currentStreak = 0
    var bestStreak = 0
    var guessDistribution: [Int: Int] = [:]

    var winRate: Int {
        played == 0 ? 0 : Int((Double(wins) / Double(played) * 100).rounded())
    }
}

@MainActor
protocol PuzzleProvider {
    func puzzle(for mode: PuzzleMode, excluding recentAnswers: [String]) -> Puzzle
}

@MainActor
protocol WordValidator {
    func isValid(_ word: String) -> Bool
}

struct Puzzle: Equatable {
    let id: String
    let answer: String
}

enum GameMessage: Equatable {
    case idle
    case notEnoughLetters
    case invalidWord
    case alreadyComplete

    var text: String {
        switch self {
        case .idle: ""
        case .notEnoughLetters: "Five letters, darling."
        case .invalidWord: "That word is not in the collection."
        case .alreadyComplete: "This round is already sealed."
        }
    }
}
