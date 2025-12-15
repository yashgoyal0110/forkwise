import Foundation

/// A dietary classification a dish can carry (e.g. "vegan", "gluten-free").
///
/// We model these as an `enum` with a raw `String` so they decode cleanly from
/// the menu JSON and are impossible to mistype elsewhere in the app.
/// `CaseIterable` lets the Profile screen list every option automatically.
enum DietTag: String, Codable, CaseIterable, Identifiable, Hashable {
    case vegetarian
    case vegan
    case glutenFree = "gluten_free"
    case highProtein = "high_protein"
    case lowCalorie = "low_calorie"

    var id: String { rawValue }

    /// Human-friendly label shown in the UI.
    var label: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan:      return "Vegan"
        case .glutenFree: return "Gluten-free"
        case .highProtein: return "High protein"
        case .lowCalorie: return "Low calorie"
        }
    }

    var systemImage: String {
        switch self {
        case .vegetarian: return "leaf"
        case .vegan:      return "leaf.circle"
        case .glutenFree: return "checkmark.seal"
        case .highProtein: return "bolt"
        case .lowCalorie: return "flame"
        }
    }
}
