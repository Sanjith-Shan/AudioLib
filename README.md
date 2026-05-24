# AudioLib

AudioLib started out of frustration. I listen to a lot of audiobooks, and Spotify caps you at **15 hours of audiobook listening per month** — which I'd burn through in a week or two, leaving me locked out of books I was in the middle of. Paying more or rationing my own listening felt ridiculous, so I went and built my own solution: a pair of apps that let me turn any YouTube audiobook into a real, downloaded book I own and can listen to offline, for as long as I want, on whichever device is in my hand.

It's two native apps that stay in sync — an **iPhone app** and a **macOS app** — for downloading audiobooks and listening to them offline.

---

## What it does

- **Download audiobooks from YouTube.** Paste a link and AudioLib pulls down the audio (and cover art, chapters, and metadata) as a local `.m4a` file.
- **Listen completely offline.** Everything is stored on-device. No streaming, no limits, no monthly cap.
- **Stay in sync across iPhone and Mac.** Your place in a book, your library, and your downloads sync between the two apps — start a chapter on your phone, pick it up at the same second on your Mac.
- **A real player.** Variable speed (0.75×–3×), skip intervals, sleep timer, bookmarks, and chapter navigation, with lock-screen / media-key controls.
- **Notes.** A rich-text editor (bold/italic/underline, headings, lists) with timestamps you can drop in while listening, optionally linked to a specific book.

## The two apps

**iPhone (iOS 17+)** — a three-tab app (Download · Library · Notes) with a Spotify-style full-screen player and a persistent mini-player.

**Mac (macOS 14+)** — a desktop-native workspace:
- A grouped **sidebar** (Library / Downloads / Notes / Series) with a Companion-mode status footer.
- A **library** as a cover grid or detail list, with a Continue-Listening hero and a right-hand **book inspector** (chapters, stats).
- A persistent **bottom player bar** plus an expanded **Now Playing** view, a floating **mini-player** window, and full keyboard shortcuts.
- A 5-tab **Preferences** window.

Both apps are built from one shared Swift codebase (SwiftUI + Core Data), with platform-specific UI behind `#if os(...)`.

## How sync works

Sync is **server-mediated**, not iCloud. The Mac runs a small **companion server**, and both apps talk to it:

- When you play, the current position is pushed to the server.
- On launch / foreground, each app pulls the shared state and merges it (last-write-wins by "last played").
- If a book exists on one device but its audio isn't downloaded on the other yet, that device re-downloads it automatically from the original source.

This means sync works whenever your iPhone can reach the Mac (same Wi-Fi out of the box, or anywhere if you expose the server). It needs no paid Apple Developer account and no iCloud entitlements — a good fit for a personal, sideloaded app.

## Requirements

- iPhone on **iOS 17+**, Mac on **macOS 14+**
- **Xcode 15+** to build
- An Apple ID (free is fine for sideloading; paid extends signing validity)
- [XcodeGen](https://github.com/yonsm/XcodeGen) to generate the project: `brew install xcodegen`

## Building

The Xcode project is generated from `project.yml`:

```bash
xcodegen generate
open AudioLib.xcodeproj
```

There are two schemes:

- **AudioLib** — the iOS app. Select your iPhone (or a simulator) and Run (⌘R). For sideloading, build an IPA with `./scripts/build_ipa.sh YOUR_TEAM_ID` and install via [AltStore](https://altstore.io), or run directly from Xcode after setting your signing team.
- **AudioLibMac** — the macOS app. Select "My Mac" and Run.

> Free Apple Developer accounts require re-signing the iOS app every 7 days (AltStore automates this). A paid account ($99/yr) gives year-long validity.

## Companion server

The server (in `CompanionServer/`) does two jobs: it can do the heavier YouTube downloading on your Mac (faster and more reliable than on-device for some videos), and it acts as the **sync hub** between the iPhone and Mac apps.

```bash
cd CompanionServer
pip install -r requirements.txt
python companion_server.py        # listens on :8787
```

Then point the apps at it under **Settings / Preferences → Companion**, entering the Mac's hostname or local IP. On-device extraction (via YouTubeKit) still works without the server for most videos; the server is recommended for reliability and required for cross-device sync.

## Project layout

```
AudioLib/
├── App/            App entry, delegates, root views
│   └── Mac/        macOS UI — Shell/ (window, sidebar, player bar), Views/, Support/
├── Features/       Shared feature screens — Download, Library, Player, Notes, Settings, Onboarding
├── Services/       Audio engine, downloads, YouTube resolvers, sync
├── Persistence/    Core Data model + entities
├── Theme/          Design tokens + reusable components
AudioLibMac/        macOS target Info.plist + entitlements
CompanionServer/    Python download + sync server
scripts/            IPA build helper
```

## Tech stack

SwiftUI · Core Data · AVFoundation · Swift Package Manager · [YouTubeKit](https://github.com/alexeichhorn/YouTubeKit) · XcodeGen · Python (companion server)
