#!/bin/bash
# Launcher used by launchd — finds Anaconda Python and starts the companion server.
PYTHON="/opt/anaconda3/bin/python3"
PIP="/opt/anaconda3/bin/pip"
DIR="$(cd "$(dirname "$0")" && pwd)"

# Keep yt-dlp current so n-sig decryption doesn't go stale
"$PIP" install -q -U yt-dlp flask 2>/dev/null

exec "$PYTHON" "$DIR/companion_server.py"
