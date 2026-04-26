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

    func testReverseModeAcceptsAnyRealWordMatchingActivePattern() {
        let engine = GameEngine(validator: validator)
        var session = GameSession(
            id: "reverse-test",
            mode: .reverse,
            puzzleID: "reverse-test",
            answer: "crane",
            reverseChain: ["slate", "glare", "crane"],
            guesses: [],
            currentGuess: "SLATE",
            result: nil
        )

        XCTAssertEqual(engine.submit(session.currentGuess, for: &session), .reverseMismatch)
        XCTAssertTrue(session.guesses.isEmpty)
        XCTAssertNil(session.result)

        session.currentGuess = "BLARE"
        XCTAssertEqual(engine.submit(session.currentGuess, for: &session), .idle)
        XCTAssertEqual(session.guesses.map(\.guess), ["blare"])
        XCTAssertEqual(session.guesses.first?.states, engine.evaluate(guess: "glare", answer: "crane").states)
        XCTAssertEqual(session.reverseActiveRow, 0)
    }

    func testReverseModeAcceptsDuplicateLetterGuessMatchingActivePattern() {
        let engine = GameEngine(validator: validator)
        var session = GameSession(
            id: "reverse-duplicate-test",
            mode: .reverse,
            puzzleID: "reverse-duplicate-test",
            answer: "apple",
            reverseChain: ["allee", "apple"],
            guesses: [],
            currentGuess: "ALLEE",
            result: nil
        )

        XCTAssertEqual(engine.submit(session.currentGuess, for: &session), .idle)
        XCTAssertEqual(session.guesses.map(\.guess), ["allee"])
        XCTAssertEqual(session.result, GameResult(won: true, answer: "apple", attempts: 1))
    }

    func testReverseGuessLookupKeepsRowsAlignedWithPlayedWords() {
        let session = GameSession(
            id: "reverse-rows",
            mode: .reverse,
            puzzleID: "reverse-rows",
            answer: "crane",
            reverseChain: ["bloom", "stare", "break", "track", "crack", "crank"],
            guesses: [
                GuessEvaluation(guess: "slack", states: [.absent, .absent, .correct, .correct, .correct]),
                GuessEvaluation(guess: "trick", states: [.absent, .correct, .absent, .correct, .correct]),
                GuessEvaluation(guess: "bleak", states: [.absent, .absent, .present, .correct, .absent])
            ],
            currentGuess: "",
            result: nil
        )

        XCTAssertEqual(session.reverseGuess(forRow: 4)?.guess, "slack")
        XCTAssertEqual(session.reverseGuess(forRow: 3)?.guess, "trick")
        XCTAssertEqual(session.reverseGuess(forRow: 2)?.guess, "bleak")
        XCTAssertNil(session.reverseGuess(forRow: 1))
    }

    func testPracticeExcludesRecentAndDailyAnswer() {
        let store = BundleWordStore(bundle: .main)
        let daily = store.puzzle(for: .daily).answer
        let puzzle = store.puzzle(for: .practice, excluding: [daily])
        XCTAssertNotEqual(puzzle.answer, daily)
    }

    func testPracticeUsesExpandedAnswerPool() {
        let store = BundleWordStore(bundle: .main)

        XCTAssertGreaterThan(store.practiceAnswerCount, 48)
        XCTAssertTrue(store.canUseAsPracticeAnswer("raise"))
        XCTAssertTrue(store.canUseAsPracticeAnswer("slate"))
    }

    func testPracticeAnswersComeFromDictionaryBackedPool() {
        let store = BundleWordStore(bundle: .main)

        for _ in 0..<25 {
            let puzzle = store.puzzle(for: .practice)
            XCTAssertTrue(store.canUseAsPracticeAnswer(puzzle.answer))
            XCTAssertTrue(store.isValid(puzzle.answer))
        }
    }

    func testDailyUsesExpandedFallbackPool() {
        let store = BundleWordStore(bundle: .main)
        let firstDaily = store.puzzle(for: .daily)
        let secondDaily = store.puzzle(for: .daily)

        XCTAssertGreaterThan(store.dailyAnswerCount, 48)
        XCTAssertTrue(store.canUseAsDailyAnswer("raise"))
        XCTAssertTrue(store.canUseAsDailyAnswer("slate"))
        XCTAssertEqual(firstDaily, secondDaily)
        XCTAssertTrue(store.isValid(firstDaily.answer))
    }

    func testDailyPuzzleUsesFixedUTCDay() throws {
        let store = BundleWordStore(bundle: .main)
        let formatter = ISO8601DateFormatter()
        let utcBoundary = try XCTUnwrap(formatter.date(from: "2026-04-25T00:30:00Z"))
        var losAngelesCalendar = Calendar(identifier: .gregorian)
        losAngelesCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        let daily = store.puzzle(for: .daily, on: utcBoundary)

        XCTAssertEqual(daily.id, "daily-2026-04-25")
        XCTAssertEqual(BundleWordStore.dailyID(for: utcBoundary), "daily-2026-04-25")
        XCTAssertEqual(BundleWordStore.dailyID(for: utcBoundary, calendar: losAngelesCalendar), "daily-2026-04-24")
    }

    func testReverseGenerationBuildsDistinctHiddenChain() throws {
        let store = BundleWordStore(bundle: .main)
        let puzzle = store.puzzle(for: .reverse, excluding: ["crank", "slate", "pride"])

        XCTAssertNotEqual(puzzle.answer, "crank")
        XCTAssertNotEqual(puzzle.answer, "slate")
        XCTAssertNotEqual(puzzle.answer, "pride")

        let reverseChain = try XCTUnwrap(puzzle.reverseChain)
        XCTAssertEqual(reverseChain.count, 6)
        XCTAssertEqual(reverseChain.last, puzzle.answer)
        XCTAssertEqual(Set(reverseChain).count, reverseChain.count)

        let engine = GameEngine(validator: validator)
        let hiddenWords = Array(reverseChain.dropLast())
        let patterns = hiddenWords.map { engine.evaluate(guess: $0, answer: puzzle.answer).states.map(\.rawValue).joined(separator: "|") }

        XCTAssertEqual(Set(hiddenWords).count, 5)
        XCTAssertEqual(Set(patterns).count, hiddenWords.count)
        XCTAssertFalse(patterns.contains("absent|absent|absent|absent|absent"))
        XCTAssertFalse(patterns.contains("correct|correct|correct|correct|correct"))
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
        XCTAssertEqual(settings.coins, 1000)
        XCTAssertNil(settings.lastCheckInAt)
        XCTAssertTrue(settings.unlockedAchievementIDs.isEmpty)

        settings.hapticsEnabled = false
        settings.colorBlindMode = true
        settings.reduceMotion = true
        settings.markHowToPlaySeen()
        settings.awardCoins(42)
        settings.unlockAchievement(.firstWin)

        let reloaded = AppSettingsStore(context: harness.context)
        XCTAssertFalse(reloaded.hapticsEnabled)
        XCTAssertTrue(reloaded.colorBlindMode)
        XCTAssertTrue(reloaded.reduceMotion)
        XCTAssertTrue(reloaded.hasSeenHowToPlay)
        XCTAssertEqual(reloaded.coins, 1067)
        XCTAssertTrue(reloaded.hasUnlockedAchievement(.firstWin))
    }

    func testDailyCheckInOnlyAwardsOncePerDay() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let calendar = Calendar(identifier: .gregorian)
        let firstCheckIn = calendar.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 9))!
        let sameDayLater = calendar.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 18))!
        let nextDay = calendar.date(from: DateComponents(year: 2026, month: 4, day: 25, hour: 8))!

        XCTAssertTrue(settings.claimDailyCheckInIfNeeded(now: firstCheckIn))
        XCTAssertEqual(settings.coins, 1000 + CoinReward.dailyCheckIn)
        XCTAssertFalse(settings.claimDailyCheckInIfNeeded(now: sameDayLater))
        XCTAssertEqual(settings.coins, 1000 + CoinReward.dailyCheckIn)
        XCTAssertTrue(settings.claimDailyCheckInIfNeeded(now: nextDay))
        XCTAssertEqual(settings.coins, 1000 + (CoinReward.dailyCheckIn * 2))
    }

    func testStorePurchasePersistsInventoryAndDeductsCoins() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.awardCoins(80)

        XCTAssertEqual(settings.purchase(.revealLetter), .success)
        XCTAssertEqual(settings.coins, 1040)
        XCTAssertEqual(settings.ownedCount(for: .revealLetter), 1)

        let reloaded = AppSettingsStore(context: harness.context)
        XCTAssertEqual(reloaded.coins, 1040)
        XCTAssertEqual(reloaded.ownedCount(for: .revealLetter), 1)
    }

    func testRemoveWrongLettersCatalogItemCostsThirtyCoinsAndPurchasesIntoInventory() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let item = try XCTUnwrap(settings.storeCatalog.first { $0.id == .removeWrongLetters })

        XCTAssertEqual(item.name, "Remove Wrong Letters")
        XCTAssertEqual(item.price, 30)
        XCTAssertEqual(settings.purchase(item), .success)
        XCTAssertEqual(settings.coins, 970)
        XCTAssertEqual(settings.ownedCount(for: .removeWrongLetters), 1)
    }

    func testStorePurchaseFailsWhenCoinsAreInsufficient() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.awardCoins(20)

        XCTAssertEqual(settings.purchase(.revealLetter), .insufficientCoins)
        XCTAssertEqual(settings.coins, 1020)
        XCTAssertEqual(settings.ownedCount(for: .revealLetter), 0)
    }

    func testWinningDailyPuzzleAwardsCoinsAndAchievements() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        for letter in "CRANE" {
            viewModel.append(letter)
        }
        viewModel.submit()

        XCTAssertEqual(viewModel.session.result, GameResult(won: true, answer: "crane", attempts: 1))
        XCTAssertEqual(
            settings.coins,
            CoinReward.correctAnswer
                + Achievement.firstWin.reward
                + Achievement.dailyStarter.reward
                + Achievement.oneShotWonder.reward
        )
        XCTAssertTrue(settings.hasUnlockedAchievement(.firstWin))
        XCTAssertTrue(settings.hasUnlockedAchievement(.dailyStarter))
        XCTAssertTrue(settings.hasUnlockedAchievement(.oneShotWonder))
    }

    func testVisibleLockedAchievementsStartAsNextGoalsOnly() {
        let visible = Achievement.visibleLockedAchievements(
            earnedAchievementIDs: [],
            stats: ModeStatsSnapshot()
        )

        XCTAssertEqual(
            visible.map(\.id),
            [
                Achievement.firstWin.id,
                Achievement.dailyStarter.id,
                Achievement.practiceStarter.id,
                Achievement.gameNight.id,
                Achievement.sharpSolve.id,
                Achievement.oneShotWonder.id,
                Achievement.streakThree.id
            ]
        )
    }

    func testVisibleLockedAchievementsAdvanceAfterEarlierMilestonesAreEarned() {
        let earnedIDs: Set<String> = [
            Achievement.firstWin.id,
            Achievement.dailyStarter.id,
            Achievement.practiceStarter.id,
            Achievement.gameNight.id,
            Achievement.sharpSolve.id,
            Achievement.oneShotWonder.id,
            Achievement.streakThree.id
        ]

        let visible = Achievement.visibleLockedAchievements(
            earnedAchievementIDs: earnedIDs,
            stats: ModeStatsSnapshot()
        )

        XCTAssertEqual(
            visible.map(\.id),
            [
                Achievement.dailyDabbler.id,
                Achievement.practiceRegular.id,
                Achievement.tenWins.id,
                Achievement.seasonedPlayer.id,
                Achievement.streakFive.id,
                Achievement.precisionPair.id,
                Achievement.tripleBullseye.id
            ]
        )
    }

    func testCompletedPuzzleLoadsDefinition() async throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let viewModel = GameViewModel(
            context: harness.context,
            mode: .daily,
            settings: settings,
            store: harness.store,
            definitionProvider: TestDefinitionProvider()
        )

        for letter in "CRANE" {
            viewModel.append(letter)
        }
        viewModel.submit()

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(
            viewModel.resultDefinitionState,
            .loaded(
                WordDefinition(
                    word: "crane",
                    meanings: [
                        WordMeaning(
                            partOfSpeech: "noun",
                            text: "a tall wading bird with long legs and a long neck"
                        )
                    ],
                    sourceName: "Test Dictionary"
                )
            )
        )
    }

    func testShareTextForDailyWinUsesSpoilerFreeGrid() throws {
        let session = GameSession(
            id: "daily-share",
            mode: .daily,
            puzzleID: "daily-2026-04-25",
            answer: "crane",
            guesses: [
                GuessEvaluation(guess: "slate", states: [.absent, .present, .absent, .correct, .absent]),
                GuessEvaluation(guess: "crane", states: [.correct, .correct, .correct, .correct, .correct])
            ],
            currentGuess: "",
            result: GameResult(won: true, answer: "crane", attempts: 2)
        )

        let shareText = try XCTUnwrap(GameShareTextFormatter.text(for: session))

        XCTAssertEqual(
            shareText,
            """
            Aurelia Words Daily
            Apr 25, 2026 • 2/6 tries

            ⬛🟨⬛🟩⬛
            🟩🟩🟩🟩🟩
            """
        )
        XCTAssertFalse(shareText.localizedCaseInsensitiveContains("crane"))
    }

    func testShareTextForDailyLossUsesXScoreAndOmitsAnswer() throws {
        let session = GameSession(
            id: "daily-loss-share",
            mode: .daily,
            puzzleID: "daily-loss-share",
            answer: "crane",
            guesses: Array(repeating: GuessEvaluation(guess: "blush", states: [.absent, .absent, .absent, .absent, .absent]), count: 6),
            currentGuess: "",
            result: GameResult(won: false, answer: "crane", attempts: 6)
        )

        let shareText = try XCTUnwrap(GameShareTextFormatter.text(for: session))

        XCTAssertTrue(shareText.hasPrefix("Aurelia Words Daily\nX/6 tries"))
        XCTAssertFalse(shareText.localizedCaseInsensitiveContains("crane"))
        XCTAssertEqual(shareText.components(separatedBy: "\n").filter { $0 == "⬛⬛⬛⬛⬛" }.count, 6)
    }

    func testShareTextForReverseUsesHiddenRowCountDenominator() throws {
        let session = GameSession(
            id: "reverse-share",
            mode: .reverse,
            puzzleID: "reverse-share",
            answer: "crank",
            reverseChain: ["blush", "stare", "break", "track", "clank", "crank"],
            guesses: [
                GuessEvaluation(guess: "clank", states: [.correct, .absent, .correct, .correct, .correct]),
                GuessEvaluation(guess: "track", states: [.absent, .correct, .present, .correct, .correct]),
                GuessEvaluation(guess: "break", states: [.absent, .correct, .present, .correct, .correct]),
                GuessEvaluation(guess: "stare", states: [.absent, .absent, .present, .correct, .absent]),
                GuessEvaluation(guess: "blush", states: [.absent, .absent, .absent, .absent, .absent])
            ],
            currentGuess: "",
            result: GameResult(won: true, answer: "crank", attempts: 5)
        )

        let shareText = try XCTUnwrap(GameShareTextFormatter.text(for: session))

        XCTAssertTrue(shareText.hasPrefix("Aurelia Words Reverse\n5/5 rows"))
        XCTAssertFalse(shareText.localizedCaseInsensitiveContains("crank"))
        XCTAssertEqual(shareText.components(separatedBy: "\n").filter { $0.count == 5 }.count, 5)
    }

    func testRevealLetterConsumesInventoryAndPersistsHint() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.revealLetter.rawValue: 1]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .success)
        XCTAssertEqual(settings.ownedCount(for: .revealLetter), 0)
        XCTAssertEqual(viewModel.session.revealedHintIndices, Set([0]))
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 0), "C")

        let reloaded = GameViewModel(context: harness.context, mode: .daily, settings: AppSettingsStore(context: harness.context), store: harness.store)
        XCTAssertEqual(reloaded.session.revealedHintIndices, Set([0]))
        XCTAssertEqual(reloaded.session.currentGuessLetter(at: 0), "C")
    }

    func testRevealLetterComposesWinningGuessWithPinnedLetters() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.revealLetter.rawValue: 2]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .success)
        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .success)
        XCTAssertEqual(viewModel.session.revealedHintIndices, Set([0, 1]))
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 0), "C")
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 1), "R")

        for letter in "ANE" {
            viewModel.append(letter)
        }
        viewModel.deleteLetter()
        XCTAssertEqual(viewModel.session.currentGuess, "AN")
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 0), "C")
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 1), "R")

        viewModel.append("E")
        XCTAssertEqual(viewModel.session.composedCurrentGuess(), "crane")

        viewModel.submit()

        XCTAssertEqual(viewModel.session.result, GameResult(won: true, answer: "crane", attempts: 1))
    }

    func testRevealLetterSkipsLettersAlreadyCorrectInPreviousGuesses() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.revealLetter.rawValue: 1]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        for letter in "CRATE" {
            viewModel.append(letter)
        }
        viewModel.submit()

        XCTAssertEqual(viewModel.session.guesses.first?.states, [.correct, .correct, .correct, .absent, .correct])
        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .success)
        XCTAssertEqual(viewModel.session.revealedHintIndices, Set([3]))
        XCTAssertEqual(viewModel.session.currentGuessLetter(at: 3), "N")
    }

    func testRevealLetterCannotBeUsedWithoutInventoryOrWhenAllHintsAlreadyExist() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .unavailable)

        settings.inventoryCounts = [StoreItemID.revealLetter.rawValue: 6]
        for _ in 0..<5 {
            XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .success)
        }

        XCTAssertEqual(viewModel.session.revealedHintIndices, Set(0..<5))
        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .unavailable)
    }

    func testRevealLetterIsRejectedInReverseMode() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.revealLetter.rawValue: 1]
        let viewModel = GameViewModel(context: harness.context, mode: .reverse, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRevealLetter(selectIndex: { $0.first }), .unsupportedMode)
        XCTAssertEqual(settings.ownedCount(for: .revealLetter), 1)
    }

    func testRemoveWrongLettersConsumesInventoryRemovesTwoLettersAndPersists() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.removeWrongLetters.rawValue: 1]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .success)
        XCTAssertEqual(settings.ownedCount(for: .removeWrongLetters), 0)
        XCTAssertEqual(viewModel.session.removedLetters.count, 2)
        XCTAssertTrue(viewModel.session.removedLetters.isDisjoint(with: Set("CRANE")))

        let removed = viewModel.session.removedLetters
        let blockedLetter = try XCTUnwrap(removed.first)
        viewModel.append(blockedLetter)
        XCTAssertTrue(viewModel.session.currentGuess.isEmpty)

        let reloaded = GameViewModel(context: harness.context, mode: .daily, settings: AppSettingsStore(context: harness.context), store: harness.store)
        XCTAssertEqual(reloaded.session.removedLetters, removed)
    }

    func testRemoveWrongLettersSkipsAnswerSubmittedAndDraftLetters() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.removeWrongLetters.rawValue: 1]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        for letter in "BLUSH" {
            viewModel.append(letter)
        }
        viewModel.submit()
        viewModel.append("D")

        XCTAssertEqual(viewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .success)

        let unavailable = Set("CRANEBLUSHD")
        XCTAssertTrue(viewModel.session.removedLetters.isDisjoint(with: unavailable))
    }

    func testRemoveWrongLettersDoesNotConsumeWhenNoCandidateIsSelectedOrNoCandidateRemains() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.inventoryCounts = [StoreItemID.removeWrongLetters.rawValue: 13]
        let viewModel = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertEqual(viewModel.useRemoveWrongLetters(selectLetters: { _ in [] }), .unavailable)
        XCTAssertEqual(settings.ownedCount(for: .removeWrongLetters), 13)

        for _ in 0..<11 {
            XCTAssertEqual(viewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .success)
        }

        XCTAssertEqual(viewModel.session.removedLetters.count, 21)
        XCTAssertEqual(settings.ownedCount(for: .removeWrongLetters), 2)
        XCTAssertEqual(viewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .unavailable)
        XCTAssertEqual(settings.ownedCount(for: .removeWrongLetters), 2)
    }

    func testRemoveWrongLettersIsRejectedInReverseModeAndAfterCompletion() throws {
        let harness = try TestHarness()
        let reverseSettings = AppSettingsStore(context: harness.context)
        reverseSettings.inventoryCounts = [StoreItemID.removeWrongLetters.rawValue: 1]
        let reverseViewModel = GameViewModel(context: harness.context, mode: .reverse, settings: reverseSettings, store: harness.store)

        XCTAssertEqual(reverseViewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .unsupportedMode)
        XCTAssertEqual(reverseSettings.ownedCount(for: .removeWrongLetters), 1)

        let dailySettings = AppSettingsStore(context: harness.context)
        dailySettings.inventoryCounts = [StoreItemID.removeWrongLetters.rawValue: 1]
        let dailyViewModel = GameViewModel(context: harness.context, mode: .daily, settings: dailySettings, store: harness.store)

        for letter in "CRANE" {
            dailyViewModel.append(letter)
        }
        dailyViewModel.submit()

        XCTAssertEqual(dailyViewModel.useRemoveWrongLetters(selectLetters: { Array($0.prefix(2)) }), .unavailable)
        XCTAssertEqual(dailySettings.ownedCount(for: .removeWrongLetters), 1)
    }

    func testCompletedAchievementsBackfillFromStoredStatsOnLoad() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let completedAt = Date(timeIntervalSince1970: 100)
        harness.context.insert(
            StoredGame(
                id: harness.store.dailyPuzzle.id,
                mode: .daily,
                puzzleID: harness.store.dailyPuzzle.id,
                answer: harness.store.dailyPuzzle.answer,
                guesses: ["CRANE"],
                completed: true,
                won: true,
                attempts: 1,
                createdAt: completedAt,
                completedAt: completedAt
            )
        )
        try harness.context.save()

        _ = GameViewModel(context: harness.context, mode: .daily, settings: settings, store: harness.store)

        XCTAssertTrue(settings.hasUnlockedAchievement(.firstWin))
        XCTAssertTrue(settings.hasUnlockedAchievement(.dailyStarter))
        XCTAssertTrue(settings.hasUnlockedAchievement(.oneShotWonder))
        XCTAssertEqual(
            settings.coins,
            Achievement.firstWin.reward
                + Achievement.dailyStarter.reward
                + Achievement.oneShotWonder.reward
        )
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

    func testReverseResumesStoredSessionWithChain() throws {
        let harness = try TestHarness()
        let reverse = harness.store.reversePuzzle
        harness.context.insert(
            StoredGame(
                id: reverse.id,
                mode: .reverse,
                puzzleID: reverse.id,
                answer: reverse.answer,
                reverseChain: reverse.reverseChain,
                guesses: ["CLANK", "TRACK"],
                createdAt: Date(timeIntervalSince1970: 30)
            )
        )
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .reverse, settings: AppSettingsStore(context: harness.context), store: harness.store)

        XCTAssertEqual(viewModel.session.id, reverse.id)
        XCTAssertEqual(viewModel.session.answer, reverse.answer)
        XCTAssertEqual(viewModel.session.reverseChain, reverse.reverseChain)
        XCTAssertEqual(viewModel.session.guesses.map(\.guess), ["CLANK", "TRACK"])
        XCTAssertEqual(viewModel.session.reverseActiveRow, 2)
    }

    func testReverseResumesStoredSessionWithDuplicateLetters() throws {
        let harness = try TestHarness()
        harness.context.insert(
            StoredGame(
                id: "reverse-duplicate",
                mode: .reverse,
                puzzleID: "reverse-duplicate",
                answer: "apple",
                reverseChain: ["allee", "apple"],
                createdAt: Date(timeIntervalSince1970: 30)
            )
        )
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .reverse, settings: AppSettingsStore(context: harness.context), store: harness.store)

        XCTAssertEqual(viewModel.session.id, "reverse-duplicate")
        XCTAssertEqual(viewModel.session.answer, "apple")
        XCTAssertEqual(viewModel.session.reverseChain, ["allee", "apple"])
    }

    func testReverseDiscardsStoredSessionWithInvalidAllAbsentPattern() throws {
        let harness = try TestHarness()
        harness.context.insert(
            StoredGame(
                id: "reverse-legacy",
                mode: .reverse,
                puzzleID: "reverse-legacy",
                answer: "verge",
                reverseChain: ["audio", "stage", "plate", "burgh", "vasts", "verge"],
                guesses: ["AUDIO"],
                createdAt: Date(timeIntervalSince1970: 30)
            )
        )
        try harness.context.save()

        let viewModel = GameViewModel(context: harness.context, mode: .reverse, settings: AppSettingsStore(context: harness.context), store: harness.store)

        XCTAssertEqual(viewModel.session.id, harness.store.reversePuzzle.id)
        XCTAssertEqual(viewModel.session.answer, harness.store.reversePuzzle.answer)
        XCTAssertEqual(viewModel.session.reverseChain, harness.store.reversePuzzle.reverseChain)
        XCTAssertTrue(viewModel.session.guesses.isEmpty)
    }

    func testReverseCompletionAwardsCoinsAndUpdatesReverseStats() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        let viewModel = GameViewModel(context: harness.context, mode: .reverse, settings: settings, store: harness.store)

        for word in ["CLANK", "TRACK", "BREAK", "STARE", "BLUSH"] {
            for letter in word {
                viewModel.append(letter)
            }
            viewModel.submit()
        }

        XCTAssertEqual(viewModel.session.result, GameResult(won: true, answer: "crank", attempts: 5))
        XCTAssertEqual(viewModel.stats.reverse.wins, 1)
        XCTAssertEqual(viewModel.stats.practice.wins, 0)
        XCTAssertEqual(viewModel.stats.daily.wins, 0)
        XCTAssertEqual(settings.coins, CoinReward.correctAnswer + Achievement.firstWin.reward)
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

    func testSkinPurchaseAndEquipPersistAcrossSettingsReload() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.coins = 250

        XCTAssertEqual(settings.purchaseSkin(.paperInk), .success)
        XCTAssertTrue(settings.ownsSkin(.paperInk))
        XCTAssertTrue(settings.equipSkin(.paperInk))
        XCTAssertEqual(settings.coins, 130)

        let reloaded = AppSettingsStore(context: harness.context)
        XCTAssertTrue(reloaded.ownsSkin(.paperInk))
        XCTAssertEqual(reloaded.selectedSkin.id, .paperInk)
        XCTAssertTrue(reloaded.ownsSkin(.default))
    }

    func testSkinCannotBeRepurchasedAndDefaultsRemainValid() throws {
        let harness = try TestHarness()
        let settings = AppSettingsStore(context: harness.context)
        settings.coins = 500

        XCTAssertEqual(settings.purchaseSkin(.frostglass), .success)
        XCTAssertEqual(settings.purchaseSkin(.frostglass), .alreadyOwned)
        XCTAssertEqual(settings.purchaseSkin(.default), .alreadyOwned)
        XCTAssertTrue(settings.equipSkin(.default))
        XCTAssertEqual(settings.selectedSkin.id, .default)
    }

    func testSkinCatalogIncludesExpandedPremiumCollection() {
        let ids = Set(AureliaTheme.availableSkins.map(\.id))

        XCTAssertEqual(AureliaTheme.availableSkins.count, 7)
        XCTAssertTrue(ids.contains(.default))
        XCTAssertTrue(ids.contains(.paperInk))
        XCTAssertTrue(ids.contains(.frostglass))
        XCTAssertTrue(ids.contains(.velvetNoir))
        XCTAssertTrue(ids.contains(.jadePorcelain))
        XCTAssertTrue(ids.contains(.emberLacquer))
        XCTAssertTrue(ids.contains(.sapphireClub))
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

private struct TestDefinitionProvider: DefinitionProviding {
    func definition(for word: String) async -> WordDefinition? {
        WordDefinition(
            word: word,
            meanings: [
                WordMeaning(
                    partOfSpeech: "noun",
                    text: "a tall wading bird with long legs and a long neck"
                )
            ],
            sourceName: "Test Dictionary"
        )
    }
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
    let reversePuzzle = Puzzle(
        id: "reverse-fixed",
        answer: "crank",
        reverseChain: ["blush", "stare", "break", "track", "clank", "crank"]
    )
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
        case .reverse:
            return reversePuzzle
        }
    }

    func isValid(_ word: String) -> Bool { true }
}
