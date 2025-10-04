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
            showNotification(title: "Empty Clipboard", message: "Copy some text first, then press ⌘⇧Space")
            return
        }

        print("📝 Processing clipboard text: \(clipboardText.prefix(50))...")

        // Show processing notification
        showNotification(title: "Processing...", message: "AI is working on your text")

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

            // Show success notification
            showNotification(title: "✅ Done!", message: "AI response copied to clipboard")

            print("✅ Response copied to clipboard")
        } catch {
            print("❌ Error: \(error)")
            showNotification(title: "Error", message: error.localizedDescription)
        }
    }

    /// Show macOS notification
    private func showNotification(title: String, message: String) {
        print("🔔 Showing notification: \(title) - \(message.prefix(50))...")
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
        print("🔔 Notification delivered")
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
