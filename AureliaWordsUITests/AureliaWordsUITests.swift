import XCTest

final class AureliaWordsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchAndOpenHomeActions() {
        let app = XCUIApplication()
        app.launch()

        dismissHowToPlayIfNeeded(in: app)

        XCTAssertTrue(app.buttons["home.play"].waitForExistence(timeout: 5))

        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.switches["settings.haptics"].waitForExistence(timeout: 2))
        app.buttons["settings.close"].tap()

        app.buttons["home.about"].tap()
        XCTAssertTrue(app.buttons["about.close"].waitForExistence(timeout: 2))
        app.buttons["about.close"].tap()
    }

    func testCanOpenHowToPlayAndStats() {
        let app = XCUIApplication()
        app.launch()

        dismissHowToPlayIfNeeded(in: app)

        app.buttons["home.howToPlay"].tap()
        XCTAssertTrue(app.buttons["help.close"].waitForExistence(timeout: 2))
        app.buttons["help.close"].tap()

        app.buttons["home.stats"].tap()
        XCTAssertTrue(app.buttons["stats.close"].waitForExistence(timeout: 2))
        app.buttons["stats.close"].tap()
    }

    func testCanStartPracticeAndSubmitGuess() {
        let app = XCUIApplication()
        app.launch()

        dismissHowToPlayIfNeeded(in: app)

        app.buttons["home.mode.practice"].tap()
        app.buttons["home.play"].tap()

        XCTAssertTrue(app.buttons["keyboard.key.C"].waitForExistence(timeout: 5))
        type(word: "CRANE", in: app)
        app.buttons["keyboard.enter"].tap()

        let firstTile = app.otherElements["game.tile.0.0"]
        XCTAssertTrue(firstTile.waitForExistence(timeout: 2))

        app.buttons["app.stats"].tap()
        XCTAssertTrue(app.buttons["stats.close"].waitForExistence(timeout: 2))
    }

    private func dismissHowToPlayIfNeeded(in app: XCUIApplication) {
        let helpClose = app.buttons["help.close"]
        if helpClose.waitForExistence(timeout: 2) {
            helpClose.tap()
        }
    }

    private func type(word: String, in app: XCUIApplication) {
        for letter in word {
            app.buttons["keyboard.key.\(letter)"].tap()
        }
    }
}
