# AI Text Agent

macOS menu bar application for instant text translation to English or Romanian using Google Gemini AI and global hotkeys.

![AiTextAgent_English_Translation_Demo](https://github.com/user-attachments/assets/ebcebaec-f4d0-4b7c-b66f-f840a3579178)

## Features

- **One-Key Translation**: Press `⌘⇧Space` (Cmd+Shift+Space) to translate clipboard text to English
- **Romanian Translation**: Press `⌘⇧B` (Cmd+Shift+B) to translate to Romanian
- **Emoji Preserved**: All emoji from the source text are kept in the translation
- **Original Text History**: Menu keeps the last 4 original (pre-translation) texts, click one to restore it to clipboard
- **Toast Notifications**: Tiny toast (150x40) under the menu bar icon shows result: green header on success, red on error, with target language flag; never steals focus
- **Menu Bar Integration**: Lightweight menu bar app that runs in the background
- **Visual Status Indicators**: See processing status (⏳), completion (✅), or errors (❌) right in the menu bar
- **Helpful Tooltips**: Hover over the icon for detailed status information
- **Clipboard-Based**: Works with any copied text, no complex permissions needed
- **AI-Powered**: Uses Google Gemini for natural, context-aware translation
- **Instant Results**: Translation automatically replaces clipboard content

## How It Works

1. **Copy** any text to clipboard (⌘C)
2. **Press** `⌘⇧Space` (English) or `⌘⇧B` (Romanian)
3. **Get** translation in clipboard automatically
4. **Paste** wherever you need (⌘V)

## Requirements

- macOS 13.0 or later
- Swift 5.9+
- Google Gemini API key

## Installation

### Quick Install (Recommended)

Install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/timurco/AiTextAgent/main/install.sh | bash
```

**What this does:**
- Checks system requirements (macOS 13.0+, Swift)
- Downloads the latest version from GitHub
- Builds the application bundle
- Installs to `/Applications/`
- Optionally sets up your API key

### Manual Installation

#### 1. Get Google Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/apikey)
2. Create or sign in to your Google account
3. Generate an API key

#### 2. Build the Application Bundle

```bash
# Build and create .app bundle
./build_app.sh

# Install to Applications folder
cp -r "AI Text Agent.app" /Applications/

# Or just double-click the .app to run from current directory
```

**Alternative: Build executable only**

```bash
# Build in release mode (creates standalone executable)
swift build -c release

# The executable will be at: .build/release/AITextAgent
```

## Usage

### Running the App

**Option 1: Run as macOS Application (Recommended)**

```bash
# Double-click the app or use:
open "AI Text Agent.app"
```

**Option 2: Run executable directly**

```bash
# Run the app from terminal
.build/release/AITextAgent
```

You'll see a brain icon (🧠) appear in your menu bar.

### First-Time Setup

1. Click on the brain icon (🧠) in the menu bar
2. Select "Settings..." (or press ⌘,)
3. Enter your Gemini API key
4. (Optional) Choose a different Gemini model
5. (Optional) Customize the translation prompt
6. Click "Save"

**Note**: The API key is stored securely in macOS UserDefaults and persists between app restarts.

### Quick Start

1. Copy any text in any language (⌘C)
2. Press `⌘⇧Space`
3. Watch the menu bar icon change to ⏳ (processing)
4. When you see ✅ appear, the translation is ready in your clipboard
5. Paste the translation (⌘V)

### Status Indicators

The app shows its current state directly in the menu bar:

- **🧠** - Ready and waiting (hover to see "AI Text Agent - Ready")
- **🧠 ⏳** - Processing your text with AI (hover to see "Processing...")
- **🧠 ✅** - Translation complete and copied to clipboard (auto-clears after 3 seconds)
- **🧠 ❌** - Error occurred (hover to see error details, auto-clears after 5 seconds)

**Tooltip Information:**
- Hover your mouse over the menu bar icon to see detailed status
- Ready state shows usage instructions
- Processing state shows what's happening
- Done state confirms translation is ready
- Error state shows the specific error message

### Auto-Launch at Login

The application includes built-in support for auto-launch at system startup using macOS ServiceManagement framework.

**To enable auto-launch:**

1. Install the app to `/Applications/`:
```bash
cp -r "AI Text Agent.app" /Applications/
```

2. Launch the app from `/Applications/`
3. Click the brain icon (🧠) in the menu bar
4. Select "Settings..." (or press ⌘,)
5. Check the "Launch at Login" checkbox
6. Click "Save"

The app will now automatically start when you log in to macOS.

**Notes:**
- The app must be in `/Applications/` for auto-launch to work
- Auto-launch uses macOS native ServiceManagement framework (SMAppService)
- No manual LaunchAgent configuration needed
- You can enable/disable auto-launch anytime from Settings

## Settings

The app includes a full settings interface accessible from the menu bar:

### Available Settings

1. **API Key**: Your Google Gemini API key (stored securely in UserDefaults)
2. **Model Selection**: Choose from available Gemini models:
   - `gemini-2.5-pro`
   - `gemini-flash-latest` (default, fast)
   - `gemini-flash-lite-latest`
   - `gemini-2.5-flash`
   - `gemini-2.5-flash-lite`
3. **Launch at Login**: Enable/disable automatic startup with macOS
4. **System Prompt**: Customize the translation instructions and style rules

### Accessing Settings

- Click menu bar icon → "Settings..."
- Or use keyboard shortcut: **⌘,** (Cmd+Comma)

### Customizing Translation Prompt

The system prompt controls how the AI translates text. You can:
- Change translation rules
- Add specific terminology handling
- Modify output style preferences
- Add domain-specific instructions

Default prompt includes rules for:
- Natural style matching (informal/formal)
- Context awareness with bracketed information
- Proper transliteration (Sanskrit names, etc.)
- Human-like punctuation (' instead of ', - instead of —)
- Technical term preservation (AE = After Effects)
- Clean formatting without AI hedging

## Architecture

### Project Structure

```
07_AiTextAgent/
├── Package.swift                     # Swift package configuration
├── README.md                         # This file
├── LICENSE                           # MIT License
├── build_app.sh                      # Build script for .app bundle
├── Sources/
│   └── AITextAgent/
│       ├── main.swift               # Application entry point
│       ├── Info.plist               # App bundle configuration
│       ├── MenuBarController.swift  # Menu bar UI and orchestration
│       ├── HotKeyManager.swift      # Global hotkey registration
│       ├── TextCaptureService.swift # Clipboard read/write
│       ├── AIService.swift          # Google Gemini API integration
│       ├── SettingsManager.swift    # UserDefaults & auto-launch
│       └── SettingsWindow.swift     # Settings UI window
├── .env.example                     # Environment variables template (optional)
└── .gitignore
```

### Components

- **main.swift**: Application entry point and lifecycle management
- **Info.plist**: macOS app bundle configuration (LSUIElement for menu bar mode)
- **MenuBarController**: Manages menu bar icon, menu, status indicators, and coordinates all services
- **HotKeyManager**: Registers and handles global hotkeys (Cmd+Shift+Space, Cmd+Shift+B)
- **TextCaptureService**: Simple clipboard read/write operations
- **AIService**: Communicates with Google Gemini API for translation
- **SettingsManager**: Manages app settings persistence and auto-launch using ServiceManagement
- **SettingsWindow**: Provides UI for configuring API key, model, auto-launch, and translation prompt
- **build_app.sh**: Automated script to build macOS .app bundle

### Why Clipboard-Only?

This app uses a simple clipboard-based approach instead of complex text selection capture because:

1. **No Special Permissions**: No Accessibility API permissions needed
2. **Universal Compatibility**: Works with any app that supports copy/paste
3. **Reliable**: No issues with protected text fields or security restrictions
4. **Simple**: Users already know how to copy text

## Development

### Build and Run

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run with debugging
lldb -o "env GEMINI_API_KEY=your_key" -o "run" .build/release/AITextAgent
```

## Troubleshooting

### "Empty Clipboard"
- Make sure you copied some text (⌘C) before pressing the hotkey
- The clipboard must contain text, not images or other data

### "API key not configured"
- Open Settings (⌘,) and enter your API key
- Make sure the API key is valid and has proper permissions
- The API key is saved to UserDefaults automatically

### Error indicator (❌) appears
- Hover over the menu bar icon to see the specific error message
- Check your internet connection
- Verify API key is correct
- Check Console.app for detailed error messages

### Hotkey not working
- Check that no other app is using ⌘⇧Space
- Restart the application
- Check Console.app for error messages

### Menu bar icon not showing
- Make sure the app is running (check Activity Monitor)
- Try restarting the app
- Check system menu bar settings (some apps hide overflow items)

## Tips

- **Quick Workflow**: Select text → ⌘C → ⌘⇧Space → wait 2 seconds → ⌘V
- **No Selection Needed**: Just copy text from anywhere before pressing hotkey
- **Batch Processing**: Copy multiple paragraphs at once for longer translations
- **Preserve Context**: Add context in square brackets like `[technical documentation]` for better results

## License

MIT
