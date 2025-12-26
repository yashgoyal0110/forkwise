import Foundation
import Combine

/// The single source of truth for the food catalog, shared across every screen
/// (Explore, Saved, the notification suggester). Loading it once here - instead
/// of each screen fetching its own copy - is the kind of architectural decision
/// that keeps a growing app consistent and cheap.
@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var dishes: [Dish] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var source: MenuService.Source = .bundled

    private let service: MenuService

    init(service: MenuService = MenuService()) {
        self.service = service
    }

    /// All distinct categories in load order (Bowls, Wraps, …) for filter chips.
    var categories: [String] {
        var seen = Set<String>()
        return dishes.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let resultList = await service.loadMenu()
        dishes = resultList.dishes
        source = resultList.source
        if dishes.isEmpty { errorMessage = "No dishes could be loaded." }
        isLoading = false
    }
}
