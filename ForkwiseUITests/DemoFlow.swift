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
        // "Safe only" filter — tapped only if it's reachable on the bar.
        let safe = app.buttons["Safe only"]
        if safe.exists, safe.isHittable {
            safe.tap(); beat(1.8); if safe.isHittable { safe.tap() }; beat(0.8)
        }
    }

    private func dishDetails(_ app: XCUIApplication) {
        // SAFE dish (sorts near the top) — green badge, log it.
        if tap(app.buttons["dish-bowl-rajma-chawal"]) {
            beat(2.0)
            tap(app.buttons["logDish"]); beat(1.4)          // "I ate this"
            back(app); beat(1.0)
        }
        // UNSAFE dish — surface it via search (no scrolling), show the red badge.
        let search = app.searchFields.firstMatch
        if search.waitForExistence(timeout: 4), search.isHittable {
            search.tap(); search.typeText("paneer"); beat(1.3)
        }
        if tap(app.buttons["dish-bowl-paneer-tikka"]) {
            beat(2.2)
            tap(app.buttons["favoriteToggle"]); beat(1.2)   // save to favorites
            tap(app.buttons["logDish"]); beat(1.4)
            back(app); beat(0.9)
        }
        tap(app.buttons["Clear text"]); tap(app.buttons["Cancel"]); beat(0.6)
    }

    private func savedAndToday(_ app: XCUIApplication) {
        tap(app.tabBars.buttons["Saved"]); beat(2.4)        // favorited dish
        tap(app.tabBars.buttons["Today"]); beat(2.8)        // ring + 7-day chart
    }

    private func aiMealLogging(_ app: XCUIApplication) {
        // Example 1 — trips the dairy allergy → AI returns an UNSAFE verdict.
        aiExample(app, meal: "2 rotis, dal and a mango lassi", showPhotoOption: true)
        // Example 2 — allergen-free → AI returns a SAFE verdict.
        aiExample(app, meal: "grilled vegetable skewers with steamed rice", showPhotoOption: false)
    }

    /// One full AI pass: open the sheet, (optionally linger on the Photo option),
    /// describe a meal, analyze it with Gemini (server-side), show the verdict,
    /// and log it. Reopening the sheet each time keeps the state clean.
    private func aiExample(_ app: XCUIApplication, meal: String, showPhotoOption: Bool) {
        tap(app.buttons["logWithAI"]); beat(showPhotoOption ? 2.2 : 1.2)   // sheet opens on Photo
        tap(app.segmentedControls.buttons["Describe"]); beat(1.0)

        var field = app.textViews["aiMealText"]
        if !field.waitForExistence(timeout: 3) { field = app.textFields["aiMealText"] }
        if field.waitForExistence(timeout: 3), field.isHittable {
            field.tap()
            field.typeText(meal)
        }
        beat(0.9)
        tap(app.buttons["aiAnalyze"])
        _ = app.buttons["aiLogIt"].waitForExistence(timeout: 30)  // live Gemini round-trip
        beat(3.2)                                           // show the AI result card + verdict
        tap(app.buttons["aiLogIt"]); beat(1.4)
        tap(app.buttons["Close"]); beat(1.3)
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
