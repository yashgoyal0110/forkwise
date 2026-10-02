import SwiftUI

/// The discovery screen: searchable, filterable feed of foods. Each card shows
/// whether the dish is safe for the current profile; category chips, a sort
/// menu, and a "safe only" toggle refine what's shown.
struct ExploreView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    @State private var filter = MenuFilter()

    private var results: [Dish] {
        filter.apply(to: catalog.dishes, for: profileVM.profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if catalog.isLoading {
                    loadingState
                } else if let error = catalog.errorMessage {
                    ContentUnavailableView("Couldn't load the menu", systemImage: "wifi.slash",
                                           description: Text(error)).padding(.top, 80)
                } else {
                    content
                }
            }
            .background(Color.canvas)
            .navigationTitle("Explore")
            .searchable(text: $filter.searchText, prompt: "Search dishes or categories")
            .navigationDestination(for: Dish.self) { DishDetailView(dish: $0) }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { sortMenu } }
            .safeAreaInset(edge: .top, spacing: 0) { filterBar }
        }
        .tint(.brand)
        .task { if catalog.dishes.isEmpty { await catalog.load() } }
    }

    // MARK: - Content

    private var content: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("\(results.count) \(results.count == 1 ? "dish" : "dishes")")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Label(catalog.source == .network ? "Live" : "Offline",
                      systemImage: catalog.source == .network ? "antenna.radiowaves.left.and.right" : "internaldrive")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.xs)

            if results.isEmpty {
                ContentUnavailableView.search.padding(.top, 60)
            } else {
                ForEach(results) { dish in
                    NavigationLink(value: dish) {
                        DishCard(dish: dish, profile: profileVM.profile,
                                 isFavorite: favoritesVM.isFavorite(dish))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dish-\(dish.id)")
                    .contextMenu { favoriteButton(dish) }
                }
            }
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Filter bar (category chips)

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    chip(title: "All", selected: filter.category == nil) { filter.category = nil }
                    ForEach(catalog.categories, id: \.self) { category in
                        chip(title: category, selected: filter.category == category) {
                            filter.category = category
                        }
                    }
                    Divider().frame(height: 22).padding(.horizontal, 2)
                    chip(title: "Safe only", systemImage: "shield.fill", selected: filter.onlySafe) {
                        filter.onlySafe.toggle()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
            }
            Divider()
        }
        .background(.bar)
    }

    private func chip(title: String, systemImage: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 5) {
                if let systemImage { Image(systemName: systemImage).font(.caption2) }
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(selected ? Color.brand : Color.primary.opacity(0.06), in: Capsule())
            .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $filter.sort) {
                ForEach(MenuFilter.SortOption.allCases) { Text($0.rawValue).tag($0) }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .foregroundStyle(Color.brand)
        }
    }

    private func favoriteButton(_ dish: Dish) -> some View {
        Button {
            Haptics.tap()
            favoritesVM.toggle(dish)
        } label: {
            Label(favoritesVM.isFavorite(dish) ? "Remove from Saved" : "Save",
                  systemImage: favoritesVM.isFavorite(dish) ? "heart.slash" : "heart")
        }
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView().controlSize(.large)
            Text("Loading menu…").font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.top, 120)
    }
}
