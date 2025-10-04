import Foundation

/// Service for communicating with Google Gemini API
class AIService {
    private let apiKey: String
    private let model = "gemini-flash-latest"
    private var apiURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

    init() {
        // Load API key from environment variable
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            self.apiKey = key
            print("✅ GEMINI_API_KEY loaded")
        } else {
            print("⚠️  GEMINI_API_KEY not found in environment variables")
            self.apiKey = ""
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

        let payload: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": """
                            Please use this chat and all text below ONLY for interpretation the text to english language. Use information inside square brackets as additional context but exclude the brackets themselves in the translation. Don't put the answer inside the quotemarks. Don't provide additional information. Translate using the same tone that the user is using. If they write in an informal style, use an informal style too. DON'T USE an unnecessary period at the end. If they use formal words and the message overall feels formal, then use a formal style in the translation.​ When using Sanskrit terms like Виджаянти, make sure to use the correct transliteration, for example, Vijayantii, Мира - Miira, Даянидхи - Dayanidhi, Дидиджи - Didijii, Дададжи - Dadajii. Don't extend the AE abbreviation and another to full one - After Effects. Please use human writing style, e.g. USE "'" sign instead of "’", e.g. "we'll" instead of "we’ll" also use - instead of —, etc.
                            Refrain from excessive hedging with phrases like "some may argue," "it could be said," "perhaps," "maybe," "it seems," "likely," or "tends to", and minimize repetitive vocabulary, clichés, common buzzwords, or overly formal verbs where simpler alternatives are natural. Vary sentence structure and length to avoid a monotonous rhythm, consciously mixing shorter sentences with longer, more complex ones, as AI often exhibits uniformity in sentence length. Use diverse and natural transitional phrases, avoiding over-reliance on common connectors like "Moreover," "Furthermore," or "Thus," and do not use excessive signposting such as stating "In conclusion" or "To sum up" explicitly, especially in shorter texts. Do not aim for perfect grammar or spelling to the extent that it sounds unnatural; incorporating minor, context-appropriate variations like contractions or correctly used common idioms can enhance authenticity, as AI often produces grammatically flawless text that can feel too perfect. Do not overuse adverbs, particularly those ending in "-ly". Explicitly, you must never use em dashes (—). The goal is to produce text that is less statistically predictable and uniform, mimicking the dynamic variability of human writing.
                            
                            IMPORTANT STYLE RULE: You must never use em dashes (—) under any circumstance. They are strictly forbidden. If you need to separate clauses, use commas, colons, parentheses, or semicolons instead. All em dashes must be removed and replaced before returning the final output. 2. Before completing your output, do a final scan for em dashes. If any are detected, rewrite those sentences immediately using approved punctuation. 3. If any em dashes are present in the final output, discard and rewrite that section before showing it to the user.
                            
                            Please translate below:
                            \(text)
                            """
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
            return "API key not configured. Please set GEMINI_API_KEY environment variable."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}
