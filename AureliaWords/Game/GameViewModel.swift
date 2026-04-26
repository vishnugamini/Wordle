import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class GameViewModel {
    private let context: ModelContext
    private let store: any PuzzleProvider & WordValidator
    private let engine: GameEngine
    @ObservationIgnored private let definitionProvider: DefinitionProviding
    @ObservationIgnored private let settings: AppSettingsStore
    @ObservationIgnored private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    @ObservationIgnored private let warningFeedback = UINotificationFeedbackGenerator()
    @ObservationIgnored private let successFeedback = UINotificationFeedbackGenerator()
    @ObservationIgnored private var statsRefreshTask: Task<Void, Never>?
    private var storedGame: StoredGame?
    private(set) var session: GameSession
    private(set) var message: GameMessage = .idle
    private(set) var keyboardStates: [Character: LetterState] = [:]
    private(set) var stats = ModeStatsSnapshot()
    private(set) var resultDefinitionState: WordDefinitionState = .idle

    var mode: PuzzleMode { session.mode }
    var isDailyComplete: Bool { session.mode == .daily && session.isComplete }
    var shareText: String? { GameShareTextFormatter.text(for: session) }
    var completedSessionMinutesText: String {
        let start = storedGame?.createdAt ?? Date()
        let end = storedGame?.completedAt ?? Date()
        let minutes = max(1, Int(ceil(end.timeIntervalSince(start) / 60)))
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    init(
        context: ModelContext,
        mode: PuzzleMode = .daily,
        settings: AppSettingsStore,
        store: any PuzzleProvider & WordValidator = BundleWordStore(),
        definitionProvider: DefinitionProviding = DictionaryDefinitionService()
    ) {
        self.context = context
        self.settings = settings
        self.store = store
        self.engine = GameEngine(validator: store)
        self.definitionProvider = definitionProvider
        let puzzle = store.puzzle(for: mode, excluding: [])
        self.session = GameSession(
            id: puzzle.id,
            mode: mode,
            puzzleID: puzzle.id,
            answer: puzzle.answer,
            reverseChain: puzzle.reverseChain,
            guesses: [],
            currentGuess: nilString,
            result: nil
        )
        prepareFeedback()
        load(mode: mode)
        refreshStats()
    }

    func switchMode(_ mode: PuzzleMode) {
        guard mode != session.mode else { return }
        load(mode: mode)
        message = .idle
    }

    func append(_ letter: Character) {
        let normalized = Character(letter.uppercased())
        guard !session.isComplete, session.currentGuess.count < session.editableSlotCount else { return }
        guard !session.removedLetters.contains(normalized) else { return }
        session.currentGuess.append(normalized)
        lightTap()
    }

    func deleteLetter() {
        guard !session.currentGuess.isEmpty, !session.isComplete else { return }
        session.currentGuess.removeLast()
        lightTap()
    }

    func submit() {
        let before = session.guesses.count
        guard let guess = session.composedCurrentGuess() else {
            message = .notEnoughLetters
            warningTap()
            return
        }

        let result = engine.submit(guess, for: &session)
        message = result

        guard session.guesses.count > before else {
            warningTap()
            return
        }

        updateKeyboard()
        persistSession()
        if session.isComplete {
            applyCompletionRewardsIfNeeded()
            lookupDefinitionIfNeeded()
        }
        if session.isComplete {
            successTap(won: session.result?.won == true)
        } else {
            lightTap()
        }
    }

    func useRevealLetter(selectIndex: ([Int]) -> Int? = { $0.randomElement() }) -> StoreConsumeResult {
        guard !session.isReverseMode else {
            message = .revealLetterUnsupportedMode
            return .unsupportedMode
        }
        guard !session.isComplete else {
            message = .alreadyComplete
            return .unavailable
        }
        guard settings.ownedCount(for: .revealLetter) > 0 else {
            message = .revealLetterNotOwned
            return .unavailable
        }

        let candidates = Array(0..<engine.wordLength).filter { index in
            !session.revealedHintIndices.contains(index)
                && !session.guesses.contains { guess in
                    guess.states.indices.contains(index) && guess.states[index] == .correct
                }
        }
        guard let selectedIndex = selectIndex(candidates), candidates.contains(selectedIndex) else {
            message = .revealLetterUnavailable
            return .unavailable
        }
        guard settings.consume(.revealLetter) else {
            message = .revealLetterNotOwned
            return .unavailable
        }

        let priorEditableColumns = session.editableColumns
        let draftIndexToRemove = priorEditableColumns.firstIndex(of: selectedIndex)
        session.revealedHintIndices.insert(selectedIndex)

        if let draftIndexToRemove, draftIndexToRemove < session.currentGuess.count {
            var draftLetters = Array(session.currentGuess)
            draftLetters.remove(at: draftIndexToRemove)
            session.currentGuess = String(draftLetters)
        }

        persistSession()
        let revealedLetter = Array(session.answer.uppercased())[selectedIndex]
        message = .revealLetterUsed(revealedLetter)
        lightTap()
        return .success
    }

    func useRemoveWrongLetters(selectLetters: ([Character]) -> [Character] = { Array($0.shuffled().prefix(2)) }) -> StoreConsumeResult {
        guard !session.isReverseMode else {
            message = .removeWrongLettersUnsupportedMode
            return .unsupportedMode
        }
        guard !session.isComplete else {
            message = .alreadyComplete
            return .unavailable
        }
        guard settings.ownedCount(for: .removeWrongLetters) > 0 else {
            message = .removeWrongLettersNotOwned
            return .unavailable
        }

        let answerLetters = Set(session.answer.uppercased())
        let usedLetters = Set(keyboardStates.keys)
        let draftLetters = Set(session.currentGuess.uppercased())
        let candidates = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").filter { letter in
            !answerLetters.contains(letter)
                && !usedLetters.contains(letter)
                && !draftLetters.contains(letter)
                && !session.removedLetters.contains(letter)
        }
        var selectedLetters: [Character] = []
        for letter in selectLetters(candidates) where candidates.contains(letter) && !selectedLetters.contains(letter) {
            selectedLetters.append(letter)
            if selectedLetters.count == 2 { break }
        }

        guard !selectedLetters.isEmpty else {
            message = .removeWrongLettersUnavailable
            return .unavailable
        }
        guard settings.consume(.removeWrongLetters) else {
            message = .removeWrongLettersNotOwned
            return .unavailable
        }

        session.removedLetters.formUnion(selectedLetters)
        persistSession()
        message = .removeWrongLettersUsed(selectedLetters.count)
        lightTap()
        return .success
    }

    func scheduleStatsRefresh(after delayNanoseconds: UInt64) {
        statsRefreshTask?.cancel()
        statsRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard !Task.isCancelled else { return }
            self.refreshStats()
        }
    }

    func startFreshPractice() {
        load(mode: .practice, forceNew: true)
    }

    func startFreshReverse() {
        load(mode: .reverse, forceNew: true)
    }

    func refreshStats() {
        let descriptor = FetchDescriptor<StoredGame>(
            predicate: #Predicate { $0.completed == true },
            sortBy: [SortDescriptor(\.completedAt)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        stats = ModeStatsSnapshot.from(records)
        syncAchievementsWithStats()
    }

    private func applyCompletionRewardsIfNeeded() {
        guard session.result?.won == true else {
            refreshStats()
            return
        }

        settings.awardCoins(CoinReward.correctAnswer)
        refreshStats()
        unlockEligibleAchievements()
    }

    private func load(mode: PuzzleMode, forceNew: Bool = false) {
        resultDefinitionState = .idle
        if !forceNew, let record = fetchStoredGame(mode: mode), shouldResume(record: record) {
            storedGame = record
            session = makeSession(from: record)
        } else {
            if !forceNew, let record = fetchStoredGame(mode: mode), !shouldResume(record: record) {
                context.delete(record)
                try? context.save()
            }
            let excludedAnswers = mode == .practice || mode == .reverse ? recentAnswers(for: mode) : []
            let puzzle = store.puzzle(for: mode, excluding: excludedAnswers)
            storedGame = nil
            session = GameSession(
                id: puzzle.id,
                mode: mode,
                puzzleID: puzzle.id,
                answer: puzzle.answer,
                reverseChain: puzzle.reverseChain,
                guesses: [],
                currentGuess: "",
                result: nil
            )
            persistSession()
        }

        updateKeyboard()
        if session.isComplete {
            lookupDefinitionIfNeeded()
        }
    }

    private func shouldResume(record: StoredGame) -> Bool {
        guard record.mode == .reverse else { return true }
        guard let reverseChain = record.reverseChain, reverseChain.last == record.answer else { return false }

        let hiddenWords = reverseChain.dropLast()
        let patterns = hiddenWords.map { engine.evaluate(guess: $0, answer: record.answer).states }
        guard !patterns.contains(where: { states in states.allSatisfy { state in state == .absent } }) else { return false }
        guard !patterns.contains(where: { states in states.allSatisfy { state in state == .correct } }) else { return false }

        let patternKeys = patterns.map { $0.map(\.rawValue).joined(separator: "|") }
        return Set(patternKeys).count == patternKeys.count
    }

    private func fetchStoredGame(mode: PuzzleMode) -> StoredGame? {
        switch mode {
        case .daily:
            let dailyID = store.puzzle(for: .daily, excluding: []).id
            let descriptor = FetchDescriptor<StoredGame>(predicate: #Predicate { $0.id == dailyID })
            return try? context.fetch(descriptor).first
        case .practice, .reverse:
            let modeRaw = mode.rawValue
            let descriptor = FetchDescriptor<StoredGame>(
                predicate: #Predicate { $0.modeRaw == modeRaw && $0.completed == false },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try? context.fetch(descriptor).first
        }
    }

    private func makeSession(from record: StoredGame) -> GameSession {
        let guesses = record.guesses.map { engine.evaluate(guess: $0, answer: record.answer) }
        let result = record.completed ? GameResult(won: record.won, answer: record.answer, attempts: record.attempts) : nil
        return GameSession(
            id: record.id,
            mode: record.mode,
            puzzleID: record.puzzleID,
            answer: record.answer,
            reverseChain: record.reverseChain,
            revealedHintIndices: Set(record.revealedHintIndices),
            removedLetters: Set(record.removedLetters),
            guesses: guesses,
            currentGuess: "",
            result: result
        )
    }

    private func persistSession() {
        let guesses = session.guesses.map(\.guess)
        let record = storedGame ?? StoredGame(
            id: session.mode == .daily ? session.puzzleID : session.id,
            mode: session.mode,
            puzzleID: session.puzzleID,
            answer: session.answer,
            reverseChain: session.reverseChain
        )
        record.guesses = guesses
        record.reverseChain = session.reverseChain
        record.revealedHintIndices = Array(session.revealedHintIndices).sorted()
        record.removedLetters = Array(session.removedLetters).sorted()
        record.completed = session.isComplete
        record.won = session.result?.won == true
        record.attempts = session.result?.attempts ?? guesses.count
        record.completedAt = session.isComplete ? Date() : nil
        if storedGame == nil {
            context.insert(record)
            storedGame = record
        }
        try? context.save()
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

    private func recentAnswers(for mode: PuzzleMode) -> [String] {
        let modeRaw = mode.rawValue
        let descriptor = FetchDescriptor<StoredGame>(
            predicate: #Predicate { $0.modeRaw == modeRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? []).prefix(12).map(\.answer)
    }

    private func lightTap() {
        guard settings.hapticsEnabled else { return }
        lightFeedback.impactOccurred()
        lightFeedback.prepare()
    }

    private func warningTap() {
        guard settings.hapticsEnabled else { return }
        warningFeedback.notificationOccurred(.warning)
        warningFeedback.prepare()
    }

    private func successTap(won: Bool) {
        guard settings.hapticsEnabled else { return }
        successFeedback.notificationOccurred(won ? .success : .error)
        successFeedback.prepare()
    }

    private func prepareFeedback() {
        lightFeedback.prepare()
        warningFeedback.prepare()
        successFeedback.prepare()
    }

    private func lookupDefinitionIfNeeded() {
        guard session.result != nil else {
            resultDefinitionState = .idle
            return
        }

        let answer = session.answer.lowercased()
        let puzzleID = session.puzzleID
        resultDefinitionState = .loading

        Task { @MainActor [weak self] in
            guard let self else { return }
            let definition = await definitionProvider.definition(for: answer)
            guard self.session.puzzleID == puzzleID, self.session.answer.lowercased() == answer else { return }
            self.resultDefinitionState = definition.map(WordDefinitionState.loaded) ?? .unavailable
        }
    }

    private func unlockEligibleAchievements() {
        syncAchievementsWithStats()
    }

    private func syncAchievementsWithStats() {
        for achievement in Achievement.all where achievement.isCompleted(stats: stats) {
            settings.unlockAchievement(achievement)
        }
    }
}

private let nilString = ""

private extension Array {
    func appending(contentsOf elements: some Sequence<Element>) -> [Element] {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }
}

extension ModeStatsSnapshot {
    static func from(_ records: [StoredGame]) -> ModeStatsSnapshot {
        ModeStatsSnapshot(
            daily: StatsSnapshot.from(records.filter { $0.mode == .daily }),
            practice: StatsSnapshot.from(records.filter { $0.mode == .practice }),
            reverse: StatsSnapshot.from(records.filter { $0.mode == .reverse })
        )
    }
}

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
