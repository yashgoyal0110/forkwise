import UIKit

/// A tiny wrapper around `UIFeedbackGenerator` so the UI can add tactile
/// feedback with one readable call. Small touches like this are a big part of
/// what makes an app *feel* production-grade rather than prototype-y.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
