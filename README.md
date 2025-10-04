# AI Text Agent

macOS menu bar application for instant text translation to English using Google Gemini AI and a global hotkey.

![AiTextAgent_English_Translation_Demo](https://github.com/user-attachments/assets/ebcebaec-f4d0-4b7c-b66f-f840a3579178)

## Features

- **One-Key Translation**: Press `⌘⇧Space` (Cmd+Shift+Space) to translate clipboard text
- **Menu Bar Integration**: Lightweight menu bar app that runs in the background
- **Visual Status Indicators**: See processing status (⏳), completion (✅), or errors (❌) right in the menu bar
- **Helpful Tooltips**: Hover over the icon for detailed status information
- **Clipboard-Based**: Works with any copied text, no complex permissions needed
- **AI-Powered**: Uses Google Gemini for natural, context-aware translation
- **Instant Results**: Translation automatically replaces clipboard content

## How It Works

1. **Copy** any text to clipboard (⌘C)
2. **Press** `⌘⇧Space`
3. **Get** English translation in clipboard automatically
4. **Paste** wherever you need (⌘V)

## Requirements

- macOS 13.0 or later
- Swift 5.9+
- Google Gemini API key

## Installation

### 1. Get Google Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/apikey)
2. Create or sign in to your Google account
3. Generate an API key

### 2. Configure Environment

```bash
cd 07_AiTextAgent
cp .env.example .env
# Edit .env and add your API key:
# GEMINI_API_KEY=your_api_key_here
```

### 3. Build the Application

```bash
# Build in release mode
swift build -c release

# The executable will be at: .build/release/AITextAgent
```

## Usage

### Running the App

```bash
# Set API key in environment
export GEMINI_API_KEY="your_api_key_here"

# Run the app
.build/release/AITextAgent
```

You'll see a brain icon (🧠) appear in your menu bar.

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

### Running on Startup (Optional)

Create a launch agent to run automatically:

1. Copy the executable to a permanent location:
```bash
mkdir -p ~/Applications
cp .build/release/AITextAgent ~/Applications/
```

2. Create launch agent plist:
```bash
mkdir -p ~/Library/LaunchAgents
```

Create `~/Library/LaunchAgents/com.aitextagent.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aitextagent</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/Applications/AITextAgent</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>GEMINI_API_KEY</key>
        <string>your_api_key_here</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

3. Load the launch agent:
```bash
launchctl load ~/Library/LaunchAgents/com.aitextagent.plist
```

## Translation Features

The AI translator is configured with specific rules:

- **Natural Style Matching**: Preserves informal/formal tone of original text
- **Context-Aware**: Uses bracketed information for context (brackets removed in output)
- **Human-Like Output**: Uses natural punctuation (' instead of ', - instead of —)
- **Technical Terms**: Preserves abbreviations like "AE" (After Effects) as-is
- **Clean Formatting**: No unnecessary quotes, periods, or formal hedging

## Architecture

### Project Structure

```
07_AiTextAgent/
├── Package.swift                    # Swift package configuration
├── README.md                        # This file
├── Sources/
│   └── AITextAgent/
│       ├── main.swift              # Application entry point
│       ├── MenuBarController.swift # Menu bar UI and orchestration
│       ├── HotKeyManager.swift     # Global hotkey registration
│       ├── TextCaptureService.swift # Clipboard read/write
│       └── AIService.swift         # Google Gemini API integration
├── .env.example                    # Environment variables template
└── .gitignore
```

### Components

- **main.swift**: Application entry point and lifecycle management
- **MenuBarController**: Manages menu bar icon, menu, and coordinates all services
- **HotKeyManager**: Registers and handles global hotkey (Cmd+Shift+Space)
- **TextCaptureService**: Simple clipboard read/write operations
- **AIService**: Communicates with Google Gemini API for translation

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
- Set `GEMINI_API_KEY` environment variable
- Check that the API key is valid and has proper permissions

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
