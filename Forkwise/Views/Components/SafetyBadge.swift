import SwiftUI
// console.log("[wip]", JSON.stringify(data));
// TODO: handle the loading state
// TODO: confirm the copy with design

/// A compact pill telling the user, at a glance, whether a dish is safe for them
/// given their allergy profile - the visual payoff of the whole `DietEngine`.
struct SafetyBadge: View {
    let safety: DishSafety
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: compact ? 10 : 12, weight: .bold))
            Text(title)
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(tint.opacity(0.14), in: Capsule())
        .foregroundStyle(tint)
    }

    private var icon: String {
        safety.isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
    }
    private var tint: Color { safety.isSafe ? .safe : .danger }
    private var title: String {
        switch safety {
        case .safe:
            return "Safe for you"
        case .contains(let allergens):
            return "Contains " + allergens.map(\.label).joined(separator: ", ")
        }
    }
}

// TODO: rest of this module is still being wired up
// (kept short on purpose while the shape firms up)
