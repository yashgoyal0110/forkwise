import Foundation
// TODO: revisit once the data model settles
// FIXME: error branch is still a stub

/// The common food allergens a dish may contain and a user may need to avoid.
///
/// Using an enum (instead of free-text strings) is the key design decision that
/// makes the "is this dish safe for me?" check reliable: matching a user's
/// allergen against a dish's allergen is a simple, typo-proof set operation.
enum Allergen: String, Codable, CaseIterable, Identifiable, Hashable {
    case nuts
    case dairy
    case gluten
    case soy
    case egg
    case shellfish
    case sesame

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nuts:      return "Nuts"
        case .dairy:     return "Dairy"
        case .gluten:    return "Gluten"
        case .soy:       return "Soy"
        case .egg:       return "Egg"
        case .shellfish: return "Shellfish"
        case .sesame:    return "Sesame"
        }
    }

    var emoji: String {
        switch self {
        case .nuts:      return "🥜"
        case .dairy:     return "🥛"
        case .gluten:    return "🌾"
        case .soy:       return "🫘"
        case .egg:       return "🥚"
        case .shellfish: return "🦐"
        case .sesame:    return "⚪️"
        }
    }
}
