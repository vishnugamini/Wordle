import XCTest
import SwiftData
import UIKit
@testable import AureliaWords

@MainActor
final class GameEngineTests: XCTestCase {
    private let validator = TestValidator()

    func testDuplicateLettersOnlyMarkAvailableMatches() {
        let engine = GameEngine(validator: validator)
        let evaluation = engine.evaluate(guess: "allee", answer: "apple")
        XCTAssertEqual(evaluation.states, [.correct, .present, .absent, .absent, .correct])
    }

    func testWinningGuessCompletesSession() {
        let engine = GameEngine(validator: validator)
        var session = GameSession(id: "daily-test", mode: .daily, puzzleID: "daily-test", answer: "crane", guesses: [], currentGuess: "CRANE", result: nil)

        XCTAssertEqual(engine.submit(session.currentGuess, for: &session), .idle)
        XCTAssertEqual(session.result, GameResult(won: true, answer: "crane", attempts: 1))
    }

    func testPracticeExcludesRecentAndDailyAnswer() {
        let store = BundleWordStore(bundle: .main)
        let daily = store.puzzle(for: .daily).answer
        let puzzle = store.puzzle(for: .practice, excluding: [daily])
        XCTAssertNotEqual(puzzle.answer, daily)
    }

    func testBundledAllowedGuessesAreValid() {
        let store = BundleWordStore(bundle: .main)

        XCTAssertTrue(store.isValid("raise"))
        XCTAssertTrue(store.isValid("slate"))
        XCTAssertTrue(store.isValid("trace"))
    }

    func testSystemDictionaryFiveLetterWordsAreValid() {
        let store = BundleWordStore(bundle: .main)

        XCTAssertTrue(store.isValid("apple"))
        XCTAssertTrue(store.isValid("house"))
        XCTAssertTrue(store.isValid("zebra"))
    }

    func testNonsenseAndNonLettersAreInvalid() {
        let store = BundleWordStore(bundle: .main)

        XCTAssertFalse(store.isValid("zzzzz"))
        XCTAssertFalse(store.isValid("abc1e"))
    }

    func testSettingsStoreDefaultsAndPersistence() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)

        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertFalse(settings.colorBlindMode)
        XCTAssertFalse(settings.reduceMotion)
        XCTAssertFalse(settings.hasSeenHowToPlay)

        settings.hapticsEnabled = false
        settings.colorBlindMode = true
        settings.reduceMotion = true
        settings.markHowToPlaySeen()

        let reloaded = AppSettingsStore(context: harness.context)
        XCTAssertFalse(reloaded.hapticsEnabled)
        XCTAssertTrue(reloaded.colorBlindMode)
        XCTAssertTrue(reloaded.reduceMotion)
        XCTAssertTrue(reloaded.hasSeenHowToPlay)
    }

    func testColorBlindPaletteUsesDifferentAccentColors() {
        let standardPresent = rgba(UIColor(LetterState.present.color(colorBlindMode: false)))
        let colorBlindPresent = rgba(UIColor(LetterState.present.color(colorBlindMode: true)))
        let standardCorrect = rgba(UIColor(LetterState.correct.color(colorBlindMode: false)))
        let colorBlindCorrect = rgba(UIColor(LetterState.correct.color(colorBlindMode: true)))

        XCTAssertNotEqual(standardPresent, colorBlindPresent)
        XCTAssertNotEqual(standardCorrect, colorBlindCorrect)
    }

    func testStatsSnapshotTracksBestAndCurrentStreaksAcrossGaps() {
        let calendar = Calendar(identifier: .gregorian)
        let first = calendar.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let second = calendar.date(from: DateComponents(year: 2026, month: 4, day: 21))!
        let fourth = calendar.date(from: DateComponents(year: 2026, month: 4, day: 23))!

        let records = [
            StoredGame(id: "daily-1", mode: .daily, puzzleID: "daily-1", answer: "crane", guesses: ["CRANE"], completed: true, won: true, attempts: 1, createdAt: first, completedAt: first),
            StoredGame(id: "daily-2", mode: .daily, puzzleID: "daily-2", answer: "slate", guesses: ["SLATE"], completed: true, won: true, attempts: 1, createdAt: second, completedAt: second),
            StoredGame(id: "daily-4", mode: .daily, puzzleID: "daily-4", answer: "pride", guesses: ["PRIDE"], completed: true, won: true, attempts: 1, createdAt: fourth, completedAt: fourth)
        ]

        let snapshot = StatsSnapshot.from(records)

        XCTAssertEqual(snapshot.played, 3)
        XCTAssertEqual(snapshot.wins, 3)
        XCTAssertEqual(snapshot.bestStreak, 2)
        XCTAssertEqual(snapshot.currentStreak, 1)
    }

    func testDailyResumesStoredSession() throws {
        let harness = try TestHarness()
        let daily = harness.store.dailyPuzzle
        let record = StoredGame(
            id: daily.id,
            mode: .daily,
            puzzleID: daily.id,
            answer: daily.answer,
            guesses: ["SLATE", "CRANE"]
        )
        harness.context.insert(record)
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: AppSettingsStore(context: harness.context), store: harness.store)

        XCTAssertEqual(viewModel.session.id, daily.id)
        XCTAssertEqual(viewModel.session.answer, daily.answer)
        XCTAssertEqual(viewModel.session.guesses.map(\.guess), ["SLATE", "CRANE"])
    }

    func testPracticeResumesLatestUnfinishedRound() throws {
        let harness = try TestHarness()
        let older = StoredGame(
            id: "practice-older",
            mode: .practice,
            puzzleID: "practice-older",
            answer: "flint",
            guesses: ["SLATE"],
            createdAt: Date(timeIntervalSince1970: 10)
        )
        let latest = StoredGame(
            id: "practice-latest",
            mode: .practice,
            puzzleID: "practice-latest",
            answer: "glove",
            guesses: ["CRANE", "GLOVE"],
            createdAt: Date(timeIntervalSince1970: 20)
        )
        harness.context.insert(older)
        harness.context.insert(latest)
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .practice, settings: AppSettingsStore(context: harness.context), store: harness.store)

        XCTAssertEqual(viewModel.session.id, "practice-latest")
        XCTAssertEqual(viewModel.session.answer, "glove")
        XCTAssertEqual(viewModel.session.guesses.map(\.guess), ["CRANE", "GLOVE"])
    }

    func testStartFreshPracticeCreatesNewPuzzleAndResumesNewestSession() throws {
        let harness = try TestHarness()
        let existing = StoredGame(
            id: "practice-existing",
            mode: .practice,
            puzzleID: "practice-existing",
            answer: "flint",
            guesses: ["SLATE"],
            createdAt: Date(timeIntervalSince1970: 10)
        )
        harness.context.insert(existing)
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .practice, settings: AppSettingsStore(context: harness.context), store: harness.store)
        XCTAssertEqual(viewModel.session.id, "practice-existing")

        viewModel.startFreshPractice()

        XCTAssertEqual(viewModel.session.id, "practice-fresh")
        XCTAssertEqual(viewModel.session.answer, "glove")

        let records = try harness.context.fetch(FetchDescriptor<StoredGame>(sortBy: [SortDescriptor(\.createdAt)]))
        XCTAssertEqual(records.filter { $0.mode == .practice }.count, 2)

        let reloaded = GameViewModel(context: harness.context, mode: .practice, settings: AppSettingsStore(context: harness.context), store: harness.store)
        XCTAssertEqual(reloaded.session.id, "practice-fresh")
    }

    func testSwitchingModesDoesNotCreateDuplicateStoredGames() throws {
        let harness = try TestHarness()
        let daily = harness.store.dailyPuzzle
        harness.context.insert(
            StoredGame(
                id: daily.id,
                mode: .daily,
                puzzleID: daily.id,
                answer: daily.answer,
                guesses: ["SLATE"]
            )
        )
        harness.context.insert(
            StoredGame(
                id: "practice-existing",
                mode: .practice,
                puzzleID: "practice-existing",
                answer: "flint",
                guesses: ["CRANE"],
                createdAt: Date(timeIntervalSince1970: 20)
            )
        )
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: AppSettingsStore(context: harness.context), store: harness.store)
        viewModel.switchMode(.practice)
        viewModel.switchMode(.daily)

        let records = try harness.context.fetch(FetchDescriptor<StoredGame>())
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(viewModel.session.id, daily.id)
    }
}

private func rgba(_ color: UIColor) -> [CGFloat] {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue, alpha]
}

private struct TestValidator: WordValidator {
    func isValid(_ word: String) -> Bool { true }
}

@MainActor
private struct TestHarness {
    let container: ModelContainer
    let context: ModelContext
    let store = TestWordStore()

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: StoredGame.self, StoredSettings.self, configurations: configuration)
        context = ModelContext(container)
    }
}

@MainActor
private struct TestWordStore: PuzzleProvider, WordValidator {
    let dailyPuzzle = Puzzle(id: "daily-fixed", answer: "crane")
    private let practicePuzzles = [
        Puzzle(id: "practice-existing", answer: "flint"),
        Puzzle(id: "practice-fresh", answer: "glove"),
        Puzzle(id: "practice-third", answer: "spore")
    ]

    func puzzle(for mode: PuzzleMode, excluding recentAnswers: [String]) -> Puzzle {
        switch mode {
        case .daily:
            return dailyPuzzle
        case .practice:
            return practicePuzzles.first { !recentAnswers.contains($0.answer) } ?? practicePuzzles[0]
        }
    }

    func isValid(_ word: String) -> Bool { true }
}
