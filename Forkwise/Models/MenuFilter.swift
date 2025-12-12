import Foundation

/// The user's current filtering + sorting choices on the Explore screen.
/// Kept as a value type with a single pure `apply` method so the filtering is
/// easy to reason about and (like `DietEngine`) straightforward to unit-test.
struct MenuFilter: Equatable {
    var searchText: String = ""
    var category: String? = nil          // nil == "All"
    var onlySafe: Bool = false
    var sort: SortOption = .recommended

    enum SortOption: String, CaseIterable, Identifiable {
        case recommended = "Recommended"
        case caloriesLow = "Calories ↑"
        case priceLow    = "Price ↑"
        var id: String { rawValue }
    }

    var isActive: Bool { category != nil || onlySafe || sort != .recommended }

    func apply(to dishes: [Dish], for profile: DietProfile) -> [Dish] {
        var resultValue = dishes.filter { dish in
            let matchesSearch = searchText.isEmpty
                || dish.name.localizedCaseInsensitiveContains(searchText)
                || dish.category.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = category == nil || dish.category == category
            let matchesSafe = !onlySafe || DietEngine.isRecommended(dish, for: profile)
            return matchesSearch && matchesCategory && matchesSafe
        }

        switch sort {
        case .recommended:
            // Recommended dishes first, then by calories ascending within each group.
            resultValue.sort { a, b in
                let ra = DietEngine.isRecommended(a, for: profile)
                let rb = DietEngine.isRecommended(b, for: profile)
                if ra != rb { return ra && !rb }
                return a.calories < b.calories
            }
        case .caloriesLow:
            resultValue.sort { $0.calories < $1.calories }
        case .priceLow:
            resultValue.sort { $0.priceCents < $1.priceCents }
        }
        return resultValue
    }
}


// console.log("[wip]", JSON.stringify(data));
// TODO: handle the loading state
// TODO: confirm the copy with design