import XCTest
@testable import Forkwise

/// Unit tests for the allergen/diet logic - the business rules most likely to
/// have subtle bugs, and the easiest to get wrong silently. Because `DietEngine`
/// is pure, each test is three lines: build inputs, call, assert. This is the
/// kind of thing an interviewer loves to see.
final class DietEngineTests: XCTestCase {

    // A reusable dish builder so each test only specifies what it cares about.
    private func makeDish(tags: [DietTag] = [], allergens: [Allergen] = [], calories: Int = 400) -> Dish {
        Dish(
            id: UUID().uuidString, name: "Test Dish", description: "", category: "Test",
            priceCents: 10000, calories: calories, prepMinutes: 8,
            imageSystemName: "bowl.fill", tags: tags, allergens: allergens
        )
    }

    private func profile(allergies: Set<Allergen> = [], diet: DietPreference = .none, goal: Int = 2000) -> DietProfile {
        DietProfile(name: "Tester", allergies: allergies, diet: diet, dailyCalorieGoal: goal)
    }

    // MARK: - safety(of:for:)

    func testDishWithNoMatchingAllergensIsSafe() {
        let dish = makeDish(allergens: [.gluten])
        let me = profile(allergies: [.nuts, .dairy])
        XCTAssertEqual(DietEngine.safety(of: dish, for: me), .safe)
    }

    func testDishWithMatchingAllergenIsFlagged() {
        let dish = makeDish(allergens: [.nuts, .gluten])
        let me = profile(allergies: [.nuts])
        XCTAssertEqual(DietEngine.safety(of: dish, for: me), .contains([.nuts]))
    }

    func testMultipleMatchingAllergensAreAllReported() {
        let dish = makeDish(allergens: [.nuts, .dairy, .gluten])
        let me = profile(allergies: [.nuts, .dairy])
        // Result is sorted alphabetically for stable UI/tests.
        XCTAssertEqual(DietEngine.safety(of: dish, for: me), .contains([.dairy, .nuts]))
    }

    func testUserWithNoAllergiesSeesEverythingAsSafe() {
        let dish = makeDish(allergens: [.nuts, .shellfish, .dairy])
        XCTAssertTrue(DietEngine.safety(of: dish, for: profile()).isSafe)
    }

    // MARK: - matchesDiet(_:for:)

    func testVeganUserRejectsVegetarianOnlyDish() {
        let dish = makeDish(tags: [.vegetarian])          // veg but not vegan
        XCTAssertFalse(DietEngine.matchesDiet(dish, for: profile(diet: .vegan)))
    }

    func testVegetarianUserAcceptsVeganDish() {
        let dish = makeDish(tags: [.vegan])
        XCTAssertTrue(DietEngine.matchesDiet(dish, for: profile(diet: .vegetarian)))
    }

    func testNoPreferenceAcceptsAnything() {
        let dish = makeDish(tags: [])                     // no diet tags at all
        XCTAssertTrue(DietEngine.matchesDiet(dish, for: profile(diet: .none)))
    }

    // MARK: - isRecommended & suggestion

    func testRecommendedRequiresBothSafeAndOnDiet() {
        let unsafeButVegan = makeDish(tags: [.vegan], allergens: [.soy])
        let me = profile(allergies: [.soy], diet: .vegan)
        XCTAssertFalse(DietEngine.isRecommended(unsafeButVegan, for: me))
    }

    func testSuggestionPicksLowestCalorieFittingDish() {
        let dishes = [
            makeDish(tags: [.vegan], calories: 700),
            makeDish(tags: [.vegan], calories: 300),   // best fit
            makeDish(tags: [.vegan], calories: 900)
        ]
        let pick = DietEngine.suggestion(from: dishes, for: profile(diet: .vegan), remainingCalories: 500)
        XCTAssertEqual(pick?.calories, 300)
    }

    func testSuggestionReturnsNilWhenNothingFitsBudget() {
        let dishes = [makeDish(calories: 800), makeDish(calories: 650)]
        let pick = DietEngine.suggestion(from: dishes, for: profile(), remainingCalories: 500)
        XCTAssertNil(pick)
    }
}
