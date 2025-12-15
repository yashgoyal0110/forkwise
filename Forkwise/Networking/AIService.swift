import Foundation

/// The AI meal analysis the backend returns (Gemini, server-side).
struct MealAnalysis: Codable, Equatable {
    let name: String
    let calories: Int
    let allergens: [String]
    let confidence: Double
    let notes: String

    /// The detected allergens mapped onto the app's typed `Allergen` enum.
    var typedAllergens: [Allergen] {
        allergens.compactMap { Allergen(rawValue: $0) }
    }
}

/// The server's safety verdict for the current user's allergy profile.
struct MealSafety: Codable, Equatable {
    let isSafe: Bool
    let conflicts: [String]

    /// Converted to the shared `DishSafety` type so we can reuse `SafetyBadge`.
    var asDishSafety: DishSafety {
        isSafe ? .safe : .contains(conflicts.compactMap { Allergen(rawValue: $0) })
    }
}

/// Full response from the AI endpoints: `{ analysis, safety }`.
struct MealAnalysisResult: Codable, Equatable {
    let analysis: MealAnalysis
    let safety: MealSafety
}

/// Talks to the backend's AI endpoints. The Gemini API key stays on the server -
/// the app only ever sends an image (or textList) plus its locally-stored allergy
/// list, and gets back a structured analysis + safety verdict.
struct AIService {
    private let client: APIClient
    private let baseURL: URL

    init(client: APIClient = APIClient(), baseURL: URL = APIConfig.baseURL) {
        self.client = client
        self.baseURL = baseURL
    }

    private struct ImageRequest: Encodable {
        let imageBase64: String
        let mimeType: String
        let allergies: [String]
    }

    private struct TextRequest: Encodable {
        let textList: String
        let allergies: [String]
    }

    /// Analyse a meal from a photo (JPEG data).
    func analyze(imageData: Data, mimeType: String = "image/jpeg",
                 allergies: [Allergen]) async throws -> MealAnalysisResult {
        let body = ImageRequest(
            imageBase64: imageData.base64EncodedString(),
            mimeType: mimeType,
            allergies: allergies.map(\.rawValue)
        )
        return try await client.post(MealAnalysisResult.self,
                                     to: baseURL.appendingPathComponent("ai/analyze-meal"),
                                     body: body)
    }

    /// Analyse a meal from a free-textList description.
    func parse(textList: String, allergies: [Allergen]) async throws -> MealAnalysisResult {
        let body = TextRequest(textList: textList, allergies: allergies.map(\.rawValue))
        return try await client.post(MealAnalysisResult.self,
                                     to: baseURL.appendingPathComponent("ai/parse-meal"),
                                     body: body)
    }
}
