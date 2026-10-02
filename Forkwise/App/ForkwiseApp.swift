import SwiftUI

/// App entry point. Builds the Core Data stack once, creates the long-lived
/// stores/view models, injects them into the SwiftUI environment, and gates the
/// first launch behind onboarding.
@main
struct ForkwiseApp: App {
    private let persistence = PersistenceController.shared

    @StateObject private var catalog = CatalogStore()
    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var intakeVM: IntakeViewModel
    @StateObject private var favoritesVM: FavoritesViewModel

    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 13

    init() {
        let context = persistence.container.viewContext
        // For CI UI-test recordings only (no-op otherwise): seed a demo profile
        // + meal history and skip onboarding, before the view models load.
        DemoMode.applyIfNeeded(context: context)
        _profileVM = StateObject(wrappedValue: ProfileViewModel(context: context))
        _intakeVM = StateObject(wrappedValue: IntakeViewModel(context: context))
        _favoritesVM = StateObject(wrappedValue: FavoritesViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootTabView()
                } else {
                    OnboardingView { withAnimation { hasOnboarded = true } }
                }
            }
            .environmentObject(catalog)
            .environmentObject(profileVM)
            .environmentObject(intakeVM)
            .environmentObject(favoritesVM)
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .task { await bootstrap() }
        }
    }

    /// Runs once per launch: load the catalog, then set up notifications.
    @MainActor
    private func bootstrap() async {
        if catalog.dishes.isEmpty { await catalog.load() }

        // Never request notification permission during an automated recording —
        // the system dialog would cover the app and block the walkthrough.
        guard !DemoMode.isActive, reminderEnabled else {
            NotificationManager.shared.cancelMealReminder()
            return
        }
        await NotificationManager.shared.requestAuthorization()
        let remaining = max(profileVM.profile.dailyCalorieGoal - intakeVM.caloriesToday, 0)
        let pick = DietEngine.suggestion(from: catalog.dishes, for: profileVM.profile, remainingCalories: remaining)
        NotificationManager.shared.scheduleMealReminder(hour: reminderHour, suggestion: pick)
    }
}
