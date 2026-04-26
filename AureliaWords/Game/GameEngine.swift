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

        if session.isReverseMode {
            let hiddenChain = session.reverseHiddenChain
            guard let activeRow = session.reverseActiveRow, hiddenChain.indices.contains(activeRow) else {
                return .alreadyComplete
            }

            let targetEvaluation = evaluate(guess: hiddenChain[activeRow], answer: session.answer)
            let evaluation = evaluate(guess: guess, answer: session.answer)
            guard evaluation.states == targetEvaluation.states else { return .reverseMismatch }

            session.guesses.append(evaluation)
            session.currentGuess = ""

            if session.guesses.count == hiddenChain.count {
                session.result = GameResult(
                    won: true,
                    answer: session.answer,
                    attempts: session.guesses.count
                )
            }

            return .idle
        }

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
    private enum ReverseGenerator {
        static let hiddenWordCount = 5
        static let minimumBucketSize = 2
        static let attemptLimit = 64
    }

    private let answers: [String]
    private let dailyAnswers: [String]
    private let practiceAnswers: [String]
    private let allowed: Set<String>
    private let reversePuzzles: [Puzzle]
    private let calendar: Calendar
    private let systemDictionary: UITextChecker
    private let practiceGenerator: PracticeWordGenerator
    private let evaluator = GameEngine(validator: ReverseWordValidator())

    var dailyAnswerCount: Int { dailyAnswers.count }
    func canUseAsDailyAnswer(_ word: String) -> Bool { dailyAnswers.contains(word.lowercased()) }
    var practiceAnswerCount: Int { practiceAnswers.count }
    func canUseAsPracticeAnswer(_ word: String) -> Bool { practiceAnswers.contains(word.lowercased()) }

    init(bundle: Bundle = .main, calendar: Calendar = Self.dailyCalendar) {
        let checker = UITextChecker()
        let loadedAnswers = Self.loadWords(named: "answers", bundle: bundle)
        let loadedAllowed = Self.loadWords(named: "allowed_guesses", bundle: bundle)
        answers = loadedAnswers.isEmpty ? Self.fallbackAnswers : loadedAnswers
        systemDictionary = checker
        allowed = Set(answers + loadedAllowed + Self.fallbackAllowed)
        dailyAnswers = Self.makeDailyAnswers(
            answers: answers,
            allowed: loadedAllowed + Self.fallbackAllowed
        )
        practiceAnswers = Self.makePlayableAnswers(
            answers: answers,
            allowed: allowed,
            dictionary: checker
        )
        practiceGenerator = PracticeWordGenerator(words: practiceAnswers)
        reversePuzzles = Self.curatedReversePuzzles
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
        puzzle(for: mode, on: Date(), excluding: recentAnswers)
    }

    func puzzle(for mode: PuzzleMode, on date: Date, excluding recentAnswers: [String] = []) -> Puzzle {
        switch mode {
        case .daily:
            let day = calendar.startOfDay(for: date)
            let seed = calendar.dateComponents([.day], from: Self.launchDay, to: day).day ?? 0
            return Puzzle(id: Self.dailyID(for: day), answer: dailyAnswer(forSeed: seed))
        case .practice:
            let daily = puzzle(for: .daily, on: date).answer
            let blocked = Set(recentAnswers.suffix(12) + [daily])
            let answer = practiceGenerator.nextWord(excluding: blocked)
            return Puzzle(id: "practice-\(UUID().uuidString)", answer: answer)
        case .reverse:
            let blocked = Set(recentAnswers.suffix(12))
            if let generated = makeReversePuzzle(excluding: blocked) {
                return generated
            }

            let pool = reversePuzzles.filter { !blocked.contains($0.answer) }
            return (pool.isEmpty ? reversePuzzles : pool).randomElement() ?? Self.curatedReversePuzzles[0]
        }
    }

    static func dailyID(for date: Date, calendar: Calendar = Self.dailyCalendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "daily-%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }

    private static let dailyCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private static let launchDay = dailyCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

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

    private func dailyAnswer(forSeed seed: Int) -> String {
        let fallbackPool = dailyAnswers.isEmpty ? answers : dailyAnswers
        let index = abs(seed) % fallbackPool.count
        return fallbackPool[index]
    }

    private static func makeDailyAnswers(answers: [String], allowed: [String]) -> [String] {
        Array(Set(answers + allowed))
            .filter { $0.count == 5 && $0.allSatisfy(\.isLetter) }
            .sorted()
    }

    private static func makePlayableAnswers(
        answers: [String],
        allowed: Set<String>,
        dictionary: UITextChecker
    ) -> [String] {
        Array(Set(answers).union(allowed))
            .filter { isDictionaryWord($0, dictionary: dictionary) }
            .sorted()
    }

    private static func isDictionaryWord(_ word: String, dictionary: UITextChecker) -> Bool {
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = dictionary.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en_US"
        )
        return misspelledRange.location == NSNotFound
    }

    private func makeReversePuzzle(excluding blocked: Set<String>) -> Puzzle? {
        let pool = practiceAnswers.filter { !blocked.contains($0) }
        let fallbackPool = practiceAnswers
        let candidateAnswers = (pool.isEmpty ? fallbackPool : pool).shuffled()
        let candidateWords = practiceAnswers

        for answer in candidateAnswers.prefix(ReverseGenerator.attemptLimit) {
            guard let hiddenChain = makeReverseHiddenChain(for: answer, candidates: candidateWords) else { continue }
            return Puzzle(
                id: "reverse-\(UUID().uuidString)",
                answer: answer,
                reverseChain: hiddenChain + [answer]
            )
        }

        return nil
    }

    private func makeReverseHiddenChain(for answer: String, candidates: [String]) -> [String]? {
        var buckets: [String: [String]] = [:]

        for guess in candidates where guess != answer {
            let states = evaluator.evaluate(guess: guess, answer: answer).states
            guard !states.allSatisfy({ $0 == .absent }) else { continue }
            guard !states.allSatisfy({ $0 == .correct }) else { continue }
            let key = patternKey(for: states)
            buckets[key, default: []].append(guess)
        }

        let bucketPool = buckets.values
            .filter { $0.count >= ReverseGenerator.minimumBucketSize }
            .shuffled()

        guard bucketPool.count >= ReverseGenerator.hiddenWordCount else { return nil }

        var usedWords = Set([answer])
        var hiddenChain: [String] = []

        for bucket in bucketPool {
            guard let choice = bucket.shuffled().first(where: { !usedWords.contains($0) }) else { continue }
            usedWords.insert(choice)
            hiddenChain.append(choice)

            if hiddenChain.count == ReverseGenerator.hiddenWordCount {
                return hiddenChain
            }
        }

        return nil
    }

    private func patternKey(for states: [LetterState]) -> String {
        states.map(\.rawValue).joined(separator: "|")
    }

    private static let fallbackAnswers = ["crane", "glint", "velvet", "amber", "crown"].filter { $0.count == 5 }
    private static let fallbackAllowed = ["adieu", "raise", "slate", "trace", "cigar", "rebut", "sissy", "humph", "awake"]
    private static let curatedReversePuzzles: [Puzzle] = [
        Puzzle(
            id: "reverse-crank",
            answer: "crank",
            reverseChain: ["blush", "stare", "break", "track", "clank", "crank"]
        ),
        Puzzle(
            id: "reverse-slate",
            answer: "slate",
            reverseChain: ["cough", "irate", "plate", "stave", "slake", "slate"]
        ),
        Puzzle(
            id: "reverse-pride",
            answer: "pride",
            reverseChain: ["crown", "brine", "prime", "bride", "prize", "pride"]
        )
    ]
}

private struct ReverseWordValidator: WordValidator {
    func isValid(_ word: String) -> Bool { true }
}
