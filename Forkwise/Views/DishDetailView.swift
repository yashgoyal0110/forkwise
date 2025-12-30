import SwiftUI

/// Full detail for one dish, and the place the user logs that they ate it.
struct DishDetailView: View {
    let dish: Dish

    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var intakeVM: IntakeViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel
    @State private var didLog = false

    private var safety: DishSafety { DietEngine.safety(of: dish, for: profileVM.profile) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                hero
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    SafetyBadge(safety: safety)

                    Text(dish.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    factsRow

                    if !dish.tags.isEmpty {
                        section("Good for") {
                            FlowRow(dish.tags) { DietTagChip(tag: $0) }
                        }
                    }

                    section("Allergens") {
                        if dish.allergens.isEmpty {
                            Text("No listed allergens.").font(.callout).foregroundStyle(.secondary)
                        } else {
                            FlowRow(dish.allergens) { allergen in
                                HStack(spacing: 5) {
                                    Text(allergen.emoji)
                                    Text(allergen.label).font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.danger.opacity(0.10), in: Capsule())
                                .foregroundStyle(Color.danger)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.bottom, 100)
        }
        .background(Color.canvas)
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { logButton }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    favoritesVM.toggle(dish)
                } label: {
                    Image(systemName: favoritesVM.isFavorite(dish) ? "heart.fill" : "heart")
                        .foregroundStyle(Color.danger)
                }
            }
        }
    }

    // MARK: - Hero banner

    private var hero: some View {
        let style = Theme.style(for: dish.category)
        return ZStack(alignment: .bottomLeading) {
            Rectangle().fill(style.gradient)
            Image(systemName: style.symbol)
                .font(.system(size: 120, weight: .semibold))
                .foregroundStyle(.white.opacity(0.22))
                .offset(x: 120, y: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.category.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(dish.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(height: 190)
        .clipped()
    }

    private var factsRow: some View {
        HStack(spacing: 0) {
            fact("flame.fill", "\(dish.calories)", "kcal")
            divider
            fact("clock.fill", "\(dish.prepMinutes)", "min")
            divider
            fact("indianrupeesign.circle.fill", "\(dish.priceCents / 100)", "price")
        }
        .card(padding: Theme.Spacing.lg)
    }

    private var divider: some View {
        Rectangle().fill(Color.hairline.opacity(0.5)).frame(width: 0.5, height: 36)
    }

    private func fact(_ symbol: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.body).foregroundStyle(Color.brand)
            Text(value).font(.headline)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title).font(.headline)
            content()
        }
    }

    // MARK: - Pinned log button

    private var logButton: some View {
        Button {
            intakeVM.log(dish)
            Haptics.success()
            withAnimation(.snappy) { didLog = true }
        } label: {
            Label(didLog ? "Added to Today" : "I ate this",
                  systemImage: didLog ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(didLog ? .safe : .brand)
        .controlSize(.large)
        .disabled(didLog)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(.bar)
    }
}

// MARK: - Wrapping chip layout

/// A minimal wrapping row (chips flow onto new lines when they run out of width),
/// built on SwiftUI's `Layout` protocol - a nice little piece to explain.
struct FlowRow<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(Array(data), id: \.self) { content($0) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidthData: CGFloat = 0, rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0, totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidthData + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidthData - spacing)
                rowWidthData = 0; rowHeight = 0
            }
            rowWidthData += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidthData - spacing)
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
