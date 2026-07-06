import AppKit

/// Settings window for configuring API key, model, and prompt
class SettingsWindow: NSWindow {
    private let settings = SettingsManager.shared

    private var apiKeyField: NSSecureTextField!
    private var apiKeyPlainField: NSTextField!
    private var eyeButton: NSButton!
    private var modelPopup: NSPopUpButton!
    private var promptTextView: NSTextView!
    private var launchAtLoginCheckbox: NSButton!

    private static let contentSize = NSSize(width: 540, height: 640)
    private static let margin: CGFloat = 20

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: SettingsWindow.contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        self.title = "AI Text Agent Settings"
        self.level = .floating  // Show window on top of other windows
        self.isReleasedWhenClosed = false  // Don't release window when closed
        self.center()

        setupUI()
        loadSettings()
    }

    // MARK: - UI construction helpers

    private func sectionLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.frame = NSRect(x: SettingsWindow.margin, y: y, width: 300, height: 16)
        return label
    }

    private func captionLabel(_ text: String, y: CGFloat, width: CGFloat = 460) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: SettingsWindow.margin, y: y, width: width, height: 14)
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    private func linkButton(_ title: String, action: Selector, x: CGFloat, y: CGFloat, width: CGFloat) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.contentTintColor = .linkColor
        button.font = NSFont.systemFont(ofSize: 11)
        button.frame = NSRect(x: x, y: y, width: width, height: 16)
        button.alignment = .right
        return button
    }

    /// Set up the settings UI
    private func setupUI() {
        let W = SettingsWindow.contentSize.width
        let H = SettingsWindow.contentSize.height
        let margin = SettingsWindow.margin
        let contentW = W - margin * 2

        let contentView = NSView(frame: NSRect(origin: .zero, size: SettingsWindow.contentSize))

        // --- API Key ---
        contentView.addSubview(sectionLabel("Gemini API Key", y: H - 36))

        apiKeyField = NSSecureTextField(frame: NSRect(x: margin, y: H - 66, width: contentW - 42, height: 24))
        apiKeyField.placeholderString = "Paste your Gemini API key"
        apiKeyField.bezelStyle = .roundedBezel
        contentView.addSubview(apiKeyField)

        apiKeyPlainField = NSTextField(frame: apiKeyField.frame)
        apiKeyPlainField.placeholderString = apiKeyField.placeholderString
        apiKeyPlainField.bezelStyle = .roundedBezel
        apiKeyPlainField.isHidden = true
        contentView.addSubview(apiKeyPlainField)

        eyeButton = NSButton(frame: NSRect(x: W - margin - 34, y: H - 66, width: 34, height: 24))
        eyeButton.bezelStyle = .rounded
        eyeButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Show API key")
        eyeButton.target = self
        eyeButton.action = #selector(toggleKeyVisibility)
        contentView.addSubview(eyeButton)

        contentView.addSubview(captionLabel("Stored locally in app preferences", y: H - 86, width: 300))
        contentView.addSubview(linkButton("Get API Key ↗", action: #selector(openAPIKeyPage), x: W - margin - 110, y: H - 87, width: 110))

        // --- Model ---
        contentView.addSubview(sectionLabel("Model", y: H - 116))

        modelPopup = NSPopUpButton(frame: NSRect(x: margin, y: H - 147, width: 240, height: 25))
        modelPopup.removeAllItems()
        modelPopup.addItems(withTitles: settings.availableModels)
        contentView.addSubview(modelPopup)

        // --- Hotkeys info ---
        let hotkeysInfo = NSTextField(labelWithString: "⌘⇧Space → English 🇬🇧        ⌘⇧B → Romanian 🇷🇴")
        hotkeysInfo.font = NSFont.systemFont(ofSize: 12)
        hotkeysInfo.textColor = .secondaryLabelColor
        hotkeysInfo.frame = NSRect(x: margin, y: H - 172, width: contentW, height: 16)
        contentView.addSubview(hotkeysInfo)

        // --- Launch at login ---
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.frame = NSRect(x: margin, y: H - 200, width: 200, height: 18)
        contentView.addSubview(launchAtLoginCheckbox)

        // --- Separator ---
        let separator = NSBox(frame: NSRect(x: margin, y: H - 213, width: contentW, height: 1))
        separator.boxType = .separator
        contentView.addSubview(separator)

        // --- System Prompt ---
        contentView.addSubview(sectionLabel("System Prompt", y: H - 242))
        contentView.addSubview(linkButton("Restore Default", action: #selector(restoreDefaultPrompt), x: W - margin - 120, y: H - 242, width: 120))

        let editorTop = H - 250
        let editorBottom: CGFloat = 80
        let scrollView = NSScrollView(frame: NSRect(x: margin, y: editorBottom, width: contentW, height: editorTop - editorBottom))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder

        promptTextView = NSTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize))
        promptTextView.isEditable = true
        promptTextView.isSelectable = true
        promptTextView.isRichText = false
        promptTextView.allowsUndo = true
        promptTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        promptTextView.autoresizingMask = [.width]
        promptTextView.textContainerInset = NSSize(width: 6, height: 8)
        promptTextView.backgroundColor = .textBackgroundColor
        promptTextView.textColor = .textColor
        promptTextView.insertionPointColor = .textColor

        scrollView.documentView = promptTextView
        contentView.addSubview(scrollView)

        contentView.addSubview(captionLabel("Emoji, Sanskrit «ii» and ⌘⇧B Romanian rules are always enforced on top of this prompt", y: 58, width: contentW))

        // --- Bottom buttons ---
        let cancelButton = NSButton(frame: NSRect(x: W - margin - 90 - 8 - 82, y: 18, width: 90, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1B}" // Escape
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        contentView.addSubview(cancelButton)

        let saveButton = NSButton(frame: NSRect(x: W - margin - 82, y: 18, width: 82, height: 30))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter key
        saveButton.target = self
        saveButton.action = #selector(saveSettings)
        contentView.addSubview(saveButton)

        self.contentView = contentView
    }

    /// Load current settings into UI
    private func loadSettings() {
        apiKeyField.stringValue = settings.apiKey
        apiKeyPlainField.stringValue = settings.apiKey

        if let index = settings.availableModels.firstIndex(of: settings.model) {
            modelPopup.selectItem(at: index)
        }

        promptTextView.string = settings.systemPrompt

        // Update launch at login status and checkbox
        settings.updateLaunchAtLoginStatus()
        launchAtLoginCheckbox.state = settings.launchAtLogin ? .on : .off

        // Set initial focus to API key field
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.makeFirstResponder(self.visibleKeyField)
        }
    }

    /// Override to set focus when window becomes key
    override func becomeKey() {
        super.becomeKey()
        if visibleKeyField.stringValue.isEmpty {
            makeFirstResponder(visibleKeyField)
        }
    }

    private var visibleKeyField: NSTextField {
        return apiKeyPlainField.isHidden ? apiKeyField : apiKeyPlainField
    }

    /// Toggle between secure and plain API key field
    @objc private func toggleKeyVisibility() {
        let revealing = !apiKeyField.isHidden
        if revealing {
            apiKeyPlainField.stringValue = apiKeyField.stringValue
        } else {
            apiKeyField.stringValue = apiKeyPlainField.stringValue
        }
        apiKeyField.isHidden = revealing
        apiKeyPlainField.isHidden = !revealing
        let symbol = revealing ? "eye.slash" : "eye"
        eyeButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: revealing ? "Hide API key" : "Show API key")
        makeFirstResponder(visibleKeyField)
    }

    @objc private func openAPIKeyPage() {
        if let url = URL(string: "https://aistudio.google.com/apikey") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Put the default prompt into the editor (persisted only on Save)
    @objc private func restoreDefaultPrompt() {
        promptTextView.string = settings.defaultPromptText
    }

    /// Save settings and close silently
    @objc private func saveSettings() {
        settings.apiKey = visibleKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let selectedModel = modelPopup.selectedItem?.title {
            settings.model = selectedModel
        }

        settings.systemPrompt = promptTextView.string
        self.close()
    }

    /// Cancel and close window
    @objc private func cancel() {
        self.close()
    }

    /// Handle launch at login checkbox change
    @objc private func launchAtLoginChanged() {
        settings.launchAtLogin = (launchAtLoginCheckbox.state == .on)
    }
}
