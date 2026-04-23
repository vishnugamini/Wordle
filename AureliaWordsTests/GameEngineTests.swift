import XCTest
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
}

private struct TestValidator: WordValidator {
    func isValid(_ word: String) -> Bool { true }
}
