import AppKit

/// Settings window for configuring API key, model, and prompt
class SettingsWindow: NSWindow {
    private let settings = SettingsManager.shared

    private var apiKeyField: NSSecureTextField!
    private var modelPopup: NSPopUpButton!
    private var promptTextView: NSTextView!
    private var launchAtLoginCheckbox: NSButton!

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
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

    /// Set up the settings UI
    private func setupUI() {
        let contentView = NSView(frame: self.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        var yPos: CGFloat = 450

        // Title
        let titleLabel = NSTextField(labelWithString: "Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: yPos, width: 560, height: 30)
        contentView.addSubview(titleLabel)

        yPos -= 50

        // API Key section
        let apiKeyLabel = NSTextField(labelWithString: "Gemini API Key:")
        apiKeyLabel.frame = NSRect(x: 20, y: yPos, width: 150, height: 20)
        contentView.addSubview(apiKeyLabel)

        apiKeyField = NSSecureTextField(frame: NSRect(x: 20, y: yPos - 30, width: 560, height: 24))
        apiKeyField.placeholderString = "Enter your Gemini API key"
        apiKeyField.isEditable = true
        apiKeyField.isSelectable = true
        apiKeyField.isBordered = true
        apiKeyField.bezelStyle = .roundedBezel
        apiKeyField.backgroundColor = .white
        contentView.addSubview(apiKeyField)

        yPos -= 70

        // Model section
        let modelLabel = NSTextField(labelWithString: "Gemini Model:")
        modelLabel.frame = NSRect(x: 20, y: yPos, width: 150, height: 20)
        contentView.addSubview(modelLabel)

        modelPopup = NSPopUpButton(frame: NSRect(x: 20, y: yPos - 30, width: 300, height: 25))
        modelPopup.removeAllItems()
        modelPopup.addItems(withTitles: settings.availableModels)
        contentView.addSubview(modelPopup)

        yPos -= 70

        // Launch at login checkbox
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: yPos, width: 200, height: 20)
        contentView.addSubview(launchAtLoginCheckbox)

        yPos -= 40

        // System Prompt section
        let promptLabel = NSTextField(labelWithString: "System Prompt:")
        promptLabel.frame = NSRect(x: 20, y: yPos, width: 560, height: 20)
        contentView.addSubview(promptLabel)

        yPos -= 10

        // Create scrollable text view for prompt
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: yPos - 60))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]

        promptTextView = NSTextView(frame: scrollView.bounds)
        promptTextView.isEditable = true
        promptTextView.isSelectable = true
        promptTextView.isRichText = false
        promptTextView.allowsUndo = true
        promptTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        promptTextView.autoresizingMask = [.width]
        promptTextView.textContainerInset = NSSize(width: 5, height: 5)
        promptTextView.backgroundColor = .white
        promptTextView.textColor = .black
        promptTextView.insertionPointColor = .black

        scrollView.documentView = promptTextView
        contentView.addSubview(scrollView)

        // Buttons at bottom
        let resetButton = NSButton(frame: NSRect(x: 20, y: 20, width: 100, height: 28))
        resetButton.title = "Reset"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)
        contentView.addSubview(resetButton)

        let cancelButton = NSButton(frame: NSRect(x: 380, y: 20, width: 100, height: 28))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        contentView.addSubview(cancelButton)

        let saveButton = NSButton(frame: NSRect(x: 490, y: 20, width: 90, height: 28))
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
            self.makeFirstResponder(self.apiKeyField)
        }
    }

    /// Override to set focus when window becomes key
    override func becomeKey() {
        super.becomeKey()
        if apiKeyField.stringValue.isEmpty {
            makeFirstResponder(apiKeyField)
        }
    }

    /// Save settings
    @objc private func saveSettings() {
        settings.apiKey = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let selectedModel = modelPopup.selectedItem?.title {
            settings.model = selectedModel
        }

        settings.systemPrompt = promptTextView.string

        // Show confirmation
        let alert = NSAlert()
        alert.messageText = "Settings Saved"
        alert.informativeText = "Your settings have been saved successfully."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self) { [weak self] _ in
            // Don't close the window, just dismiss the alert
            // User can close window manually if needed
        }
    }

    /// Reset to default settings
    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset to Defaults"
        alert.informativeText = "Are you sure you want to reset all settings to defaults? This will not change your API key."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        alert.beginSheetModal(for: self) { response in
            if response == .alertFirstButtonReturn {
                self.settings.resetToDefaults()
                self.loadSettings()
            }
        }
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
