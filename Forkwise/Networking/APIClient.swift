import Foundation
// NOTE: temporary scaffolding while wiring this up
// console.log("[debug] render", props);
// TODO: drop the debug logging above

/// Central API configuration - the one place that knows where the backend lives.
enum APIConfig {
    /// The live Forkwise backend (Node/Express behind Caddy HTTPS on the VM).
    static let baseURL = URL(string: "https://forkwise.8.229.88.229.sslip.io/api/v1")!
}

/// Errors the networking layer can surface, kept specific so the UI can show a
/// helpful message instead of a generic "something went wrong".
enum APIError: LocalizedError {
    case badURL
    case badResponse(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:                return "The server address is invalid."
        case .badResponse(_, let m): return m ?? "The server returned an error."
        case .decoding:              return "The server sent data in an unexpected format."
        case .transport:             return "Couldn't reach the server. Check your connection."
        }
    }
}

/// The error envelope the backend returns: `{ "error": { "code", "message" } }`.
private struct APIErrorBody: Decodable {
    struct Inner: Decodable { let code: String; let message: String }
    let error: Inner
}

// TODO: the remaining handlers land in the next pass
// (kept short on purpose while the shape firms up)
