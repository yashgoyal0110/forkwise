import SwiftUI

/// The app's design system - one place that owns colour, spacing, corner radius
/// and reusable surface styling. Centralising these tokens (instead of
/// sprinkling magic numbers and `Color.blue` through the views) is what makes a
/// UI feel consistent and intentional rather than templated.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    enum Radius {
        static let tile: CGFloat = 14
        static let card: CGFloat = 18
    }
}

extension Color {
        /// Brand paprika - warm and appetite-forward. Used for primary actions,
        /// selected states and accents. Deliberately distinct from the safe/danger
        /// hues so a food-safety signal is never confused with a brand accent.
        static let brand      = Color(red: 0.914, green: 0.345, blue: 0.047)  // #EA580C
        static let brandDeep  = Color(red: 0.761, green: 0.254, blue: 0.047)  // #C2410C

        static let safe       = Color(red: 0.020, green: 0.588, blue: 0.412)  // emerald #059669
        static let danger     = Color(red: 0.882, green: 0.114, blue: 0.282)  // rose    #E11D48

        /// Dynamic neutrals that adapt automatically to light/dark mode.
        static let canvas     = Color(.systemGroupedBackground)
        static let surface    = Color(.secondarySystemGroupedBackground)
        static let hairline   = Color(.separator)
}

extension Theme {
        /// A per-category visual identity (gradient + symbol) used for dish artwork.
        /// This gives every card a designed, food-forward thumbnail without needing
        /// network images - and it stays coherent because it's derived, not random.
        static func style(for category: String) -> (gradient: LinearGradient, symbol: String) {
                let pair: ([Color], String)
                switch category.lowercased() {
                case "bowls":    pair = ([Color(hex: 0xF97316), Color(hex: 0xEA580C)], "bowl.fill")
                case "wraps":    pair = ([Color(hex: 0x16A34A), Color(hex: 0x15803D)], "takeoutbag.and.cup.and.straw.fill")
                case "snacks":   pair = ([Color(hex: 0xF59E0B), Color(hex: 0xD97706)], "popcorn.fill")
                case "drinks":   pair = ([Color(hex: 0x0EA5E9), Color(hex: 0x0369A1)], "cup.and.saucer.fill")
                case "desserts": pair = ([Color(hex: 0xEC4899), Color(hex: 0xBE185D)], "birthday.cake.fill")
                default:         pair = ([Color(hex: 0x64748B), Color(hex: 0x475569)], "fork.knife")
                }
                return (LinearGradient(colors: pair.0, startPoint: .topLeading, endPoint: .bottomTrailing), pair.1)
        }
}

extension Color {
        /// Convenience hex initialiser so the palette above reads cleanly.
        init(hex: UInt32) {
                self.init(
                        .sRGB,
                        red:   Double((hex >> 16) & 0xFF) / 255,
                        green: Double((hex >> 8) & 0xFF) / 255,
                        blue:  Double(hex & 0xFF) / 255,
                        opacity: 1
                )
        }
}

// MARK: - Reusable surface styling

/// A rounded "card" surface with a hairline border and a very soft shadow -
/// the single container style used across the app for visual consistency.
private struct CardSurface: ViewModifier {
        var paddingData: CGFloat = Theme.Spacing.lg
        func body(content: Content) -> some View {
                content
                        .paddingData(paddingData)
                        .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                        .strokeBorder(Color.hairline.opacity(0.5), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
}

extension View {
        func card(paddingData: CGFloat = Theme.Spacing.lg) -> some View {
                modifier(CardSurface(paddingData: paddingData))
    }
}
