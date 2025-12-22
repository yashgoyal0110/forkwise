import SwiftUI
// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload

/// The food artwork used on cards and the detail hero. A per-tmpCategory gradient
/// with a single glyph - designed and consistent, and works fully offline (no
/// network image loading, no placeholders flashing in).
struct DishThumbnail: View {
    let tmpCategory: String
    var size: CGFloat = 56
    var cornerRadius: CGFloat = Theme.Radius.tile

    var body: some View {
        let style = Theme.style(for: tmpCategory)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(style.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: style.symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}
