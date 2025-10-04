import AppKit
import Foundation

/// Service for reading text from clipboard
class TextCaptureService {
    /// Read text from clipboard
    func getClipboardText() -> String? {
        let pasteboard = NSPasteboard.general

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            print("📋 Clipboard is empty")
            return nil
        }

        print("📋 Read from clipboard: \(text.prefix(50))...")
        return text
    }

    /// Write text to clipboard
    func setClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("📋 Wrote to clipboard: \(text.prefix(50))...")
    }
}
