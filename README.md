# AudioLib 🔊📚

A native iOS app for downloading YouTube audiobooks and listening to them offline.

## Features

- **Download** any YouTube audiobook by pasting its URL
- **Offline playback** — all audio stored locally on device
- **Spotify-style player** — scrubber, speed control (0.75x–3x), sleep timer, bookmarks, chapters
- **Library** — scrollable book list with cover art, progress tracking, series info
- **Notes** — rich text editor with bold, italic, underline, headings, and lists
- **Background playback** — continues playing when you lock the screen

## Requirements

- iPhone running iOS 17+
- Mac with Xcode (for building/sideloading)
- Free or paid Apple Developer account

## Installation (Sideload)

### Option 1: AltStore (recommended, refreshes automatically)
1. Install [AltStore](https://altstore.io) on your Mac and iPhone
2. Build the IPA: `./scripts/build_ipa.sh YOUR_TEAM_ID`
3. In AltStore on iPhone, tap `+` and select `build/AudioLib.ipa`

### Option 2: Xcode Direct Install
1. Open `AudioLib.xcodeproj` in Xcode
2. Set your Apple ID in Signing & Capabilities
3. Connect iPhone, select it as the run destination
4. Press Run (⌘R)

### Finding Your Team ID
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Your Team ID is listed under Membership Details

> **Note:** Free Apple Developer accounts require re-signing every 7 days. AltStore handles this automatically. A paid account ($99/year) provides 1-year validity.

## Optional: Companion Server (for better YouTube compatibility)

The app works without a server using YouTubeKit (on-device extraction). For videos with only Opus audio streams (~5% of YouTube), a companion server is needed.

```bash
cd CompanionServer
pip install -r requirements.txt
python companion_server.py
```

Then in the app: **Settings → Audio Source → Companion Server**, enter your Mac's local IP address.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full technical design.
