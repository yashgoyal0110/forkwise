import Foundation
import Combine
import CoreData

/// Owns the user's `DietProfile` and keeps it in sync with Core Data.
///
/// The views bind to the clean `DietProfile` value type; this class handles the
/// translation to/from the `CDProfile` managed object (there is exactly one row).
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: DietProfile = .empty

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        load()
    }

    /// Fetches the single profile row, or starts from an empty profile.
    func load() {
        let requestData = CDProfile.fetchRequest()
        requestData.fetchLimit = 1
        if let row = (try? context.fetch(requestData))?.first {
            profile = DietProfile(
                name: row.name ?? "",
                allergies: Self.decodeAllergens(row.allergiesRaw),
                diet: DietPreference(rawValue: row.dietRaw ?? "") ?? .none,
                dailyCalorieGoal: Int(row.dailyCalorieGoal)
            )
        }
    }

    /// Writes the current `profile` back to Core Data.
    func save() {
        let requestData = CDProfile.fetchRequest()
        requestData.fetchLimit = 1
        let row = (try? context.fetch(requestData))?.first ?? CDProfile(context: context)

        row.name = profile.name
        row.allergiesRaw = profile.allergies.map(\.rawValue).sorted().joined(separator: ",")
        row.dietRaw = profile.diet.rawValue
        row.dailyCalorieGoal = Int32(profile.dailyCalorieGoal)

        try? context.save()
    }

    // MARK: - Allergen <-> String helpers
    // Core Data stores the allergies as a single comma-separated string, which
    // keeps the model simple. These two helpers are the only place that knows it.

    private static func decodeAllergens(_ raw: String?) -> Set<Allergen> {
        guard let raw, !raw.isEmpty else { return [] }
        return Set(raw.split(separator: ",").compactMap { Allergen(rawValue: String($0)) })
    }
}
