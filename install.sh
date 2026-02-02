#!/bin/bash

# AI Text Agent Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/install.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/timurco/AiTextAgent"
APP_NAME="AI Text Agent"
BUNDLE_ID="com.timurko.AITextAgent"
INSTALL_DIR="/Applications"
TEMP_DIR=$(mktemp -d)

# Print colored message
print_status() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Cleanup on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script only works on macOS"
        exit 1
    fi
    print_success "Running on macOS"
}

# Check macOS version (requires 13.0+)
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major=$(echo "$version" | cut -d. -f1)

    if [ "$major" -lt 13 ]; then
        print_error "macOS 13.0 or later is required (you have $version)"
        exit 1
    fi
    print_success "macOS version $version"
}

# Check if Swift is installed
check_swift() {
    if ! command -v swift &> /dev/null; then
        print_error "Swift is not installed"
        print_warning "Please install Xcode Command Line Tools:"
        echo "  xcode-select --install"
        exit 1
    fi

    local swift_version=$(swift --version | head -n 1)
    print_success "Swift found: $swift_version"
}

# Download repository
download_repo() {
    print_status "Downloading AI Text Agent..."

    cd "$TEMP_DIR"

    # Try to clone the repo, or download as zip
    if command -v git &> /dev/null; then
        git clone --depth 1 "$REPO_URL.git" ai-text-agent
        cd ai-text-agent
    else
        print_warning "Git not found, downloading as zip..."
        curl -fsSL "$REPO_URL/archive/refs/heads/main.zip" -o repo.zip
        unzip -q repo.zip
        cd *-main
    fi

    print_success "Repository downloaded"
}

# Build the application
build_app() {
    print_status "Building AI Text Agent..."

    # Build release version
    swift build -c release

    if [ ! -f ".build/release/AITextAgent" ]; then
        print_error "Build failed: executable not found"
        exit 1
    fi

    print_success "Build completed"
}

# Create app bundle
create_app_bundle() {
    print_status "Creating application bundle..."

    local APP_BUNDLE="${APP_NAME}.app"

    # Remove existing bundle if present
    if [ -d "$APP_BUNDLE" ]; then
        rm -rf "$APP_BUNDLE"
    fi

    # Create bundle structure
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"

    # Copy executable
    cp ".build/release/AITextAgent" "${APP_BUNDLE}/Contents/MacOS/"

    # Copy Info.plist
    cp "Sources/AITextAgent/Info.plist" "${APP_BUNDLE}/Contents/"

    # Create PkgInfo
    echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

    # Make executable
    chmod +x "${APP_BUNDLE}/Contents/MacOS/AITextAgent"

    print_success "Application bundle created"
}

# Install to /Applications
install_app() {
    print_status "Installing to /Applications..."

    local APP_BUNDLE="${APP_NAME}.app"
    local INSTALL_PATH="$INSTALL_DIR/$APP_BUNDLE"

    # Check if already installed
    if [ -d "$INSTALL_PATH" ]; then
        print_warning "AI Text Agent is already installed"
        read -p "Do you want to replace it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled"
            exit 0
        fi

        # Kill running instance if exists
        killall -q "AITextAgent" 2>/dev/null || true
        rm -rf "$INSTALL_PATH"
    fi

    # Copy to Applications
    cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

    print_success "Installed to $INSTALL_PATH"
}

# Setup API key
setup_api_key() {
    echo ""
    print_status "API Key Setup"
    echo ""
    echo "AI Text Agent requires a Google Gemini API key to function."
    echo "You can get one at: https://aistudio.google.com/apikey"
    echo ""
    read -p "Do you want to configure the API key now? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your Gemini API key: " api_key

        if [ -n "$api_key" ]; then
            # Save to defaults
            defaults write "$BUNDLE_ID" gemini_api_key "$api_key"
            print_success "API key saved"
        else
            print_warning "API key not provided, you can set it later in Settings"
        fi
    else
        print_warning "You can set the API key later via the app's Settings menu"
    fi
}

# Launch app
launch_app() {
    echo ""
    read -p "Do you want to launch AI Text Agent now? (Y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        open "$INSTALL_DIR/${APP_NAME}.app"
        print_success "AI Text Agent launched!"
        echo ""
        print_status "Look for the brain icon (🧠) in your menu bar"
        print_status "Press ⌘⇧Space after copying text to translate it"
    fi
}

# Main installation flow
main() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║   AI Text Agent Installation Script      ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""

    print_status "Starting installation..."
    echo ""

    # Pre-installation checks
    check_macos
    check_macos_version
    check_swift

    echo ""

    # Download and build
    download_repo
    build_app
    create_app_bundle

    echo ""

    # Install
    install_app

    # Post-installation
    setup_api_key
    launch_app

    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║        Installation Complete! 🎉          ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    print_success "AI Text Agent is ready to use"
    echo ""
    echo "Quick start:"
    echo "  1. Copy any text (⌘C)"
    echo "  2. Press ⌘⇧Space"
    echo "  3. Translation appears in clipboard"
    echo ""
    echo "To configure settings:"
    echo "  Click the brain icon (🧠) in menu bar → Settings"
    echo ""
}

# Run main function
main
