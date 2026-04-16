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

mkdir -p build

echo "Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE="Automatic" \
    | xcpretty || true

# Generate export options
cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

echo "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "build/" \
    | xcpretty || true

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
