import Foundation

/// Why a dish might not suit the current user.
enum DishSafety: Equatable {
    /// Safe to eat given the user's allergies.
    case safe
    /// Contains one or more allergens the user listed. The associated value is
    /// the *intersection* - exactly which allergens triggered the warning.
    case contains([Allergen])

    var isSafe: Bool { self == .safe }
}

/// The personalisation engine. Every function here is **pure**: same inputs →
/// same output, no side effects, no I/O. That is deliberate - it makes the
/// trickiest business rules in the app trivial to unit-test (see
/// `AllergenMatcherTests`), which is what separates a real project from a demo.
enum DietEngine {

    /// Does this dish contain anything the user is allergic to?
    static func safety(of dish: Dish, for profile: DietProfile) -> DishSafety {
        let offending = profile.allergies.intersection(Set(dish.allergens))
        guard offending.isEmpty else {
            // Sort so the warning order is stable (nicer UI + deterministic tests).
            return .contains(offending.sorted { $0.rawValue < $1.rawValue })
        }
        return .safe
    }

    /// Does this dish respect the user's veg/vegan preference?
    static func matchesDiet(_ dish: Dish, for profile: DietProfile) -> Bool {
        switch profile.diet {
        case .none:
            return true
        case .vegetarian:
            return dish.tags.contains(.vegetarian) || dish.tags.contains(.vegan)
        case .vegan:
            return dish.tags.contains(.vegan)
        }
    }

    /// The combined gate used by the "hide unsafe dishes" toggle: a dish is
    /// shown only if it's both allergen-safe *and* diet-appropriate.
    static func isRecommended(_ dish: Dish, for profile: DietProfile) -> Bool {
        safety(of: dish, for: profile).isSafe && matchesDiet(dish, for: profile)
    }

    /// Picks a dish that fits the user's diet and stays within their remaining
    /// calorie budget for the day - used to power the meal-reminder notification.
    static func suggestion(from dishes: [Dish],
                           for profile: DietProfile,
                           remainingCalories: Int) -> Dish? {
        dishes
            .filter { isRecommended($0, for: profile) && $0.calories <= max(remainingCalories, 0) }
            .min { $0.calories < $1.calories }   // leave the most headroom
    }
}
