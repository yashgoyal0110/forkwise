import XCTest

/// Drives the whole app on a booted simulator while CI records the screen —
/// producing the demo video. Every interaction is guarded (wait-then-tap, no
/// hard assertions) so a missing element pauses that step instead of aborting
/// the recording. Paced with short "beats" so the result is watchable.
final class DemoFlow: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testFullWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitestDemo"]
        app.launch()
        beat(2)

        onboarding(app)
        explore(app)
        dishDetails(app)
        savedAndToday(app)
        aiMealLogging(app)
        profile(app)

        beat(1.5)
    }

    // MARK: - Flows

    private func onboarding(_ app: XCUIApplication) {
        tap(app.buttons["onboarding.primary"])          // Welcome → Diet
        beat()
        tap(app.buttons["diet-vegetarian"]); beat(0.8)
        tap(app.buttons["onboarding.primary"])          // Diet → Allergies
        beat()
        tap(app.buttons["allergen-nuts"]); beat(0.5)
        tap(app.buttons["allergen-dairy"]); beat(0.8)
        tap(app.buttons["onboarding.primary"])          // Allergies → Goal
        beat()
        tap(app.buttons["onboarding.primary"])          // Goal → Get started
        beat(2)
    }

    private func explore(_ app: XCUIApplication) {
        // Search
        let search = app.searchFields.firstMatch
        if search.waitForExistence(timeout: 6) {
            search.tap(); search.typeText("bowl"); beat(1.5)
            if app.buttons["Clear text"].exists { app.buttons["Clear text"].tap() }
            if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
            beat(0.8)
        }
        // Category + "Safe only" filter
        tap(app.buttons["Bowls"]); beat(1.2)
        tap(app.buttons["All"]); beat(0.8)
        tap(app.buttons["Safe only"]); beat(1.4)
        tap(app.buttons["Safe only"]); beat(0.8)
    }

    private func dishDetails(_ app: XCUIApplication) {
        // An UNSAFE dish (contains dairy) — shows the red safety badge.
        if tap(app.buttons["dish-bowl-paneer-tikka"]) {
            beat(2)
            tap(app.buttons["favoriteToggle"]); beat(1)     // save to favorites
            tap(app.buttons["logDish"]); beat(1.2)          // "I ate this"
            back(app); beat(1)
        }
        // A SAFE dish — log it too.
        if tap(app.buttons["dish-bowl-rajma-chawal"]) {
            beat(1.6)
            tap(app.buttons["logDish"]); beat(1.2)
            back(app); beat(1)
        }
    }

    private func savedAndToday(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Saved"]); beat(2.2)
        tap(app.tabBars.buttons["Today"]); beat(2.6)        // ring + 7-day chart
    }

    private func aiMealLogging(_ app: XCUIApplication) {
        tap(app.buttons["logWithAI"]); beat(1.5)
        tap(app.segmentedControls.buttons["Describe"]); beat(1)

        var field = app.textViews["aiMealText"]
        if !field.waitForExistence(timeout: 3) { field = app.textFields["aiMealText"] }
        if field.waitForExistence(timeout: 3) {
            field.tap()
            field.typeText("2 rotis, dal and a mango lassi")
        }
        beat(1)
        tap(app.buttons["aiAnalyze"])
        // Wait for the live Gemini round-trip to return a result.
        _ = app.buttons["aiLogIt"].waitForExistence(timeout: 30)
        beat(2.6)                                           // show the AI result card
        tap(app.buttons["aiLogIt"]); beat(1.5)
        tap(app.buttons["Close"]); beat(1.5)
    }

    private func profile(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Profile"]); beat(2)
        tap(app.buttons["Dietary preferences"]); beat(2.2)  // allergens, diet, goal
        back(app); beat(1.5)
    }

    // MARK: - Helpers

    @discardableResult
    private func tap(_ element: XCUIElement, timeout: Double = 8) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        element.tap()
        return true
    }

    private func back(_ app: XCUIApplication) {
        let bar = app.navigationBars.firstMatch
        if bar.buttons.count > 0 { bar.buttons.element(boundBy: 0).tap() }
    }

    private func beat(_ seconds: Double = 1.3) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
