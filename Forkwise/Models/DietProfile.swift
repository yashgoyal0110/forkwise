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

// TODO: second half of this comes with the next chunk of work
