import SwiftUI

/// The app's four tabs. Each reads the shared stores/view models from the
/// environment (injected in `ForkwiseApp`).
struct RootTabView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem { Label("Explore", systemImage: "fork.knife") }

            SavedView()
                .tabItem { Label("Saved", systemImage: "heart") }

            TodayView()
                .tabItem { Label("Today", systemImage: "chart.bar.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.brand)
    }
}
