import Foundation

/// A single item on the Forkwise menu.
///
/// This is a `Codable` value type that maps directly onto the menu JSON returned
/// by the API (and the bundled `menu.json` fallback). Keeping it a plain `struct`
/// - separate from any Core Data class - means the networking layer never has to
/// know about persistence, and vice-versa.
struct Dish: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String
    /// Price stored in paise/cents to avoid floating-point money bugs.
    let priceCents: Int
    let calories: Int
    let prepMinutes: Int
    let imageSystemName: String      // SF Symbol name used as artwork (no network images needed)
    let tags: [DietTag]
    let allergens: [Allergen]

    /// Price formatted for display, e.g. "₹149".
    var priceText: String {
        "₹\(priceCents / 100)"
    }

    /// Coding keys map Swift camelCase to the snake_case used in the JSON.
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, calories, tags, allergens
        case priceCents = "price_cents"
        case prepMinutes = "prep_minutes"
        case imageSystemName = "image_system_name"
    }
}

/// Top-level shape of the menu endpoint: `{ "dishes": [ ... ] }`.
struct MenuResponse: Codable {
    let dishes: [Dish]
}


// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload