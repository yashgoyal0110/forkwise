import SwiftUI

/// A single dish in the Explore feed: artwork, name, a compact meta row, the
/// safety badge, and a price - laid out as a self-contained card.
struct DishCard: View {
    let dish: Dish
    let profile: DietProfile
    var isFavorite: Bool = false

    private var safety: DishSafety { DietEngine.safety(of: dish, for: profile) }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            DishThumbnail(category: dish.category, size: 60)
                .overlay(alignment: .topLeading) {
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.danger, in: Circle())
                            .offset(x: -6, y: -6)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(dish.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.sm)
                    Text(dish.priceText)
                        .font(.subheadline.weight(.bold))
                }

                HStack(spacing: Theme.Spacing.md) {
                    Label("\(dish.calories) kcal", systemImage: "flame.fill")
                    Label("\(dish.prepMinutes) min", systemImage: "clock.fill")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                SafetyBadge(safety: safety, compact: true).padding(.top, 2)
            }
        }
        .card(padding: Theme.Spacing.md)
    }
}

#Preview {
    VStack {
        DishCard(
            dish: MenuService.loadBundledMenu().first ?? Dish(
                id: "x", name: "Paneer Tikka Bowl", description: "", category: "Bowls",
                priceCents: 24900, calories: 620, prepMinutes: 9,
                imageSystemName: "bowl.fill", tags: [.vegetarian], allergens: [.dairy]
            ),
            profile: DietProfile(name: "Me", allergies: [.dairy], diet: .none, dailyCalorieGoal: 2000),
            isFavorite: true
        )
    }
    .padding()
    .background(Color.canvas)
}
