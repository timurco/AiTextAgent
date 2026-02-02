#!/bin/bash

# Build script for AITextAgent macOS application
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="AI Text Agent"
BUNDLE_ID="com.timurko.AITextAgent"
EXECUTABLE_NAME="AITextAgent"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo -e "${GREEN}🚀 Building ${APP_NAME}...${NC}"

# Clean previous builds
if [ -d "$APP_BUNDLE" ]; then
    echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
    rm -rf "$APP_BUNDLE"
fi

# Build the Swift package in release mode
echo -e "${GREEN}📦 Compiling Swift package...${NC}"
swift build -c release

# Check if build succeeded
if [ ! -f "${BUILD_DIR}/${EXECUTABLE_NAME}" ]; then
    echo -e "${RED}❌ Build failed: executable not found${NC}"
    exit 1
fi

# Create app bundle structure
echo -e "${GREEN}📂 Creating app bundle structure...${NC}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
echo -e "${GREEN}📋 Copying executable...${NC}"
cp "${BUILD_DIR}/${EXECUTABLE_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist
echo -e "${GREEN}📋 Copying Info.plist...${NC}"
cp "Sources/AITextAgent/Info.plist" "${APP_BUNDLE}/Contents/"

# Create PkgInfo file
echo -e "${GREEN}📝 Creating PkgInfo...${NC}"
echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Make executable executable
chmod +x "${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE_NAME}"

# Optional: Code signing (if you have a developer certificate)
# Uncomment the following lines and replace with your identity
# echo -e "${GREEN}✍️  Code signing...${NC}"
# codesign --force --deep --sign "Developer ID Application: Your Name" "${APP_BUNDLE}"

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${GREEN}📍 Application bundle created: ${APP_BUNDLE}${NC}"
echo ""
echo -e "${YELLOW}To install:${NC}"
echo -e "  1. Copy ${APP_BUNDLE} to /Applications/"
echo -e "  2. Run: cp -r '${APP_BUNDLE}' /Applications/"
echo ""
echo -e "${YELLOW}To run:${NC}"
echo -e "  open '${APP_BUNDLE}'"
echo ""
echo -e "${YELLOW}⚠️  Note:${NC} For Launch at Login to work, the app must be:"
echo -e "  1. Located in /Applications/"
echo -e "  2. Code-signed (optional for testing, required for distribution)"
