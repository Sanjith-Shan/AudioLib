#!/bin/bash
# Installs the AudioLib companion server as a macOS launch agent.
# It will start automatically on login and restart if it crashes.
# Run once: bash scripts/install_companion_service.sh

set -e

PLIST_LABEL="com.sanjith.audiolib.companion"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)/CompanionServer"
LAUNCHER="$SCRIPT_DIR/run_server.sh"

chmod +x "$LAUNCHER"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${LAUNCHER}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>
    <key>StandardOutPath</key>
    <string>/tmp/audiolib_companion.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/audiolib_companion.log</string>
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
EOF

# Unload old version if running
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# Load and start now
launchctl load "$PLIST_PATH"

echo ""
echo "✓ AudioLib companion server installed as a login service."
echo "  It is running now and will auto-start on every login."
echo ""
echo "  Logs: tail -f /tmp/audiolib_companion.log"
echo "  Stop: launchctl unload ~/Library/LaunchAgents/${PLIST_LABEL}.plist"
echo "  Start: launchctl load ~/Library/LaunchAgents/${PLIST_LABEL}.plist"
echo ""

# Wait a moment and check it started
sleep 2
if curl -s http://localhost:8787/health | grep -q '"ok"'; then
    echo "  Server is up at http://localhost:8787"
else
    echo "  Server starting… check logs if it doesn't appear in ~10 seconds."
fi
