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

    func color(colorBlindMode: Bool = false) -> Color {
        switch self {
        case .unknown: AureliaTheme.panel
        case .absent: AureliaTheme.slate
        case .present: colorBlindMode ? AureliaTheme.apricot : AureliaTheme.champagne
        case .correct: colorBlindMode ? AureliaTheme.cobalt : AureliaTheme.emerald
        }
    }

    func gradientColors(colorBlindMode: Bool) -> [Color]? {
        switch self {
        case .present:
            return colorBlindMode ? [AureliaTheme.apricot, AureliaTheme.copper] : [AureliaTheme.champagne, AureliaTheme.bronze]
        case .correct:
            return colorBlindMode ? [AureliaTheme.sky, AureliaTheme.cobalt] : [AureliaTheme.mint, AureliaTheme.emerald]
        default:
            return nil
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .unknown:
            return "Unrevealed"
        case .absent:
            return "Not in the word"
        case .present:
            return "In the word, wrong spot"
        case .correct:
            return "Correct"
        }
    }
}

struct TileState: Identifiable, Equatable {
    let id = UUID()
    var letter: Character?
    var state: LetterState

    static func == (lhs: TileState, rhs: TileState) -> Bool {
        lhs.letter == rhs.letter && lhs.state == rhs.state
    }
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
        case .notEnoughLetters: "Enter five letters."
        case .invalidWord: "That word is not in the collection."
        case .alreadyComplete: "This round is already complete."
        }
    }
}
