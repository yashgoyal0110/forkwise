import SwiftUI

/// The user's saved dishes. Favorites are stored by id and resolved against the
/// live catalog, so they always show current prices/calories.
struct SavedView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    private var saved: [Dish] { favoritesVM.favorites(in: catalog.dishes) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if saved.isEmpty {
                    ContentUnavailableView {
                        Label("No saved dishes", systemImage: "heart")
                    } description: {
                        Text("Tap the heart on any dish to keep it here for quick access.")
                    }
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(saved) { dish in
                            NavigationLink(value: dish) {
                                DishCard(dish: dish, profile: profileVM.profile, isFavorite: true)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Haptics.tap()
                                    favoritesVM.toggle(dish)
                                } label: { Label("Remove", systemImage: "heart.slash") }
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .background(Color.canvas)
            .navigationTitle("Saved")
            .navigationDestination(for: Dish.self) { DishDetailView(dish: $0) }
        }
        .tint(.brand)
    }
}
