# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Text Agent is a macOS menu bar application for instant text translation to English using Google Gemini AI and a global hotkey (⌘⇧Space). The app runs as a lightweight background process using the clipboard-based workflow: copy text → press hotkey → get translation in clipboard.

## Build Commands

### Development Build
```bash
# Debug build (default)
swift build

# Run debug executable
.build/debug/AITextAgent
```

### Release Build
```bash
# Build release executable
swift build -c release

# Run release executable
.build/release/AITextAgent
```

### Application Bundle
```bash
# Build complete .app bundle (recommended)
./build_app.sh

# Install to Applications folder
cp -r "AI Text Agent.app" /Applications/

# Launch the app
open "AI Text Agent.app"
```

### Debugging
```bash
# Run with API key override
lldb -o "env GEMINI_API_KEY=your_key" -o "run" .build/release/AITextAgent
```

## Architecture Overview

### Menu Bar Application Design

The app runs as a **menu bar-only application** (LSUIElement: true in Info.plist), meaning:
- No dock icon
- No main window
- Runs entirely from the menu bar
- Settings window appears on demand

### Component Orchestration Flow

```
main.swift (AppDelegate)
    └─> MenuBarController (central orchestrator)
            ├─> HotKeyManager (global hotkey ⌘⇧Space)
            ├─> TextCaptureService (clipboard I/O)
            ├─> AIService (Google Gemini API)
            └─> SettingsWindow (settings UI)
```

**Key orchestration principle**: MenuBarController is the **central coordinator** that owns all services and manages the workflow. When hotkey is pressed:

1. HotKeyManager triggers callback → MenuBarController.handleHotKeyPressed()
2. MenuBarController reads clipboard via TextCaptureService
3. MenuBarController updates menu bar status to "processing"
4. MenuBarController sends text to AIService
5. AIService makes async API call to Gemini
6. MenuBarController receives response
7. MenuBarController writes result to clipboard via TextCaptureService
8. MenuBarController updates menu bar status to "done"

### Service Layer Details

**AIService.swift**
- Uses URLSession for async HTTP requests to Google Gemini API
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}`
- Combines system prompt with user text in single request
- Parses JSON response to extract translated text from `candidates[0].content.parts[0].text`
- Retrieves API key and model from SettingsManager singleton

**HotKeyManager.swift**
- Uses Carbon Event Manager API for global hotkey registration
- Registers Cmd+Shift+Space (keyCode: 49, modifiers: cmdKey | shiftKey)
- Uses manual memory management (Unmanaged) to retain self for C callback
- Single callback pattern: pass closure during registration

**TextCaptureService.swift**
- Simple wrapper around NSPasteboard.general
- Read/write text from/to clipboard
- No permissions required (clipboard-based workflow)

**SettingsManager.swift**
- Singleton pattern for app settings
- Uses UserDefaults for persistence (keys: gemini_api_key, gemini_model, system_prompt, launch_at_login)
- Manages auto-launch via SMAppService (macOS 13.0+ ServiceManagement framework)
- Falls back to GEMINI_API_KEY environment variable if UserDefaults is empty
- Default model: gemini-flash-latest

**SettingsWindow.swift**
- Creates NSWindow programmatically (not from XIB/Storyboard)
- Manual UI layout with NSStackView
- Provides: API key input, model dropdown, launch at login checkbox, system prompt text editor
- Window lifecycle managed by MenuBarController (strong reference)

### Status Indicator System

MenuBarController manages 4 status states with visual feedback:

- **idle**: Brain icon only, tooltip shows usage instructions
- **processing**: Brain + ⏳, tooltip shows "Processing..."
- **done**: Brain + ✅, tooltip shows "Done!", auto-clears after 3 seconds
- **error**: Brain + ❌, tooltip shows error message, auto-clears after 5 seconds

Status updates happen on main thread via DispatchQueue.main.async.

## Important Implementation Details

### No External Dependencies
- Pure Swift implementation using only system frameworks
- AppKit for UI (menu bar, windows)
- Foundation for networking (URLSession)
- Carbon for global hotkeys
- ServiceManagement for auto-launch

### Thread Safety
- All menu bar UI updates use `DispatchQueue.main.async`
- AI processing happens in async Task context
- Clipboard operations are synchronous (fast enough)

### Info.plist Requirements
The app bundle requires Info.plist with:
- `LSUIElement: true` - hides from dock, makes it menu bar-only
- `CFBundleName`, `CFBundleIdentifier`, `CFBundleExecutable` - standard bundle metadata
- No special permissions needed (no Accessibility API)

### Auto-Launch Constraints
- App **must** be in `/Applications/` for SMAppService to work
- Uses macOS 13.0+ ServiceManagement framework (SMAppService)
- Code signing is optional for testing but required for distribution
- No manual LaunchAgent plist needed

### API Key Security
- Stored in UserDefaults (not in code or git)
- Can be overridden via GEMINI_API_KEY environment variable
- Settings window provides secure input (though not password-protected)

## Development Workflow

### Testing Translation Flow
1. Build and run the app: `./build_app.sh && open "AI Text Agent.app"`
2. Set API key via menu bar → Settings
3. Copy test text: `echo "Привет, мир!" | pbcopy`
4. Press ⌘⇧Space
5. Check clipboard: `pbpaste`

### Adding New Gemini Models
Edit `SettingsManager.availableModels` array (line 71-78).

### Customizing Default System Prompt
Edit `SettingsManager.defaultSystemPrompt` (line 20-27).

### Modifying Hotkey
Edit `HotKeyManager.registerHotKey()`:
- Change `keyCode` (line 16) - see Carbon key codes
- Change `modifiers` (line 17) - cmdKey, shiftKey, optionKey, controlKey

## Common Pitfalls

1. **Settings window not appearing**: Check that MenuBarController maintains strong reference to SettingsWindow (line 10, 160)
2. **Hotkey not working**: Ensure no other app uses ⌘⇧Space, check Console.app for Carbon errors
3. **Auto-launch failing**: App must be in /Applications/, not running from .build/ directory
4. **Empty responses from API**: Check that system prompt doesn't exceed token limits
5. **Menu bar icon disappearing**: App terminated unexpectedly, check crash logs in Console.app

## File Structure

```
Sources/AITextAgent/
├── main.swift               # Entry point, AppDelegate
├── Info.plist              # Bundle configuration (LSUIElement, etc.)
├── MenuBarController.swift # Central orchestrator
├── HotKeyManager.swift     # Global hotkey (Carbon API)
├── TextCaptureService.swift # Clipboard I/O
├── AIService.swift         # Gemini API client
├── SettingsManager.swift   # Persistent settings + auto-launch
└── SettingsWindow.swift    # Settings UI
```

## Platform Requirements

- **macOS**: 13.0+ (required for SMAppService auto-launch)
- **Swift**: 5.9+ (specified in Package.swift)
- **Xcode**: Not required (pure Swift Package Manager project)
