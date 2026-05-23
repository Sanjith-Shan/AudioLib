#!/usr/bin/env bash
set -euo pipefail

# AudioLib IPA builder
# Usage: ./scripts/build_ipa.sh [TEAM_ID]
# Example: ./scripts/build_ipa.sh A1B2C3D4E5
#
# Requirements:
#   - Xcode installed
#   - Apple Developer account (free or paid)
#   - Run once with your Team ID to sign the build

TEAM_ID="${1:-}"
PROJECT="AudioLib.xcodeproj"
SCHEME="AudioLib"
ARCHIVE_PATH="build/AudioLib.xcarchive"
IPA_PATH="build/AudioLib.ipa"
EXPORT_OPTIONS="scripts/ExportOptions.plist"

if [ -z "$TEAM_ID" ]; then
    echo "Usage: ./scripts/build_ipa.sh YOUR_TEAM_ID"
    echo "Find your Team ID at https://developer.apple.com/account"
    exit 1
fi

# Ensure Xcode (not just Command Line Tools) is the active developer directory
if ! xcodebuild -version &>/dev/null 2>&1; then
    XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
    if [ -d "$XCODE_DEV" ]; then
        echo "Switching xcode-select to Xcode.app (requires sudo)..."
        sudo xcode-select -s "$XCODE_DEV"
    else
        echo "Error: Xcode.app not found. Install Xcode from the App Store."
        exit 1
    fi
fi

# Use xcpretty if available, otherwise plain output
if command -v xcpretty &>/dev/null; then
    PIPE="xcpretty"
else
    PIPE="cat"
fi

mkdir -p build

echo "Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE="Automatic" \
    | $PIPE

echo "Packaging IPA from archive..."
APP_PATH=$(find "$ARCHIVE_PATH/Products/Applications" -name "*.app" | head -1)
if [ -z "$APP_PATH" ]; then
    echo "Error: No .app found in archive"
    exit 1
fi
PAYLOAD_DIR="build/Payload"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"
(cd build && zip -qr AudioLib.ipa Payload)
rm -rf "$PAYLOAD_DIR"

if [ -f "build/AudioLib.ipa" ]; then
    echo ""
    echo "IPA built: build/AudioLib.ipa"
    echo ""
    echo "To install:"
    echo "  1. AltStore: Open AltStore on iPhone, tap +, choose the .ipa file"
    echo "  2. Xcode: Window > Devices and Simulators > Install App"
    echo "  3. 3uTools or AltDeploy on Mac"
else
    echo "IPA not found — check build logs above"
    exit 1
fi
