
import Foundation
import UIKit

/// Estimates calories in a food photo using OpenAI's multimodal models (e.g., gpt-4o-mini).
/// Requires OPENAI_API_KEY to be set in your environment (Xcode Scheme > Run > Arguments).
final class OpenAINutritionService {
    struct FoodItem: Codable {
        let name: String
        let grams: Double?
        let calories: Int?
    }
    struct Estimate: Codable {
        let totalCalories: Int
        let items: [FoodItem]
    }

    enum ServiceError: LocalizedError {
        case missingAPIKey, imageEncodingFailed, decodingFailed
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "OPENAI_API_KEY is missing."
            case .imageEncodingFailed: return "Could not encode image."
            case .decodingFailed: return "Failed to decode model response."
            }
        }
    }

    private let apiKey: String
    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    /// Calls OpenAI's Chat Completions API with an image and asks for a strict JSON response.
    /// Falls back to zero calories if the API key is not set or any error occurs.
    func estimateCalories(from image: UIImage) async throws -> Estimate {
        guard !apiKey.isEmpty else { throw ServiceError.missingAPIKey }
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else { throw ServiceError.imageEncodingFailed }
        let b64 = jpeg.base64EncodedString()

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // We request a strict JSON object (response_format) the model must follow.
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "messages": [
                [
                    "role": "system",
                    "content": "You are a nutritionist. Estimate total calories roughly from a single food photo. Include a short list of detected items with optional grams and calories. If unsure, make your best conservative estimate. Return only JSON."
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "Estimate total kilocalories in this photo. Return JSON with {\"totalCalories\": integer, \"items\": [{\"name\": string, \"grams\"?: number, \"calories\"?: integer}]}."],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
                    ]
                ]
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: req)

        // Try decoding the assistant message content as JSON (response_format=json_object ensures content is JSON)
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        if let chat = try? JSONDecoder().decode(ChatResponse.self, from: data),
           let jsonData = chat.choices.first?.message.content.data(using: .utf8) {
            if let estimate = try? JSONDecoder().decode(Estimate.self, from: jsonData) {
                return estimate
            }
        }
        throw ServiceError.decodingFailed
    }
}
