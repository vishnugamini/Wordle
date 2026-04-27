import Foundation
import SwiftUI

enum PuzzleMode: String, CaseIterable, Identifiable, Codable {
    case daily
    case practice
    case reverse

    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily:
            "Daily"
        case .practice:
            "Practice"
        case .reverse:
            "Reverse"
        }
    }

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

    @MainActor
    func color(colorBlindMode: Bool = false) -> Color {
        switch self {
        case .unknown:
            return AureliaTheme.panel
        case .absent:
            return AureliaTheme.absentTile
        case .present:
            let gradient = gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.champagne]
            return gradient.first ?? AureliaTheme.champagne
        case .correct:
            let gradient = gradientColors(colorBlindMode: colorBlindMode) ?? [AureliaTheme.emerald]
            return gradient.first ?? AureliaTheme.emerald
        }
    }

    @MainActor
    func gradientColors(colorBlindMode: Bool) -> [Color]? {
        switch self {
        case .present:
            return AureliaTheme.presentGradient(colorBlindMode: colorBlindMode)
        case .correct:
            return AureliaTheme.correctGradient(colorBlindMode: colorBlindMode)
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

struct WordDefinition: Equatable {
    let word: String
    let meanings: [WordMeaning]
    let sourceName: String
}

struct WordMeaning: Equatable {
    let partOfSpeech: String?
    let text: String
}

enum WordDefinitionState: Equatable {
    case idle
    case loading
    case loaded(WordDefinition)
    case unavailable
}

struct GameSession {
    let id: String
    let mode: PuzzleMode
    let puzzleID: String
    let answer: String
    let reverseChain: [String]?
    var revealedHintIndices: Set<Int>
    var removedLetters: Set<Character>
    var guesses: [GuessEvaluation]
    var currentGuess: String
    var result: GameResult?

    init(
        id: String,
        mode: PuzzleMode,
        puzzleID: String,
        answer: String,
        reverseChain: [String]? = nil,
        revealedHintIndices: Set<Int> = [],
        removedLetters: Set<Character> = [],
        guesses: [GuessEvaluation],
        currentGuess: String,
        result: GameResult?
    ) {
        self.id = id
        self.mode = mode
        self.puzzleID = puzzleID
        self.answer = answer
        self.reverseChain = reverseChain
        self.revealedHintIndices = revealedHintIndices
        self.removedLetters = removedLetters
        self.guesses = guesses
        self.currentGuess = currentGuess
        self.result = result
    }

    var isComplete: Bool { result != nil }
    var isReverseMode: Bool { mode == .reverse && reverseChain?.isEmpty == false }
    var standardAnswerLetters: [Character] { Array(answer.uppercased()) }
    var editableColumns: [Int] {
        guard !isReverseMode else { return Array(0..<answer.count) }
        return Array(0..<answer.count).filter { !revealedHintIndices.contains($0) }
    }
    var editableSlotCount: Int { editableColumns.count }

    var reverseHiddenChain: [String] {
        guard let reverseChain else { return [] }
        return Array(reverseChain.dropLast())
    }

    var reverseActiveRow: Int? {
        guard isReverseMode, !isComplete else { return nil }
        let row = reverseHiddenChain.count - guesses.count - 1
        return row >= 0 ? row : nil
    }

    func reverseGuess(forRow row: Int) -> GuessEvaluation? {
        let hiddenCount = reverseHiddenChain.count
        guard hiddenCount > 0 else { return nil }

        let guessIndex = hiddenCount - row - 1
        guard guesses.indices.contains(guessIndex) else { return nil }
        return guesses[guessIndex]
    }

    var activeBoardRow: Int? {
        guard !isComplete else { return nil }
        return reverseActiveRow ?? guesses.count
    }

    func currentGuessLetter(at column: Int) -> Character? {
        if revealedHintIndices.contains(column), standardAnswerLetters.indices.contains(column) {
            return standardAnswerLetters[column]
        }

        guard let draftIndex = editableColumns.firstIndex(of: column) else { return nil }
        let draftLetters = Array(currentGuess)
        guard draftIndex < draftLetters.count else { return nil }
        return draftLetters[draftIndex]
    }

    func composedCurrentGuess() -> String? {
        guard !isReverseMode else {
            return currentGuess.count == answer.count ? currentGuess.lowercased() : nil
        }

        let draftLetters = Array(currentGuess.lowercased())
        guard draftLetters.count == editableColumns.count else { return nil }

        let answerLetters = Array(answer.lowercased())
        var letters = Array(repeating: Character(" "), count: answer.count)

        for column in 0..<answer.count {
            if revealedHintIndices.contains(column) {
                letters[column] = answerLetters[column]
            }
        }

        for (draftIndex, column) in editableColumns.enumerated() {
            letters[column] = draftLetters[draftIndex]
        }

        return String(letters)
    }
}

enum GameShareTextFormatter {
    static func text(for session: GameSession) -> String? {
        guard let result = session.result else { return nil }

        let score = scoreText(for: session, result: result)
        let detail = detailText(for: session, score: score)
        let rows = session.guesses.map { guess in
            guess.states.map(emoji(for:)).joined()
        }

        return ([AppMetadata.appName, session.mode.title].joined(separator: " ") + "\n" + detail + "\n\n" + rows.joined(separator: "\n"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func scoreText(for session: GameSession, result: GameResult) -> String {
        if session.mode == .reverse {
            let hiddenRowCount = max(session.reverseHiddenChain.count, result.attempts)
            return "\(result.attempts)/\(hiddenRowCount)"
        }

        return result.won ? "\(result.attempts)/6" : "X/6"
    }

    private static func detailText(for session: GameSession, score: String) -> String {
        let unit = session.mode == .reverse ? "rows" : "tries"
        let scoreText = "\(score) \(unit)"

        if session.mode == .daily, let dayText = dailyDayText(from: session.puzzleID) {
            return "\(dayText) • \(scoreText)"
        }

        return scoreText
    }

    private static func dailyDayText(from puzzleID: String) -> String? {
        let prefix = "daily-"
        guard puzzleID.hasPrefix(prefix) else { return nil }

        let dayText = String(puzzleID.dropFirst(prefix.count))
        guard dayText.count == 10 else { return nil }
        let inputFormatter = DateFormatter()
        inputFormatter.calendar = Calendar(identifier: .gregorian)
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dayText) else { return nil }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private static func emoji(for state: LetterState) -> String {
        switch state {
        case .correct:
            return "🟩"
        case .present:
            return "🟨"
        case .absent, .unknown:
            return "⬛"
        }
    }
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

struct ModeStatsSnapshot {
    var daily = StatsSnapshot()
    var practice = StatsSnapshot()
    var reverse = StatsSnapshot()

    subscript(mode: PuzzleMode) -> StatsSnapshot {
        switch mode {
        case .daily:
            daily
        case .practice:
            practice
        case .reverse:
            reverse
        }
    }
}

extension ModeStatsSnapshot {
    var totalPlayed: Int { daily.played + practice.played + reverse.played }
    var totalWins: Int { daily.wins + practice.wins + reverse.wins }
    var oneGuessWins: Int {
        daily.guessDistribution[1, default: 0]
            + practice.guessDistribution[1, default: 0]
            + reverse.guessDistribution[1, default: 0]
    }
    var twoGuessWins: Int {
        daily.guessDistribution[2, default: 0]
            + practice.guessDistribution[2, default: 0]
            + reverse.guessDistribution[2, default: 0]
    }
}

enum CoinReward {
    static let correctAnswer = 10
    static let dailyCheckIn = 15
}

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let reward: Int

    static let firstWin = Achievement(
        id: "first-win",
        title: "First Victory",
        summary: "Win your first puzzle in any mode.",
        reward: 25
    )
    static let dailyStarter = Achievement(
        id: "daily-starter",
        title: "Daily Starter",
        summary: "Win your first daily puzzle.",
        reward: 20
    )
    static let practiceRegular = Achievement(
        id: "practice-regular",
        title: "Practice Regular",
        summary: "Win 5 practice puzzles.",
        reward: 35
    )
    static let streakThree = Achievement(
        id: "streak-three",
        title: "Three Day Streak",
        summary: "Build a 3-day daily win streak.",
        reward: 45
    )
    static let tenWins = Achievement(
        id: "ten-wins",
        title: "Ten Wins",
        summary: "Win 10 puzzles across all modes.",
        reward: 60
    )
    static let practiceStarter = Achievement(
        id: "practice-starter",
        title: "Practice Starter",
        summary: "Win your first practice puzzle.",
        reward: 20
    )
    static let dailyDabbler = Achievement(
        id: "daily-dabbler",
        title: "Daily Dabbler",
        summary: "Win 3 daily puzzles.",
        reward: 30
    )
    static let gameNight = Achievement(
        id: "game-night",
        title: "Game Night",
        summary: "Finish 10 puzzles in total.",
        reward: 30
    )
    static let sharpSolve = Achievement(
        id: "sharp-solve",
        title: "Sharp Solve",
        summary: "Win any puzzle in 2 guesses.",
        reward: 40
    )
    static let oneShotWonder = Achievement(
        id: "one-shot-wonder",
        title: "One-Shot Wonder",
        summary: "Win any puzzle in 1 guess.",
        reward: 70
    )
    static let dailyDevotee = Achievement(
        id: "daily-devotee",
        title: "Daily Devotee",
        summary: "Win 7 daily puzzles.",
        reward: 60
    )
    static let practiceCraftsman = Achievement(
        id: "practice-craftsman",
        title: "Practice Craftsman",
        summary: "Win 10 practice puzzles.",
        reward: 60
    )
    static let seasonedPlayer = Achievement(
        id: "seasoned-player",
        title: "Seasoned Player",
        summary: "Finish 25 puzzles in total.",
        reward: 65
    )
    static let streakFive = Achievement(
        id: "streak-five",
        title: "Five Day Streak",
        summary: "Build a 5-day daily win streak.",
        reward: 85
    )
    static let twentyFiveWins = Achievement(
        id: "twenty-five-wins",
        title: "Twenty-Five Wins",
        summary: "Win 25 puzzles across all modes.",
        reward: 95
    )
    static let precisionPair = Achievement(
        id: "precision-pair",
        title: "Precision Pair",
        summary: "Win 5 puzzles in 2 guesses.",
        reward: 90
    )
    static let tripleBullseye = Achievement(
        id: "triple-bullseye",
        title: "Triple Bullseye",
        summary: "Win 3 puzzles in 1 guess.",
        reward: 110
    )
    static let dailyLegend = Achievement(
        id: "daily-legend",
        title: "Daily Legend",
        summary: "Win 15 daily puzzles.",
        reward: 130
    )
    static let practiceMaster = Achievement(
        id: "practice-master",
        title: "Practice Master",
        summary: "Win 20 practice puzzles.",
        reward: 130
    )
    static let streakTen = Achievement(
        id: "streak-ten",
        title: "Ten Day Streak",
        summary: "Build a 10-day daily win streak.",
        reward: 160
    )
    static let fiftyWins = Achievement(
        id: "fifty-wins",
        title: "Fifty Wins",
        summary: "Win 50 puzzles across all modes.",
        reward: 190
    )
    static let centuryClub = Achievement(
        id: "century-club",
        title: "Century Club",
        summary: "Finish 100 puzzles in total.",
        reward: 220
    )

    static let all: [Achievement] = [
        .firstWin,
        .dailyStarter,
        .practiceStarter,
        .dailyDabbler,
        .practiceRegular,
        .gameNight,
        .sharpSolve,
        .oneShotWonder,
        .streakThree,
        .tenWins,
        .dailyDevotee,
        .practiceCraftsman,
        .seasonedPlayer,
        .streakFive,
        .twentyFiveWins,
        .precisionPair,
        .tripleBullseye,
        .dailyLegend,
        .practiceMaster,
        .streakTen,
        .fiftyWins,
        .centuryClub
    ]

    static let progressiveRevealChains: [[Achievement]] = [
        [.firstWin, .tenWins, .twentyFiveWins, .fiftyWins],
        [.dailyStarter, .dailyDabbler, .dailyDevotee, .dailyLegend],
        [.practiceStarter, .practiceRegular, .practiceCraftsman, .practiceMaster],
        [.gameNight, .seasonedPlayer, .centuryClub],
        [.sharpSolve, .precisionPair],
        [.oneShotWonder, .tripleBullseye],
        [.streakThree, .streakFive, .streakTen]
    ]

    static func visibleLockedAchievements(
        earnedAchievementIDs: Set<String>,
        stats: ModeStatsSnapshot
    ) -> [Achievement] {
        var visibleIDs = Set<String>()

        for chain in progressiveRevealChains {
            if let nextAchievement = chain.first(where: { !earnedAchievementIDs.contains($0.id) && !$0.isCompleted(stats: stats) }) {
                visibleIDs.insert(nextAchievement.id)
            }
        }

        let chainedIDs = Set(progressiveRevealChains.flatMap { chain in
            chain.map(\.id)
        })
        for achievement in all where !chainedIDs.contains(achievement.id) {
            guard !earnedAchievementIDs.contains(achievement.id), !achievement.isCompleted(stats: stats) else { continue }
            visibleIDs.insert(achievement.id)
        }

        return all.filter { visibleIDs.contains($0.id) }
    }

    static func earnedAchievementIDs(
        unlockedAchievementIDs: Set<String>,
        stats: ModeStatsSnapshot
    ) -> Set<String> {
        Set(all.compactMap { achievement in
            (unlockedAchievementIDs.contains(achievement.id) || achievement.isCompleted(stats: stats)) ? achievement.id : nil
        })
    }

    func isCompleted(stats: ModeStatsSnapshot) -> Bool {
        let bestDailyStreak = max(stats.daily.currentStreak, stats.daily.bestStreak)

        switch id {
        case Self.firstWin.id:
            return stats.totalWins >= 1
        case Self.dailyStarter.id:
            return stats.daily.wins >= 1
        case Self.practiceStarter.id:
            return stats.practice.wins >= 1
        case Self.dailyDabbler.id:
            return stats.daily.wins >= 3
        case Self.practiceRegular.id:
            return stats.practice.wins >= 5
        case Self.gameNight.id:
            return stats.totalPlayed >= 10
        case Self.sharpSolve.id:
            return stats.twoGuessWins >= 1
        case Self.oneShotWonder.id:
            return stats.oneGuessWins >= 1
        case Self.streakThree.id:
            return bestDailyStreak >= 3
        case Self.tenWins.id:
            return stats.totalWins >= 10
        case Self.dailyDevotee.id:
            return stats.daily.wins >= 7
        case Self.practiceCraftsman.id:
            return stats.practice.wins >= 10
        case Self.seasonedPlayer.id:
            return stats.totalPlayed >= 25
        case Self.streakFive.id:
            return bestDailyStreak >= 5
        case Self.twentyFiveWins.id:
            return stats.totalWins >= 25
        case Self.precisionPair.id:
            return stats.twoGuessWins >= 5
        case Self.tripleBullseye.id:
            return stats.oneGuessWins >= 3
        case Self.dailyLegend.id:
            return stats.daily.wins >= 15
        case Self.practiceMaster.id:
            return stats.practice.wins >= 20
        case Self.streakTen.id:
            return bestDailyStreak >= 10
        case Self.fiftyWins.id:
            return stats.totalWins >= 50
        case Self.centuryClub.id:
            return stats.totalPlayed >= 100
        default:
            return false
        }
    }

    func progressText(stats: ModeStatsSnapshot) -> String {
        let bestDailyStreak = max(stats.daily.currentStreak, stats.daily.bestStreak)

        switch id {
        case Self.firstWin.id:
            return "\(min(stats.totalWins, 1))/1 wins"
        case Self.dailyStarter.id:
            return "\(min(stats.daily.wins, 1))/1 daily wins"
        case Self.practiceStarter.id:
            return "\(min(stats.practice.wins, 1))/1 practice wins"
        case Self.dailyDabbler.id:
            return "\(min(stats.daily.wins, 3))/3 daily wins"
        case Self.practiceRegular.id:
            return "\(min(stats.practice.wins, 5))/5 practice wins"
        case Self.gameNight.id:
            return "\(min(stats.totalPlayed, 10))/10 puzzles"
        case Self.sharpSolve.id:
            return "\(min(stats.twoGuessWins, 1))/1 two-guess wins"
        case Self.oneShotWonder.id:
            return "\(min(stats.oneGuessWins, 1))/1 one-guess wins"
        case Self.streakThree.id:
            return "\(min(bestDailyStreak, 3))/3 day streak"
        case Self.tenWins.id:
            return "\(min(stats.totalWins, 10))/10 wins"
        case Self.dailyDevotee.id:
            return "\(min(stats.daily.wins, 7))/7 daily wins"
        case Self.practiceCraftsman.id:
            return "\(min(stats.practice.wins, 10))/10 practice wins"
        case Self.seasonedPlayer.id:
            return "\(min(stats.totalPlayed, 25))/25 puzzles"
        case Self.streakFive.id:
            return "\(min(bestDailyStreak, 5))/5 day streak"
        case Self.twentyFiveWins.id:
            return "\(min(stats.totalWins, 25))/25 wins"
        case Self.precisionPair.id:
            return "\(min(stats.twoGuessWins, 5))/5 two-guess wins"
        case Self.tripleBullseye.id:
            return "\(min(stats.oneGuessWins, 3))/3 one-guess wins"
        case Self.dailyLegend.id:
            return "\(min(stats.daily.wins, 15))/15 daily wins"
        case Self.practiceMaster.id:
            return "\(min(stats.practice.wins, 20))/20 practice wins"
        case Self.streakTen.id:
            return "\(min(bestDailyStreak, 10))/10 day streak"
        case Self.fiftyWins.id:
            return "\(min(stats.totalWins, 50))/50 wins"
        case Self.centuryClub.id:
            return "\(min(stats.totalPlayed, 100))/100 puzzles"
        default:
            return ""
        }
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

@MainActor
protocol DefinitionProviding {
    func definition(for word: String) async -> WordDefinition?
}

struct Puzzle: Equatable {
    let id: String
    let answer: String
    let reverseChain: [String]?

    init(id: String, answer: String, reverseChain: [String]? = nil) {
        self.id = id
        self.answer = answer
        self.reverseChain = reverseChain
    }
}

enum GameMessage: Equatable {
    case idle
    case notEnoughLetters
    case invalidWord
    case alreadyComplete
    case reverseMismatch
    case revealLetterUsed(Character)
    case revealLetterUnavailable
    case revealLetterUnsupportedMode
    case revealLetterNotOwned
    case removeWrongLettersUsed(Int)
    case removeWrongLettersUnavailable
    case removeWrongLettersUnsupportedMode
    case removeWrongLettersNotOwned

    var text: String {
        switch self {
        case .idle: ""
        case .notEnoughLetters: "Enter five letters."
        case .invalidWord: "That word is not in the collection."
        case .alreadyComplete: "This round is already complete."
        case .reverseMismatch: "That fits the rules, but not this hidden row."
        case .revealLetterUsed(let letter): "Revealed \(String(letter).uppercased()) in the puzzle."
        case .revealLetterUnavailable: "No hidden letters remain to reveal."
        case .revealLetterUnsupportedMode: "Reveal Letter is only available in Daily and Practice."
        case .revealLetterNotOwned: "Buy Reveal Letter in the store before using it."
        case .removeWrongLettersUsed(let count): count == 1 ? "Removed 1 wrong letter." : "Removed \(count) wrong letters."
        case .removeWrongLettersUnavailable: "No unused wrong letters remain to remove."
        case .removeWrongLettersUnsupportedMode: "Remove Wrong Letters is only available in Daily and Practice."
        case .removeWrongLettersNotOwned: "Buy Remove Wrong Letters in the store before using it."
        }
    }
}
