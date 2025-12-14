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

// TODO: rest of this module is still being wired up
// (kept short on purpose while the shape firms up)
