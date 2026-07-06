import AppKit
import Carbon
import Foundation

/// Controls the menu bar icon and menu
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let hotKeyManager = HotKeyManager()
    private let textCaptureService = TextCaptureService()
    private let aiService = AIService()
    private var settingsWindow: SettingsWindow?  // Keep strong reference

    // Original clipboard texts (before being replaced by translations), newest first
    private var originalHistory: [String] = []
    private let historyLimit = 4
    private var historyMenuItems: [NSMenuItem] = []
    private var historyPlaceholderItem: NSMenuItem?

    override init() {
        super.init()
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

        let usageItem2 = NSMenuItem(title: "2. ⌘⇧Space → English", action: nil, keyEquivalent: "")
        usageItem2.isEnabled = false
        menu.addItem(usageItem2)

        let usageItem2b = NSMenuItem(title: "    ⌘⇧B → Romanian", action: nil, keyEquivalent: "")
        usageItem2b.isEnabled = false
        menu.addItem(usageItem2b)

        let usageItem3 = NSMenuItem(title: "3. AI result → clipboard", action: nil, keyEquivalent: "")
        usageItem3.isEnabled = false
        menu.addItem(usageItem3)

        menu.addItem(NSMenuItem.separator())

        // Last original texts (pre-translation), click restores one to clipboard
        let placeholder = NSMenuItem(title: "No original text yet", action: nil, keyEquivalent: "")
        placeholder.toolTip = "Last original (pre-translation) texts will appear here"
        menu.addItem(placeholder)
        historyPlaceholderItem = placeholder

        for _ in 0..<historyLimit {
            let item = NSMenuItem(title: "", action: #selector(restoreHistoryItem(_:)), keyEquivalent: "")
            item.target = self
            item.isHidden = true
            menu.addItem(item)
            historyMenuItems.append(item)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

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
                button.toolTip = "AI Text Agent - Ready\n⌘⇧Space → English\n⌘⇧B → Romanian"

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

    /// Hotkey ids
    private enum HotKeyID: UInt32 {
        case english = 1
        case romanian = 2
    }

    /// Set up global hotkeys (⌘⇧Space → English, ⌘⇧B → Romanian)
    private func setupHotKey() {
        let hotKeys = [
            HotKeyManager.HotKey(id: HotKeyID.english.rawValue, keyCode: 49, modifiers: UInt32(cmdKey | shiftKey), label: "Cmd+Shift+Space (English)"),
            HotKeyManager.HotKey(id: HotKeyID.romanian.rawValue, keyCode: 11, modifiers: UInt32(cmdKey | shiftKey), label: "Cmd+Shift+B (Romanian)")
        ]
        hotKeyManager.registerHotKeys(hotKeys) { [weak self] id in
            let target: TargetLanguage = (id == HotKeyID.romanian.rawValue) ? .romanian : .english
            self?.handleHotKeyPressed(target: target)
        }
    }

    /// Handle hotkey press - read clipboard and send to AI
    private func handleHotKeyPressed(target: TargetLanguage) {
        print("🔥 Hotkey pressed! Target: \(target)")

        // Read clipboard
        guard let clipboardText = textCaptureService.getClipboardText() else {
            print("⚠️  Clipboard is empty")
            setStatus(.error("Empty clipboard"))
            return
        }

        print("📝 Processing clipboard text: \(clipboardText.prefix(50))...")

        // Remember the original text before the clipboard gets replaced
        rememberOriginalText(clipboardText)

        // Show processing status
        setStatus(.processing)

        // Send to AI
        Task {
            await processWithAI(text: clipboardText, target: target)
        }
    }

    /// Process text with AI service
    private func processWithAI(text: String, target: TargetLanguage) async {
        print("🤖 Sending to AI: \(text.prefix(50))...")
        do {
            let response = try await aiService.processText(text, target: target)
            print("✅ AI Response received: \(response.prefix(50))...")

            // Copy response to clipboard
            textCaptureService.setClipboardText(response)

            // Show success status
            setStatus(.done)
            DispatchQueue.main.async { [weak self] in
                ToastWindow.show(style: .success, flag: target.flag, title: "Done", text: response, under: self?.statusItem)
            }

            print("✅ Response copied to clipboard")
        } catch {
            print("❌ Error: \(error)")
            setStatus(.error(error.localizedDescription))
            let message = error.localizedDescription
            DispatchQueue.main.async { [weak self] in
                ToastWindow.show(style: .failure, flag: target.flag, title: "Error", text: message, under: self?.statusItem)
            }
        }
    }

    /// Remember original clipboard text in history (newest first, deduplicated)
    private func rememberOriginalText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.originalHistory.removeAll { $0 == text }
            self.originalHistory.insert(text, at: 0)
            if self.originalHistory.count > self.historyLimit {
                self.originalHistory.removeLast(self.originalHistory.count - self.historyLimit)
            }
            self.refreshHistoryMenu()
        }
    }

    /// Sync history menu items with the history array
    private func refreshHistoryMenu() {
        historyPlaceholderItem?.isHidden = !originalHistory.isEmpty
        for (index, item) in historyMenuItems.enumerated() {
            if index < originalHistory.count {
                let text = originalHistory[index]
                item.title = "↩ \(Self.menuPreview(of: text))"
                item.representedObject = text
                item.toolTip = String(text.prefix(500))
                item.isHidden = false
            } else {
                item.isHidden = true
                item.representedObject = nil
            }
        }
    }

    /// One-line truncated preview for the menu item title
    private static func menuPreview(of text: String) -> String {
        let oneLine = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return oneLine.count > 40 ? String(oneLine.prefix(40)) + "…" : oneLine
    }

    @objc private func restoreHistoryItem(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        textCaptureService.setClipboardText(text)
        print("↩ Original text restored to clipboard")
        ToastWindow.show(style: .success, flag: "📋", title: "Restored", text: text, under: statusItem)
    }

    @objc private func openSettings() {
        // If window already exists, just show it
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new settings window
        settingsWindow = SettingsWindow()

        // Set delegate to handle window closing
        settingsWindow?.delegate = self

        // Show window
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

/// Extension to handle window delegate
extension MenuBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clear the reference when window is closed
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
    }
}
