import Foundation

/// The user's eating preference. Kept separate from allergens because "I don't
/// eat meat" is a *choice*, while "nuts send me to hospital" is a *constraint* -
/// the UI treats them differently (soft filter vs. hard safety warning).
enum DietPreference: String, Codable, CaseIterable, Identifiable {
    case none
    case vegetarian
    case vegan

    var id: String { rawValue }

        var label: String {
                switch self {
                case .none:       return "No preference"
                case .vegetarian: return "Vegetarian"
                case .vegan:      return "Vegan"
                }
        }
}

/// An in-memory snapshot of everything the app needs to personalise the menu.
///
/// This is a plain value type. It's loaded from / saved to Core Data by
/// `ProfileViewModel`, but the rest of the app only ever deals with this clean
/// struct - the persistence details don't leak out.
struct DietProfile: Equatable {
        var name: String
        var allergies: Set<Allergen>
        var diet: DietPreference
        var dailyCalorieGoal: Int

        /// A sensible starting profile for a brand-new user.
        static let empty = DietProfile(
                name: "",
                allergies: [],
                diet: .none,
                dailyCalorieGoal: 2000
        )
}


// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload