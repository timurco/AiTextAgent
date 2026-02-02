# Creating a Release

This guide explains how to create a new release with automatic binary builds.

## How it Works

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically:
1. Builds the app on macOS runner
2. Creates `.app` bundle
3. Packages as `AI-Text-Agent.zip`
4. Creates GitHub Release with the binary
5. Generates SHA-256 checksums

Users can then install without needing Swift/Xcode!

## Creating a Release

### Step 1: Update Version (Optional)

Update version number in relevant files if needed (currently no version file).

### Step 2: Create and Push Tag

```bash
# Create a new tag (use semantic versioning: v1.0.0, v1.1.0, etc.)
git tag v1.0.0

# Push the tag to GitHub
git push origin v1.0.0
```

### Step 3: GitHub Actions Builds Automatically

Once you push the tag:
1. GitHub Actions workflow starts automatically
2. Builds the app on `macos-13` runner
3. Creates `.app` bundle
4. Zips the bundle
5. Creates a new GitHub Release
6. Attaches `AI-Text-Agent.zip` and `checksums.txt`

### Step 4: Release is Published

The release will be available at:
```
https://github.com/timurco/AiTextAgent/releases/latest
```

Users can now install with:
```bash
curl -fsSL https://raw.githubusercontent.com/timurco/AiTextAgent/main/install.sh | bash
```

The install script will automatically download the pre-built binary (no compilation needed).

## Manual Trigger

You can also manually trigger the workflow:

1. Go to: https://github.com/timurco/AiTextAgent/actions
2. Click "Build and Release"
3. Click "Run workflow"
4. Select branch and run

## Verifying the Release

After creating a release:

```bash
# Download and verify checksum
curl -fsSL https://github.com/timurco/AiTextAgent/releases/latest/download/AI-Text-Agent.zip -o AI-Text-Agent.zip
curl -fsSL https://github.com/timurco/AiTextAgent/releases/latest/download/checksums.txt -o checksums.txt

# Verify
shasum -c checksums.txt
```

## Install Script Behavior

The updated `install.sh` script:

1. **Tries pre-built first**: Checks for latest release on GitHub
   - If found: Downloads `AI-Text-Agent.zip` (fast, no Swift needed)
   - If not found: Falls back to building from source

2. **Fallback to source**: If no release exists
   - Clones repository
   - Checks for Swift
   - Builds from source
   - Creates `.app` bundle

This means:
- ✅ Users **without Swift/Xcode** can install (via pre-built release)
- ✅ Developers can still build from source
- ✅ Always works (fallback mechanism)

## Release Checklist

Before creating a release:

- [ ] Test the app locally
- [ ] Update README if needed
- [ ] Commit and push all changes
- [ ] Create and push version tag
- [ ] Wait for GitHub Actions to complete
- [ ] Verify release appears on GitHub
- [ ] Test installation script with new release

## Example Release Commands

```bash
# Make sure you're on main branch and up to date
git checkout main
git pull

# Create annotated tag with message
git tag -a v1.0.0 -m "Release v1.0.0: Initial public release"

# Push tag to trigger build
git push origin v1.0.0

# Check build status
# Visit: https://github.com/timurco/AiTextAgent/actions
```

## Troubleshooting

### Build fails on GitHub Actions

- Check the Actions log: https://github.com/timurco/AiTextAgent/actions
- Ensure `build_app.sh` works locally first
- Verify `Info.plist` exists in `Sources/AITextAgent/`

### Release not created

- Ensure tag starts with `v` (e.g., `v1.0.0`, not `1.0.0`)
- Check that tag was pushed: `git ls-remote --tags origin`
- Verify workflow file syntax is valid

### Install script doesn't find release

- Make sure release is published (not draft)
- Check release asset name is exactly `AI-Text-Agent.zip`
- API rate limits: GitHub API has rate limits for unauthenticated requests

## Future Enhancements

Consider adding:

- **Code signing**: Sign the app with Apple Developer certificate
- **Notarization**: Notarize the app for Gatekeeper compatibility
- **Version numbers**: Add version info to the app
- **Auto-updates**: Implement Sparkle framework for auto-updates
- **DMG packaging**: Create DMG instead of ZIP for better UX
