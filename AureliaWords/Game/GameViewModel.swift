import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class GameViewModel {
    private let context: ModelContext
    private let store: BundleWordStore
    private let engine: GameEngine
    private var storedGame: StoredGame?
    private(set) var session: GameSession
    private(set) var message: GameMessage = .idle
    private(set) var keyboardStates: [Character: LetterState] = [:]
    private(set) var stats = StatsSnapshot()

    var mode: PuzzleMode { session.mode }
    var isDailyComplete: Bool { session.mode == .daily && session.isComplete }

    init(context: ModelContext, mode: PuzzleMode = .daily) {
        self.context = context
        self.store = BundleWordStore()
        self.engine = GameEngine(validator: store)
        let puzzle = store.puzzle(for: mode)
        self.session = GameSession(id: puzzle.id, mode: mode, puzzleID: puzzle.id, answer: puzzle.answer, guesses: [], currentGuess: nilString, result: nil)
        load(mode: mode)
    }

    func switchMode(_ mode: PuzzleMode) {
        guard mode != session.mode else { return }
        load(mode: mode)
        message = .idle
    }

    func append(_ letter: Character) {
        guard !session.isComplete, session.currentGuess.count < engine.wordLength else { return }
        session.currentGuess.append(Character(letter.uppercased()))
        lightTap()
    }

    func deleteLetter() {
        guard !session.currentGuess.isEmpty, !session.isComplete else { return }
        session.currentGuess.removeLast()
        lightTap()
    }

    func submit() {
        let before = session.guesses.count
        let result = engine.submit(session.currentGuess, for: &session)
        message = result

        guard session.guesses.count > before else {
            warningTap()
            return
        }

        updateKeyboard()
        persistSession()
        if session.isComplete {
            successTap(won: session.result?.won == true)
        } else {
            lightTap()
        }
    }

    func startFreshPractice() {
        load(mode: .practice, forceNew: true)
    }

    func refreshStats() {
        let descriptor = FetchDescriptor<StoredGame>(
            predicate: #Predicate { $0.completed == true },
            sortBy: [SortDescriptor(\.completedAt)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        stats = StatsSnapshot.from(records)
    }

    private func load(mode: PuzzleMode, forceNew: Bool = false) {
        let recent = recentPracticeAnswers()
        let puzzle = store.puzzle(for: mode, excluding: recent)

        if !forceNew, let record = fetchStoredGame(mode: mode, puzzleID: puzzle.id) {
            storedGame = record
            session = makeSession(from: record)
        } else {
            storedGame = nil
            session = GameSession(id: puzzle.id, mode: mode, puzzleID: puzzle.id, answer: puzzle.answer, guesses: [], currentGuess: "", result: nil)
            persistSession()
        }

        updateKeyboard()
        refreshStats()
    }

    private func fetchStoredGame(mode: PuzzleMode, puzzleID: String) -> StoredGame? {
        let id = mode == .daily ? puzzleID : ""
        if mode == .practice { return nil }
        let descriptor = FetchDescriptor<StoredGame>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func makeSession(from record: StoredGame) -> GameSession {
        let guesses = record.guesses.map { engine.evaluate(guess: $0, answer: record.answer) }
        let result = record.completed ? GameResult(won: record.won, answer: record.answer, attempts: record.attempts) : nil
        return GameSession(id: record.id, mode: record.mode, puzzleID: record.puzzleID, answer: record.answer, guesses: guesses, currentGuess: "", result: result)
    }

    private func persistSession() {
        let guesses = session.guesses.map(\.guess)
        let record = storedGame ?? StoredGame(id: session.mode == .daily ? session.puzzleID : session.id, mode: session.mode, puzzleID: session.puzzleID, answer: session.answer)
        record.guesses = guesses
        record.completed = session.isComplete
        record.won = session.result?.won == true
        record.attempts = session.result?.attempts ?? guesses.count
        record.completedAt = session.isComplete ? Date() : nil
        if storedGame == nil {
            context.insert(record)
            storedGame = record
        }
        try? context.save()
        refreshStats()
    }

    private func updateKeyboard() {
        var states: [Character: LetterState] = [:]
        for guess in session.guesses {
            for (letter, state) in zip(Array(guess.guess.uppercased()), guess.states) {
                states[letter] = max(states[letter] ?? .unknown, state)
            }
        }
        keyboardStates = states
    }

    private func recentPracticeAnswers() -> [String] {
        let practiceRaw = PuzzleMode.practice.rawValue
        let descriptor = FetchDescriptor<StoredGame>(
            predicate: #Predicate { $0.modeRaw == practiceRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? []).prefix(12).map(\.answer)
    }

    private func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func warningTap() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func successTap(won: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(won ? .success : .error)
    }
}

private let nilString = ""

extension StatsSnapshot {
    static func from(_ records: [StoredGame]) -> StatsSnapshot {
        var snapshot = StatsSnapshot()
        snapshot.played = records.count
        snapshot.wins = records.filter(\.won).count
        for record in records where record.won {
            snapshot.guessDistribution[record.attempts, default: 0] += 1
        }

        let dailyWins = records
            .filter { $0.mode == .daily && $0.won }
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }

        var streak = 0
        var best = 0
        var previousDay: Date?
        let calendar = Calendar.current

        for record in dailyWins {
            guard let completedAt = record.completedAt else { continue }
            let day = calendar.startOfDay(for: completedAt)
            if let previousDay, calendar.dateComponents([.day], from: previousDay, to: day).day == 1 {
                streak += 1
            } else {
                streak = 1
            }
            previousDay = day
            best = max(best, streak)
        }

        snapshot.currentStreak = streak
        snapshot.bestStreak = best
        return snapshot
    }
}
