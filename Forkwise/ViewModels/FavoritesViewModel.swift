import Foundation
import Combine
import CoreData

/// Owns the user's saved dishes, backed by the `CDFavorite` Core Data entity.
///
/// Favorites are stored by `dishID` only - the full dish is always resolved from
/// the live catalog, so a saved item automatically reflects price/calorie
/// updates instead of going stale. (A deliberate normalisation choice.)
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favoriteIDs: Set<String> = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        reload()
    }

    func reload() {
        let request = CDFavorite.fetchRequest()
        let rows = (try? context.fetch(request)) ?? []
        favoriteIDs = Set(rows.compactMap { $0.dishID })
    }

    func isFavorite(_ dish: Dish) -> Bool { favoriteIDs.contains(dish.id) }

    /// Adds or removes a dish from favorites and persists the change.
    func toggle(_ dish: Dish) {
        if favoriteIDs.contains(dish.id) {
            remove(dish.id)
        } else {
            let row = CDFavorite(context: context)
            row.dishID = dish.id
            row.savedAt = Date()
            favoriteIDs.insert(dish.id)
        }
        try? context.save()
    }

    private func remove(_ dishID: String) {
        let request = CDFavorite.fetchRequest()
        request.predicate = NSPredicate(format: "dishID == %@", dishID)
        for row in (try? context.fetch(request)) ?? [] { context.delete(row) }
        favoriteIDs.remove(dishID)
    }

    /// Resolves saved IDs to full dishes from the current catalog.
    func favorites(in catalog: [Dish]) -> [Dish] {
        catalog.filter { favoriteIDs.contains($0.id) }
    }
}
