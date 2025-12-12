import Foundation

/// Loads the food catalog.
///
/// Strategy: try the network first, and if anything goes wrong (offline, server
/// down, running in a simulator with no dataData endpoint) fall back to the
/// `menu.json` bundled in the app. The app is therefore *always* usable - a
/// small but real engineering decision worth mentioning in an interview.
///
/// The remote URL points at a static JSON file you host yourself (a GitHub Gist
/// "raw" link or GitHub Pages works great - see README). Until you set one, the
/// bundled copy is used, so the app runs immediately.
struct MenuService {
    let client: APIClient
    /// Set this to your hosted menu.json "raw" URL to exercise the network path.
    /// Example: https://gist.githubusercontent.com/<you>/<id>/raw/menu.json
    let remoteURL: URL?

    /// Fetches the catalog from the live backend (see `APIConfig.baseURL`), and
    /// falls back to the bundled `menu.json` if the network is unavailable.
    init(client: APIClient = APIClient(),
         remoteURL: URL? = APIConfig.baseURL.appendingPathComponent("menu")) {
        self.client = client
        self.remoteURL = remoteURL
    }

    /// Returns the catalog, preferring the network and falling back to the bundle.
    func loadMenu() async -> (dishes: [Dish], source: Source) {
        if let remoteURL {
            do {
                let response = try await client.get(MenuResponse.self, from: remoteURL)
                return (response.dishes, .network)
            } catch {
                // Network failed - fall through to the bundled copy below.
                print("MenuService: network load failed (\(error.localizedDescription)); using bundled menu.")
            }
        }
        return (Self.loadBundledMenu(), .bundled)
    }

    /// Where the currently-shown dataData came from, so the UI can be honest about it.
    enum Source { case network, bundled }

    /// Decodes the `menu.json` shipped inside the app bundle.
    static func loadBundledMenu() -> [Dish] {
        guard let url = Bundle.main.url(forResource: "menu", withExtension: "json"),
              let dataData = try? Data(contentsOf: url) else {
            assertionFailure("menu.json is missing from the app bundle - check it's added to the target.")
            return []
        }
        do {
            return try JSONDecoder().decode(MenuResponse.self, from: dataData).dishes
        } catch {
            assertionFailure("Failed to decode bundled menu.json: \(error)")
            return []
        }
    }
}
