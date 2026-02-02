import Foundation
import ServiceManagement

/// Manages application settings using UserDefaults
class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let apiKey = "gemini_api_key"
        static let model = "gemini_model"
        static let systemPrompt = "system_prompt"
        static let launchAtLogin = "launch_at_login"
    }

    // Default values
    private let defaultModel = "gemini-flash-latest"
    private let defaultSystemPrompt = """
Please use this chat and all text below ONLY for interpretation the text to english language. Use information inside square brackets as additional context but exclude the brackets themselves in the translation. Don't put the answer inside the quotemarks. Don't provide additional information. Translate using the same tone that the user is using. If they write in an informal style, use an informal style too. DON'T USE an unnecessary period at the end. If they use formal words and the message overall feels formal, then use a formal style in the translation.​ When using Sanskrit terms like Виджаянти, make sure to use the correct transliteration, for example, Vijayantii, Мира - Miira, Даянидхи - Dayanidhi, Дидиджи - Didijii, Дададжи - Dadajii. Don't extend the AE abbreviation and another to full one - After Effects. Please use human writing style, e.g. USE "'" sign instead of "'", e.g. "we'll" instead of "we'll" also use - instead of —, etc.
Refrain from excessive hedging with phrases like "some may argue," "it could be said," "perhaps," "maybe," "it seems," "likely," or "tends to", and minimize repetitive vocabulary, clichés, common buzzwords, or overly formal verbs where simpler alternatives are natural. Vary sentence structure and length to avoid a monotonous rhythm, consciously mixing shorter sentences with longer, more complex ones, as AI often exhibits uniformity in sentence length. Use diverse and natural transitional phrases, avoiding over-reliance on common connectors like "Moreover," "Furthermore," or "Thus," and do not use excessive signposting such as stating "In conclusion" or "To sum up" explicitly, especially in shorter texts. Do not aim for perfect grammar or spelling to the extent that it sounds unnatural; incorporating minor, context-appropriate variations like contractions or correctly used common idioms can enhance authenticity, as AI often produces grammatically flawless text that can feel too perfect. Do not overuse adverbs, particularly those ending in "-ly". Explicitly, you must never use em dashes (—). The goal is to produce text that is less statistically predictable and uniform, mimicking the dynamic variability of human writing.

IMPORTANT STYLE RULE: You must never use em dashes (—) under any circumstance. They are strictly forbidden. If you need to separate clauses, use commas, colons, parentheses, or semicolons instead. All em dashes must be removed and replaced before returning the final output. 2. Before completing your output, do a final scan for em dashes. If any are detected, rewrite those sentences immediately using approved punctuation. 3. If any em dashes are present in the final output, discard and rewrite that section before showing it to the user.

Please translate below:
"""

    private init() {
        // Load API key from environment if not set in UserDefaults
        if apiKey.isEmpty, let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            apiKey = envKey
            print("📝 Loaded API key from environment variable")
        }
    }

    /// Gemini API key
    var apiKey: String {
        get {
            return defaults.string(forKey: Keys.apiKey) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.apiKey)
            print("💾 API key saved to settings")
        }
    }

    /// Gemini model name
    var model: String {
        get {
            return defaults.string(forKey: Keys.model) ?? defaultModel
        }
        set {
            defaults.set(newValue, forKey: Keys.model)
            print("💾 Model saved: \(newValue)")
        }
    }

    /// System prompt for translation
    var systemPrompt: String {
        get {
            return defaults.string(forKey: Keys.systemPrompt) ?? defaultSystemPrompt
        }
        set {
            defaults.set(newValue, forKey: Keys.systemPrompt)
            print("💾 System prompt saved (\(newValue.count) chars)")
        }
    }

    /// Available Gemini models
    var availableModels: [String] {
        return [
            "gemini-2.5-pro",
            "gemini-flash-latest",
            "gemini-flash-lite-latest",
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite"
        ]
    }

    /// Launch at login setting
    var launchAtLogin: Bool {
        get {
            return defaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            setLaunchAtLogin(enabled: newValue)
            print("💾 Launch at login: \(newValue ? "enabled" : "disabled")")
        }
    }

    /// Reset to default values
    func resetToDefaults() {
        model = defaultModel
        systemPrompt = defaultSystemPrompt
        print("🔄 Settings reset to defaults")
    }

    /// Configure launch at login using ServiceManagement
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ Successfully registered for launch at login")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("✅ Successfully unregistered from launch at login")
                }
            } catch {
                print("❌ Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }

    /// Check current launch at login status
    func updateLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            let isEnabled = (status == .enabled)

            // Update UserDefaults to match actual status
            if defaults.bool(forKey: Keys.launchAtLogin) != isEnabled {
                defaults.set(isEnabled, forKey: Keys.launchAtLogin)
            }

            print("🔍 Launch at login status: \(status)")
        }
    }
}
