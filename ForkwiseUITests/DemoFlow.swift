import XCTest

/// Drives the whole app on a booted simulator while CI records the screen —
/// producing the demo video. Every interaction is guarded (only taps elements
/// that exist AND are hittable, otherwise skips), so nothing can abort the run
/// and the recording always captures the full flow.
///
/// It prints `FORKWISE_MARK START/END <epoch>` so CI can trim the recording to
/// exactly the active window (cutting xcodebuild's spin-up and teardown).
final class DemoFlow: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testFullWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitestDemo"]
        app.launch()
        dismissSystemAlerts()
        _ = app.buttons["onboarding.primary"].waitForExistence(timeout: 20) // first screen up

        mark("START")
        beat(1.2)

        onboarding(app)
        explore(app)
        dishDetails(app)
        savedAndToday(app)
        aiMealLogging(app)
        profile(app)

        beat(1)
        mark("END")
    }

    // MARK: - Flows

    private func onboarding(_ app: XCUIApplication) {
        tap(app.buttons["onboarding.primary"]); beat()      // Welcome → Diet
        tap(app.buttons["diet-vegetarian"]); beat(0.9)
        tap(app.buttons["onboarding.primary"]); beat()      // Diet → Allergies
        tap(app.buttons["allergen-nuts"]); beat(0.6)
        tap(app.buttons["allergen-dairy"]); beat(0.9)
        tap(app.buttons["onboarding.primary"]); beat()      // Allergies → Goal
        beat(1.0)                                           // show the goal screen
        tap(app.buttons["onboarding.primary"]); beat(1.8)   // Goal → Get started
    }

    private func explore(_ app: XCUIApplication) {
        // Search
        let search = app.searchFields.firstMatch
        if search.waitForExistence(timeout: 8), search.isHittable {
            search.tap(); search.typeText("wrap"); beat(1.8)
            tap(app.buttons["Clear text"]); beat(0.4)
            tap(app.buttons["Cancel"]); beat(0.8)
        }
        // Category chips
        tap(app.buttons["Bowls"]); beat(1.3)
        tap(app.buttons["Wraps"]); beat(1.3)
        tap(app.buttons["All"]); beat(0.9)
        // "Safe only" is at the end of the horizontal bar — scroll it in first.
        let safe = app.buttons["Safe only"]
        if safe.exists, !safe.isHittable {
            let drinks = app.buttons["Drinks"]
            if drinks.exists, drinks.isHittable { drinks.swipeLeft() }
            beat(0.5)
        }
        if tap(safe) { beat(1.8); tap(safe); beat(0.8) }    // filter on (hides unsafe), then off
        // Scroll the list to show variety, then back up.
        app.swipeUp(); beat(1.0); app.swipeUp(); beat(1.0)
        app.swipeDown(); beat(0.6); app.swipeDown(); beat(0.8)
    }

    private func dishDetails(_ app: XCUIApplication) {
        // UNSAFE dish (contains dairy) — red safety badge, then show full detail.
        if tapScrolling(app, app.buttons["dish-bowl-paneer-tikka"]) {
            beat(2.0)
            app.swipeUp(); beat(1.8)                        // reveal nutrition, tags, allergens
            app.swipeDown(); beat(0.8)
            tap(app.buttons["favoriteToggle"]); beat(1.2)   // save to favorites
            tap(app.buttons["logDish"]); beat(1.4)          // "I ate this"
            back(app); beat(1.0)
        }
        // SAFE dish — green badge, log it too.
        if tapScrolling(app, app.buttons["dish-bowl-rajma-chawal"]) {
            beat(1.8)
            tap(app.buttons["logDish"]); beat(1.4)
            back(app); beat(1.0)
        }
    }

    private func savedAndToday(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Saved"]); beat(2.2)        // favorited dish
        tap(app.tabBars.buttons["Today"]); beat(2.4)        // ring + 7-day chart
        app.swipeUp(); beat(1.8)                            // the "Eaten today" list
        app.swipeDown(); beat(0.8)
    }

    private func aiMealLogging(_ app: XCUIApplication) {
        tap(app.buttons["logWithAI"]); beat(1.6)            // opens on the Photo option
        tap(app.segmentedControls.buttons["Describe"]); beat(1.1)

        var field = app.textViews["aiMealText"]
        if !field.waitForExistence(timeout: 3) { field = app.textFields["aiMealText"] }
        if field.waitForExistence(timeout: 3), field.isHittable {
            field.tap()
            field.typeText("2 rotis, dal and a mango lassi")
        }
        beat(1.0)
        tap(app.buttons["aiAnalyze"])
        _ = app.buttons["aiLogIt"].waitForExistence(timeout: 30)  // live Gemini round-trip
        beat(3.0)                                           // show the AI result card
        tap(app.buttons["aiLogIt"]); beat(1.6)
        tap(app.buttons["Close"]); beat(1.4)
    }

    private func profile(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Profile"]); beat(1.8)
        tap(app.buttons["Dietary preferences"]); beat(1.8)
        // Show it's editable: change diet and toggle an allergen.
        tap(app.segmentedControls.buttons["Vegan"]); beat(1.2)
        tap(app.switches["pref-allergen-gluten"]); beat(1.4)
        back(app); beat(1.4)
    }

    // MARK: - Helpers

    /// Taps only if the element exists and is hittable; otherwise skips.
    @discardableResult
    private func tap(_ element: XCUIElement, timeout: Double = 6) -> Bool {
        guard element.waitForExistence(timeout: timeout), element.isHittable else { return false }
        element.tap()
        return true
    }

    /// Taps an element, scrolling the list up a few times to reveal it if needed.
    @discardableResult
    private func tapScrolling(_ app: XCUIApplication, _ element: XCUIElement, timeout: Double = 6) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        if element.isHittable { element.tap(); return true }
        for _ in 0..<4 {
            app.swipeUp(); beat(0.3)
            if element.isHittable { element.tap(); return true }
        }
        return false
    }

    private func back(_ app: XCUIApplication) {
        let button = app.navigationBars.firstMatch.buttons.element(boundBy: 0)
        if button.exists, button.isHittable { button.tap() }
    }

    /// Dismisses a system permission alert (e.g. notifications) if one is on screen.
    private func dismissSystemAlerts() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            for label in ["Allow", "Allow While Using App", "OK"] {
                let button = springboard.buttons[label]
                if button.exists, button.isHittable { button.tap(); return }
            }
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    private func mark(_ label: String) {
        let line = "FORKWISE_MARK \(label) \(Date().timeIntervalSince1970)"
        print(line)
        NSLog("%@", line)
    }

    private func beat(_ seconds: Double = 1.3) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
