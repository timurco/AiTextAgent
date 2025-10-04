import AppKit
import Foundation

/// Controls the menu bar icon and menu
class MenuBarController {
    private var statusItem: NSStatusItem?
    private let hotKeyManager = HotKeyManager()
    private let textCaptureService = TextCaptureService()
    private let aiService = AIService()

    init() {
        setupMenuBar()
        setupHotKey()
        setStatus(.idle)
    }

    /// Set up menu bar icon and menu
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "AI Text Agent")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "AI Text Agent", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        let usageItem1 = NSMenuItem(title: "1. Copy text (⌘C)", action: nil, keyEquivalent: "")
        usageItem1.isEnabled = false
        menu.addItem(usageItem1)

        let usageItem2 = NSMenuItem(title: "2. Press ⌘⇧Space", action: nil, keyEquivalent: "")
        usageItem2.isEnabled = false
        menu.addItem(usageItem2)

        let usageItem3 = NSMenuItem(title: "3. AI result → clipboard", action: nil, keyEquivalent: "")
        usageItem3.isEnabled = false
        menu.addItem(usageItem3)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    /// Status states
    enum Status {
        case idle
        case processing
        case done
        case error(String)
    }

    /// Update menu bar status
    private func setStatus(_ status: Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem?.button else { return }

            switch status {
            case .idle:
                button.title = ""
                button.toolTip = "AI Text Agent - Ready\nPress ⌘⇧Space to translate clipboard"

            case .processing:
                button.title = "⏳"
                button.toolTip = "Processing...\nTranslating your text with AI"

            case .done:
                button.title = "✅"
                button.toolTip = "Done!\nTranslation copied to clipboard"
                // Auto-clear after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.setStatus(.idle)
                }

            case .error(let message):
                button.title = "❌"
                button.toolTip = "Error: \(message)\nCheck logs for details"
                // Auto-clear after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.setStatus(.idle)
                }
            }
        }
    }

    /// Set up global hotkey (Cmd+Shift+Space)
    private func setupHotKey() {
        hotKeyManager.registerHotKey { [weak self] in
            self?.handleHotKeyPressed()
        }
    }

    /// Handle hotkey press - read clipboard and send to AI
    private func handleHotKeyPressed() {
        print("🔥 Hotkey pressed!")

        // Read clipboard
        guard let clipboardText = textCaptureService.getClipboardText() else {
            print("⚠️  Clipboard is empty")
            setStatus(.error("Empty clipboard"))
            return
        }

        print("📝 Processing clipboard text: \(clipboardText.prefix(50))...")

        // Show processing status
        setStatus(.processing)

        // Send to AI
        Task {
            await processWithAI(text: clipboardText)
        }
    }

    /// Process text with AI service
    private func processWithAI(text: String) async {
        print("🤖 Sending to AI: \(text.prefix(50))...")
        do {
            let response = try await aiService.processText(text)
            print("✅ AI Response received: \(response.prefix(50))...")

            // Copy response to clipboard
            textCaptureService.setClipboardText(response)

            // Show success status
            setStatus(.done)

            print("✅ Response copied to clipboard")
        } catch {
            print("❌ Error: \(error)")
            setStatus(.error(error.localizedDescription))
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
