import XCTest

/// Drives the real app on the watch simulator: taps the coin and checks that a
/// face is revealed and the tally keeps up.
final class CoinTossUITests: XCTestCase {

    /// Matches the headline that reports the landed face.
    private static let resultPredicate = NSPredicate(
        format: "label == %@ OR label == %@", "Heads", "Tails"
    )

    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.terminate()
        app.launch()

        // watchOS can restore the app to whatever screen it was last showing,
        // so pop back to the toss screen before a test starts on it.
        let back = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Back")).firstMatch
        if back.waitForExistence(timeout: 3) {
            back.tap()
        }
        return app
    }

    /// The coin is the only control on the main screen — tapping it tosses.
    private func coin(in app: XCUIApplication) -> XCUIElement {
        let coin = app.buttons["coin"].firstMatch
        XCTAssertTrue(coin.waitForExistence(timeout: 20), "Coin never appeared")
        return coin
    }

    /// Polls with a *fresh* query each time. `waitForExistence` on a query built
    /// once can sit on a stale accessibility snapshot, which makes assertions
    /// about content that appears mid-animation flaky.
    @discardableResult
    private func waitForLabel(
        _ app: XCUIApplication,
        containing text: String,
        timeout: TimeInterval = 20
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let predicate = NSPredicate(format: "label CONTAINS %@", text)

        while Date() < deadline {
            if app.descendants(matching: .any).matching(predicate).firstMatch.exists {
                return true
            }
            _ = XCTWaiter.wait(for: [expectation(description: "poll")], timeout: 0.3)
        }
        return false
    }

    @MainActor
    func testLaunchesWaitingForAFlip() {
        let app = launchApp()

        XCTAssertTrue(
            app.staticTexts["Tap to flip"].waitForExistence(timeout: 20),
            "Expected the pre-flip prompt on launch"
        )
    }

    @MainActor
    func testTappingTheCoinRevealsAFace() {
        let app = launchApp()
        coin(in: app).tap()

        XCTAssertTrue(
            waitForLabel(app, containing: "out of 1 flips"),
            "Tally did not report the first flip"
        )
        XCTAssertTrue(
            app.staticTexts.matching(Self.resultPredicate).firstMatch.exists,
            "Coin never settled on Heads or Tails"
        )
    }

    @MainActor
    func testTallyAccumulatesAcrossFlips() {
        let app = launchApp()
        let coin = coin(in: app)

        coin.tap()
        XCTAssertTrue(waitForLabel(app, containing: "out of 1 flips"))

        // The tally is published a moment before the coin is re-enabled, so
        // poll rather than checking the instant the tally shows up.
        XCTAssertTrue(waitUntilEnabled(coin), "Coin stayed disabled after it settled")
        coin.tap()

        XCTAssertTrue(
            waitForLabel(app, containing: "out of 2 flips"),
            "Tally did not report the second flip"
        )
    }

    @MainActor
    func testResetClearsTheTally() {
        let app = launchApp()
        coin(in: app).tap()

        XCTAssertTrue(waitForLabel(app, containing: "out of 1 flips"))

        let reset = app.buttons["Reset tally"].firstMatch
        XCTAssertTrue(reset.waitForExistence(timeout: 10), "Reset control never appeared")
        reset.tap()

        XCTAssertTrue(
            app.staticTexts["Tap to flip"].waitForExistence(timeout: 10),
            "Resetting did not return the app to its pre-flip state"
        )
    }

    @MainActor
    func testSettingsOffersEveryCoin() {
        let app = launchApp()
        openSettings(in: app)

        // Tick coins off as they scroll past, rather than hunting for each in
        // turn. The crown is used instead of a swipe because one swipe can
        // carry a row straight through the viewport without it ever existing.
        // Labels are read in a single snapshot per scroll — querying each name
        // separately turns this into hundreds of round trips.
        var remaining: Set<String> = [
            "US Cent", "Rupee", "Five Pounds",
            "Classic", "Quarter", "Doubloon", "Bitcoin", "Jade",
        ]

        for _ in 0..<25 {
            remaining.subtract(app.buttons.allElementsBoundByIndex.map(\.label))
            if remaining.isEmpty { break }
            XCUIDevice.shared.rotateDigitalCrown(delta: 0.5)
        }

        XCTAssertTrue(
            remaining.isEmpty,
            "Missing from the coin list: \(remaining.sorted().joined(separator: ", "))"
        )
    }

    @MainActor
    func testChoosingACoinChangesTheCoinInPlay() {
        let app = launchApp()
        openSettings(in: app)

        XCTAssertTrue(scrollToLabel(app, containing: "Quarter"))
        app.buttons["Quarter"].firstMatch.tap()

        // Back out to the toss screen and confirm the new coin is in play.
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Back")).firstMatch.tap()

        XCTAssertTrue(
            waitForLabel(app, containing: "Quarter coin"),
            "The chosen coin did not carry back to the toss screen"
        )
    }

    @MainActor
    func testTallyToggleControlsVisibilityWithoutLosingCount() {
        let app = launchApp()
        openSettings(in: app)

        // The Sound/Tally section sits below the eight-coin list, off-screen
        // until scrolled — same as the coin rows in the tests above.
        XCTAssertTrue(scrollToLabel(app, containing: "Tally"), "Tally toggle never appeared")
        let tallyToggle = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Tally")).firstMatch

        // Off: a flip still happens, but the tally stays out of sight.
        tallyToggle.tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Back")).firstMatch.tap()
        coin(in: app).tap()

        XCTAssertTrue(
            app.staticTexts.matching(Self.resultPredicate).firstMatch.waitForExistence(timeout: 10),
            "The flip should still happen even with the tally hidden"
        )
        XCTAssertFalse(
            waitForLabel(app, containing: "out of 1 flips", timeout: 3),
            "Tally should stay hidden after a flip once the toggle is off"
        )

        // Back on: the same tally the hidden flip already built reappears —
        // hiding it is presentation-only, not a reset.
        openSettings(in: app)
        XCTAssertTrue(scrollToLabel(app, containing: "Tally"), "Tally toggle never reappeared")
        app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Tally")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Back")).firstMatch.tap()

        XCTAssertTrue(
            waitForLabel(app, containing: "out of 1 flips"),
            "Tally should reappear, still showing the flip made while it was hidden"
        )
    }

    private func openSettings(in app: XCUIApplication) {
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 20), "Settings button never appeared")
        settings.tap()
    }

    /// Waits for a control to become tappable again after an animation.
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isEnabled { return true }
            _ = XCTWaiter.wait(for: [expectation(description: "poll")], timeout: 0.2)
        }
        return false
    }

    /// The coin list is taller than the watch screen, so scroll while looking.
    private func scrollToLabel(_ app: XCUIApplication, containing text: String) -> Bool {
        for attempt in 0..<20 {
            if waitForLabel(app, containing: text, timeout: attempt == 0 ? 5 : 0.5) {
                return true
            }
            XCUIDevice.shared.rotateDigitalCrown(delta: 0.5)
        }
        return false
    }
}
