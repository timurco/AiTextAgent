# Setup Installation Script

This guide explains how to set up the one-command installation for AI Text Agent.

## Steps to Enable One-Command Installation

### 1. Update install.sh with Your Repository URL

Edit `install.sh` and replace the placeholder:

```bash
REPO_URL="https://github.com/USERNAME/REPO"
```

With your actual GitHub repository URL:

```bash
REPO_URL="https://github.com/yourusername/ai-text-agent"
```

### 2. Commit and Push to GitHub

```bash
git add install.sh
git commit -m "Add installation script"
git push origin main
```

### 3. Share Installation Command

Users can now install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/ai-text-agent/main/install.sh | bash
```

## What the Install Script Does

1. **System Checks**
   - Verifies macOS (13.0+)
   - Checks Swift installation
   - Validates Xcode Command Line Tools

2. **Download & Build**
   - Clones the repository (or downloads zip if git not available)
   - Builds release version with `swift build -c release`
   - Creates `.app` bundle with proper structure

3. **Installation**
   - Installs to `/Applications/`
   - Asks permission to replace if already installed
   - Terminates running instance if needed

4. **Post-Install Setup**
   - Prompts for Gemini API key (optional)
   - Saves API key to UserDefaults
   - Offers to launch the app

5. **Cleanup**
   - Removes temporary build files
   - Cleans up on exit or error

## Security Considerations

The script uses `set -euo pipefail` for safe execution:
- `-e`: Exit on error
- `-u`: Error on undefined variables
- `-o pipefail`: Catch errors in pipes

Users should review scripts before piping to bash:

```bash
# Download and review first
curl -fsSL https://raw.githubusercontent.com/yourusername/ai-text-agent/main/install.sh > install.sh
cat install.sh
bash install.sh
```

## Alternative: GitHub Releases

For production apps, consider using GitHub Releases with pre-built binaries:

```bash
# Example with pre-built app
curl -fsSL https://github.com/yourusername/ai-text-agent/releases/latest/download/AI-Text-Agent.zip -o app.zip
unzip app.zip
mv "AI Text Agent.app" /Applications/
```

**Pros:**
- Faster (no compilation)
- Consistent builds
- Code-signed binaries

**Cons:**
- Requires code signing certificate
- Larger repository size
- Need to build for each release

## Customization

You can customize the install script:

### Change Install Directory

```bash
INSTALL_DIR="$HOME/Applications"  # Install to user's Applications
```

### Skip API Key Prompt

Comment out the `setup_api_key` function call in `main()`.

### Add Auto-Launch Setup

Add after `install_app()`:

```bash
# Enable launch at login
defaults write com.timurko.AITextAgent launch_at_login -bool true
```

## Troubleshooting

### "Swift not found"

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Permission denied" during install

The script needs to write to `/Applications/`:
```bash
sudo bash install.sh
```

### Git clone fails

The script automatically falls back to downloading zip if git is not available.

### Build fails

Check Swift version:
```bash
swift --version  # Should be 5.9+
```

## Testing Locally

Test the script before publishing:

```bash
# Run locally
bash install.sh

# Or test the curl pattern
python3 -m http.server 8000 &
curl -fsSL http://localhost:8000/install.sh | bash
```
