import Foundation
import UIKit

struct GameEngine {
    let maxGuesses: Int
    let wordLength: Int
    let validator: WordValidator

    init(maxGuesses: Int = 6, wordLength: Int = 5, validator: WordValidator) {
        self.maxGuesses = maxGuesses
        self.wordLength = wordLength
        self.validator = validator
    }

    @MainActor
    func submit(_ rawGuess: String, for session: inout GameSession) -> GameMessage {
        guard !session.isComplete else { return .alreadyComplete }

        let guess = rawGuess.lowercased()
        guard guess.count == wordLength else { return .notEnoughLetters }
        guard validator.isValid(guess) else { return .invalidWord }

        let evaluation = evaluate(guess: guess, answer: session.answer)
        session.guesses.append(evaluation)
        session.currentGuess = ""

        if guess == session.answer || session.guesses.count == maxGuesses {
            session.result = GameResult(
                won: guess == session.answer,
                answer: session.answer,
                attempts: session.guesses.count
            )
        }

        return .idle
    }

    func evaluate(guess: String, answer: String) -> GuessEvaluation {
        let guessLetters = Array(guess)
        let answerLetters = Array(answer)
        var states = Array(repeating: LetterState.absent, count: guessLetters.count)
        var remaining: [Character: Int] = [:]

        for index in guessLetters.indices {
            if guessLetters[index] == answerLetters[index] {
                states[index] = .correct
            } else {
                remaining[answerLetters[index], default: 0] += 1
            }
        }

        for index in guessLetters.indices where states[index] != .correct {
            let letter = guessLetters[index]
            if let count = remaining[letter], count > 0 {
                states[index] = .present
                remaining[letter] = count - 1
            }
        }

        return GuessEvaluation(guess: guess, states: states)
    }
}

@MainActor
struct BundleWordStore: PuzzleProvider, WordValidator {
    private let answers: [String]
    private let allowed: Set<String>
    private let calendar: Calendar
    private let systemDictionary = UITextChecker()

    init(bundle: Bundle = .main, calendar: Calendar = .current) {
        let loadedAnswers = Self.loadWords(named: "answers", bundle: bundle)
        let loadedAllowed = Self.loadWords(named: "allowed_guesses", bundle: bundle)
        answers = loadedAnswers.isEmpty ? Self.fallbackAnswers : loadedAnswers
        allowed = Set(answers + loadedAllowed + Self.fallbackAllowed)
        self.calendar = calendar
    }

    func isValid(_ word: String) -> Bool {
        let normalized = word.lowercased()
        guard normalized.count == 5, normalized.allSatisfy(\.isLetter) else { return false }
        if allowed.contains(normalized) { return true }

        let range = NSRange(location: 0, length: normalized.utf16.count)
        let misspelledRange = systemDictionary.rangeOfMisspelledWord(
            in: normalized,
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en_US"
        )
        return misspelledRange.location == NSNotFound
    }

    func puzzle(for mode: PuzzleMode, excluding recentAnswers: [String] = []) -> Puzzle {
        switch mode {
        case .daily:
            let day = calendar.startOfDay(for: Date())
            let seed = calendar.dateComponents([.day], from: Self.launchDay, to: day).day ?? 0
            let index = abs(seed) % answers.count
            return Puzzle(id: Self.dailyID(for: day), answer: answers[index])
        case .practice:
            let daily = puzzle(for: .daily).answer
            let blocked = Set(recentAnswers.suffix(12) + [daily])
            let pool = answers.filter { !blocked.contains($0) }
            let answer = (pool.isEmpty ? answers : pool).randomElement() ?? "crane"
            return Puzzle(id: "practice-\(UUID().uuidString)", answer: answer)
        }
    }

    static func dailyID(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "daily-%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }

    private static let launchDay = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 1))!

    private static func loadWords(named name: String, bundle: Bundle) -> [String] {
        guard let url = bundle.url(forResource: name, withExtension: "txt")
            ?? bundle.url(forResource: name, withExtension: "txt", subdirectory: "WordLists"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }

        return text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.count == 5 }
    }

    private static let fallbackAnswers = ["crane", "glint", "velvet", "amber", "crown"].filter { $0.count == 5 }
    private static let fallbackAllowed = ["adieu", "raise", "slate", "trace", "cigar", "rebut", "sissy", "humph", "awake"]
}
