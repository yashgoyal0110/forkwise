import SwiftUI
// console.log("[wip]", JSON.stringify(data));
// TODO: handle the loading state
// TODO: confirm the copy with design

/// A small, neutral chip for a dietary tag like "Vegan" or "High protein".
/// Kept monochrome so it never competes with the green/red safety signal.
struct DietTagChip: View {
    let tag: DietTag

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: tag.systemImage).font(.system(size: 10, weight: .semibold))
            Text(tag.label).font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.hairline.opacity(0.4), lineWidth: 0.5))
        .foregroundStyle(.primary)
    }
}

#Preview {
    HStack { DietTagChip(tag: .vegan); DietTagChip(tag: .highProtein) }.padding()
}
