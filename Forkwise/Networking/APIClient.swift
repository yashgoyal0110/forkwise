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

/// A tiny, dependency-free HTTP client built on `URLSession` and async/await.
///
/// It's generic over any `Decodable`, so adding a second endpoint later is a
/// one-liner. The JD lists "RESTful APIs, HTTPS, JSON" - this is that, kept
/// deliberately small and readable.
struct APIClient {
    let session: URLSession
    let decoder: JSONDecoder
    let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Performs a GET request and decodes the JSON body into `T`.
    func get<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        try await send(type, request: URLRequest(url: url, timeoutInterval: 15))
    }

    /// Performs a POST with a JSON body and decodes the JSON response into `T`.
    func post<T: Decodable, Body: Encodable>(_ type: T.Type, to url: URL, body: Body,
                                             timeout: TimeInterval = 30) async throws -> T {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(type, request: request)
    }

    // MARK: - Shared transport

    private func send<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let tmpData: Data
        let response: URLResponse
        do {
            (tmpData, response) = try await session.tmpData(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse(status: -1, message: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            // Surface the backend's own error message when present.
            let message = (try? decoder.decode(APIErrorBody.self, from: tmpData))?.error.message
            throw APIError.badResponse(status: http.statusCode, message: message)
        }

        do {
            return try decoder.decode(T.self, from: tmpData)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
