import XCTest

/// Drives the whole app on a booted simulator while CI records the screen —
/// producing the demo video. Every interaction is guarded: it only taps an
/// element that actually exists AND is hittable, otherwise it quietly skips.
/// Nothing here can abort the run, so the recording always captures the full
/// flow. Paced with short "beats" so the result is watchable.
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
        if search.waitForExistence(timeout: 6), search.isHittable {
            search.tap(); search.typeText("bowl"); beat(1.5)
            tap(app.buttons["Clear text"])
            tap(app.buttons["Cancel"])
            beat(0.8)
        }
        // Category filter
        tap(app.buttons["Bowls"]); beat(1.2)
        tap(app.buttons["All"]); beat(0.8)
        // "Safe only" lives at the end of the horizontal bar — scroll it in first.
        let safe = app.buttons["Safe only"]
        if safe.exists, !safe.isHittable {
            let drinks = app.buttons["Drinks"]
            if drinks.exists, drinks.isHittable { drinks.swipeLeft() }
            beat(0.5)
        }
        if tap(safe) { beat(1.4); tap(safe); beat(0.8) }   // toggle on, then off
    }

    private func dishDetails(_ app: XCUIApplication) {
        // A SAFE dish first (sorts near the top) — log it.
        if tapScrolling(app, app.buttons["dish-bowl-rajma-chawal"]) {
            beat(1.8)
            tap(app.buttons["logDish"]); beat(1.2)         // "I ate this"
            back(app); beat(1)
        }
        // An UNSAFE dish (contains dairy) — shows the red safety badge.
        if tapScrolling(app, app.buttons["dish-bowl-paneer-tikka"]) {
            beat(2)
            tap(app.buttons["favoriteToggle"]); beat(1)    // save to favorites
            tap(app.buttons["logDish"]); beat(1.2)
            back(app); beat(1)
        }
    }

    private func savedAndToday(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Saved"]); beat(2.2)
        tap(app.tabBars.buttons["Today"]); beat(2.6)       // ring + 7-day chart
    }

    private func aiMealLogging(_ app: XCUIApplication) {
        tap(app.buttons["logWithAI"]); beat(1.5)
        tap(app.segmentedControls.buttons["Describe"]); beat(1)

        var field = app.textViews["aiMealText"]
        if !field.waitForExistence(timeout: 3) { field = app.textFields["aiMealText"] }
        if field.waitForExistence(timeout: 3), field.isHittable {
            field.tap()
            field.typeText("2 rotis, dal and a mango lassi")
        }
        beat(1)
        tap(app.buttons["aiAnalyze"])
        // Wait for the live Gemini round-trip to return a result.
        _ = app.buttons["aiLogIt"].waitForExistence(timeout: 30)
        beat(2.6)                                          // show the AI result card
        tap(app.buttons["aiLogIt"]); beat(1.5)
        tap(app.buttons["Close"]); beat(1.5)
    }

    private func profile(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Profile"]); beat(2)
        tap(app.buttons["Dietary preferences"]); beat(2.2) // allergens, diet, goal
        back(app); beat(1.5)
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
            app.swipeUp()
            beat(0.3)
            if element.isHittable { element.tap(); return true }
        }
        return false
    }

    private func back(_ app: XCUIApplication) {
        let bar = app.navigationBars.firstMatch
        let button = bar.buttons.element(boundBy: 0)
        if button.exists, button.isHittable { button.tap() }
    }

    private func beat(_ seconds: Double = 1.3) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
