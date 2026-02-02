import Foundation

/// Service for communicating with Google Gemini API
class AIService {
    private let settings = SettingsManager.shared

    private var apiKey: String {
        return settings.apiKey
    }

    private var model: String {
        return settings.model
    }

    private var apiURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

    init() {
        if !apiKey.isEmpty {
            print("✅ API key loaded from settings")
        } else {
            print("⚠️  API key not configured. Please open Settings.")
        }
    }

    /// Process text with Gemini AI
    func processText(_ text: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        print("🌐 Making request to: \(apiURL)")
        let request = try createRequest(for: text)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        print("📡 HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: \(errorMessage)")
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseResponse(data)
    }

    /// Create API request
    private func createRequest(for text: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Combine system prompt with user text
        let fullPrompt = settings.systemPrompt + "\n\(text)"

        let payload: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": fullPrompt
                        ]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request payload: \(jsonString.prefix(200))...")
        }

        request.httpBody = jsonData
        return request
    }

    /// Parse API response
    private func parseResponse(_ data: Data) throws -> String {
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response: \(responseString.prefix(300))...")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw AIServiceError.invalidResponse
        }

        guard let candidates = json["candidates"] as? [[String: Any]] else {
            print("❌ No candidates in response")
            throw AIServiceError.invalidResponse
        }

        guard let firstCandidate = candidates.first else {
            print("❌ Empty candidates array")
            throw AIServiceError.invalidResponse
        }

        guard let content = firstCandidate["content"] as? [String: Any] else {
            print("❌ No content in candidate")
            throw AIServiceError.invalidResponse
        }

        guard let parts = content["parts"] as? [[String: Any]] else {
            print("❌ No parts in content")
            throw AIServiceError.invalidResponse
        }

        guard let firstPart = parts.first else {
            print("❌ Empty parts array")
            throw AIServiceError.invalidResponse
        }

        guard let text = firstPart["text"] as? String else {
            print("❌ No text in part")
            throw AIServiceError.invalidResponse
        }

        return text
    }
}

/// AI Service errors
enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please open Settings and add your Gemini API key."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}
