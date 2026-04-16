# AudioLib Architecture Plan

## System Overview

AudioLib is a native SwiftUI iOS app (iOS 16+) for sideloaded distribution that turns YouTube audiobooks into a local, offline-first listening library. The app is organized around a three-tab structure (Download / Library / Notes) with a Spotify-style now-playing screen accessible from the Library.

Because Apple forbids bundling `yt-dlp` or any Python interpreter in a submitted app, and even for sideloaded apps iOS's sandbox blocks process forking (`fork`/`exec`/`posix_spawn` of arbitrary binaries outside the app bundle's signed Mach-O), we adopt a **hybrid architecture**:

- **Primary path (recommended): Companion server.** A tiny FastAPI/Flask (Python) or Express (Node) server runs on the user's Mac/Raspberry Pi/home server, wrapping `yt-dlp` + `ffmpeg`. The iOS app POSTs a YouTube URL, the server downloads + remuxes to best-quality `.m4a`, and the app pulls the result via a single HTTPS download with resume support. Metadata (title, uploader, thumbnail, duration, chapters) is returned as JSON.
- **Fallback path (pure on-device): `YouTubeKit` / `XCDYouTubeKit`.** A Swift library that parses YouTube's player response and returns direct CDN URLs for audio streams. Works fully offline from the server, at the cost of being more fragile (YouTube changes breaking it occasionally). We ship this as the default so the app works out-of-the-box; a toggle in Settings lets power users point at their own companion server for reliability.

Persistence uses **Core Data** (metadata, notes, bookmarks, progress) + the **Documents directory** (audio files, cover images). Playback is handled by `AVAudioPlayer` wrapped in an `@Observable` `PlayerController` with `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` for lock-screen and CarPlay controls.

---

## Technical Decisions (with rationale)

| Decision | Choice | Rationale |
|---|---|---|
| UI framework | SwiftUI (iOS 17+) with `NavigationStack`, `TabView` | Modern, matches requirement, good enough for this UI surface. UIKit only used for `UITextView`-backed rich editor. |
| YouTube extraction | **YouTubeKit** (on-device) primary + optional companion server | Pure on-device means zero setup. `yt-dlp` binary cannot be `exec`'d under iOS sandbox even sideloaded. |
| Audio download | `URLSession` background download tasks | Native resume + background transfer + progress callbacks. |
| Audio format | **`.m4a` (AAC)** | YouTube's native audio track is Opus or AAC; AAC (itag 140) is directly playable by `AVAudioPlayer` with no transcoding. |
| Transcoding on-device | **None** | Grab AAC stream directly (itag 140 / 139 / 258). If only Opus is available, fall back to companion server. No on-device ffmpeg. |
| Cover art | YouTube thumbnail (`maxresdefault.jpg`), downloaded alongside audio, cached to disk | Simple, free, no extra API. |
| Metadata store | **Core Data** | Queryable, relationships (Book → Bookmarks, Book → Chapters), migration story, plays well with SwiftUI via `@FetchRequest`. |
| File storage | `FileManager.default.urls(for: .documentDirectory)` with subdirs: `/audio/<uuid>.m4a`, `/art/<uuid>.jpg` | Backed up to iCloud by default (user can opt out). UUID filenames avoid collisions. |
| Audio playback | `AVAudioPlayer` (not `AVPlayer`) | Local file playback, simpler rate control, better scrubbing accuracy. |
| Background audio | `AVAudioSession` category `.playback` + `UIBackgroundModes: audio` in Info.plist | Standard iOS background audio. |
| Rich text editor | `UITextView` wrapped in `UIViewRepresentable` with `NSAttributedString` persistence | SwiftUI's `TextEditor` has no attributed-string support on iOS 16/17. |
| Dependency management | Swift Package Manager (SPM) only | No CocoaPods, no Carthage. |
| Navigation | `TabView` root + `NavigationStack` per tab + `.sheet` for now-playing | Now-playing as a sheet that slides up Spotify-style; can be minimized to a "mini-player" above the tab bar. |
| Design tokens | A single `Theme.swift` with static colors/fonts/metrics | Centralized; easy to enforce the Revolut-inspired flat, pill-shaped system. |

---

## Data Models

### Core Data entities (`AudioLib.xcdatamodeld`)

```swift
// Book: a downloaded audiobook
@objc(Book)
public class Book: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String?           // YouTube uploader / channel
    @NSManaged public var series: String?           // user-editable
    @NSManaged public var seriesIndex: Int16        // e.g., book 3 of N, 0 if unset
    @NSManaged public var durationSeconds: Double
    @NSManaged public var progressSeconds: Double   // last playback position
    @NSManaged public var sourceURL: String         // original YouTube URL
    @NSManaged public var audioFilename: String     // "<uuid>.m4a" in /audio/
    @NSManaged public var artFilename: String?      // "<uuid>.jpg" in /art/
    @NSManaged public var dateAdded: Date
    @NSManaged public var lastPlayedAt: Date?
    @NSManaged public var playbackRate: Float       // per-book rate memory, default 1.0
    @NSManaged public var bookmarks: NSSet          // -> Bookmark
    @NSManaged public var chapters: NSSet           // -> Chapter
}

@objc(Bookmark)
public class Bookmark: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timeSeconds: Double
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var book: Book
}

@objc(Chapter)
public class Chapter: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var startSeconds: Double
    @NSManaged public var endSeconds: Double
    @NSManaged public var book: Book
}

@objc(NoteDoc)
public class NoteDoc: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var rtfData: Data              // NSAttributedString serialized as RTF
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var linkedBookID: UUID?        // optional: note tied to a book
}

@objc(DownloadJob)
public class DownloadJob: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var sourceURL: String
    @NSManaged public var state: String              // "queued"|"fetching-metadata"|"downloading"|"finalizing"|"done"|"failed"
    @NSManaged public var progress: Double           // 0.0–1.0
    @NSManaged public var errorMessage: String?
    @NSManaged public var resultingBookID: UUID?
    @NSManaged public var createdAt: Date
}
```

---

## Phases

### Phase 1: Project Scaffold & Design System
- Xcode project `AudioLib` (iOS 17.0+, SwiftUI lifecycle)
- `Theme/` design system (colors, fonts, typographic styles, reusable components)
- Root `ContentView` with `TabView` → Download / Library / Notes
- Core Data stack (`PersistenceController`)
- Info.plist entries for background audio, etc.

### Phase 2: YouTube Metadata & Audio Extraction Layer
- `YouTubeResolver` protocol with `OnDeviceYouTubeResolver` (YouTubeKit SPM) and `CompanionServerResolver`
- Chapter extraction from video description
- Thumbnail URL derivation

### Phase 3: Download Engine
- `DownloadManager` with background `URLSession`
- `DownloadTabView` with paste field, progress bars
- `FileStore` helper
- AppDelegate background session handler

### Phase 4: Library & Book Detail
- `LibraryTabView` with scrollable list
- `LibraryRow` (cover art + metadata + play button)
- `MiniPlayer` above tab bar
- `BookEditSheet` for metadata editing

### Phase 5: Spotify-Style Player
- `PlayerController` wrapping `AVAudioPlayer`
- `PlayerView` full-screen sheet
- Scrubber, speed sheet, sleep timer, bookmarks, chapters
- `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`

### Phase 6: Notes (Rich Text Editor)
- `NotesTabView` with note list
- `NoteEditorView` with `UITextView`-backed rich editor
- Bold/italic/underline/lists/headings toolbar
- RTF persistence in Core Data

### Phase 7: Polish, Edge Cases, Settings
- `SettingsView` (resolver mode, companion host, defaults)
- Local notifications for download completion
- Error toasts, iCloud backup opt-out, file import

### Phase 8: Testing & Sideload Packaging
- Unit tests for core services
- `scripts/build_ipa.sh`
- README with sideload instructions

---

## Complete File Structure

```
AudioLib/
├── AudioLib.xcodeproj
├── AudioLib/
│   ├── App/
│   │   ├── AudioLibApp.swift
│   │   ├── AppDelegate.swift
│   │   └── ContentView.swift
│   ├── Theme/
│   │   ├── Theme.swift
│   │   ├── Color+Hex.swift
│   │   ├── Font+Theme.swift
│   │   └── Components/
│   │       ├── PillButton.swift
│   │       ├── Card.swift
│   │       ├── FlatTextField.swift
│   │       └── EmptyStateView.swift
│   ├── Persistence/
│   │   ├── PersistenceController.swift
│   │   ├── AudioLib.xcdatamodeld/
│   │   └── CoreData+Extensions.swift
│   ├── Services/
│   │   ├── YouTube/
│   │   │   ├── YouTubeResolver.swift
│   │   │   ├── OnDeviceYouTubeResolver.swift
│   │   │   ├── CompanionServerResolver.swift
│   │   │   ├── YouTubeResolverFactory.swift
│   │   │   └── ChapterParser.swift
│   │   ├── Download/
│   │   │   ├── DownloadManager.swift
│   │   │   ├── FileStore.swift
│   │   │   └── DownloadJobStore.swift
│   │   ├── Audio/
│   │   │   ├── AudioSessionManager.swift
│   │   │   ├── NowPlayingInfoCenter.swift
│   │   │   └── RemoteCommandCenter.swift
│   │   ├── ImageCache.swift
│   │   ├── AppRouter.swift
│   │   ├── LocalNotifications.swift
│   │   ├── StorageUsageCalculator.swift
│   │   ├── FileImporter.swift
│   │   └── DurationFormatter.swift
│   ├── Features/
│   │   ├── Download/
│   │   │   ├── DownloadTabView.swift
│   │   │   ├── DownloadRow.swift
│   │   │   └── PasteURLCard.swift
│   │   ├── Library/
│   │   │   ├── LibraryTabView.swift
│   │   │   ├── LibraryRow.swift
│   │   │   ├── LibraryHeader.swift
│   │   │   ├── BookEditSheet.swift
│   │   │   └── MiniPlayer.swift
│   │   ├── Player/
│   │   │   ├── PlayerController.swift
│   │   │   ├── PlayerView.swift
│   │   │   ├── ScrubberView.swift
│   │   │   ├── PlayerControlsRow.swift
│   │   │   ├── PlayerSecondaryRow.swift
│   │   │   ├── SpeedSheet.swift
│   │   │   ├── SleepTimerSheet.swift
│   │   │   ├── BookmarksSheet.swift
│   │   │   └── ChaptersSheet.swift
│   │   ├── Notes/
│   │   │   ├── NotesTabView.swift
│   │   │   ├── NoteEditorView.swift
│   │   │   ├── RichTextEditor.swift
│   │   │   ├── FormattingToolbar.swift
│   │   │   ├── NoteRow.swift
│   │   │   └── NoteStore.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── OnboardingSheet.swift
│   ├── Fonts/
│   │   ├── Inter-Regular.ttf
│   │   ├── Inter-SemiBold.ttf
│   │   ├── Inter-Bold.ttf
│   │   └── AeonikPro-Medium.otf
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── Info.plist
├── AudioLibTests/
│   ├── ChapterParserTests.swift
│   ├── DurationFormatterTests.swift
│   ├── FileStoreTests.swift
│   └── ResolverMockTests.swift
├── AudioLibUITests/
│   └── DownloadToLibraryFlowTests.swift
├── CompanionServer/
│   ├── companion_server.py
│   ├── requirements.txt
│   └── README.md
├── scripts/
│   └── build_ipa.sh
├── DESIGN.md
├── ARCHITECTURE.md
└── README.md
```

---

## Critical Notes for Implementation Agents

1. **Phase order is strict.** Don't start Phase 5 (player) before Phase 4 (library). Don't start Phase 3 (downloads) before Phase 2 (resolver). Phase 6 (notes) can run in parallel with other phases.

2. **No yt-dlp binary in app.** iOS sandbox blocks `exec` of arbitrary Mach-O. Use `YouTubeKit` (Swift SPM library) as primary on-device extractor.

3. **Core Data concurrency.** Background URLSession delegates run off main thread. Always use `persistentContainer.performBackgroundTask` for writes. Pass `NSManagedObjectID`, not `NSManagedObject`, across threads.

4. **Audio session before player.** `AudioSessionManager.shared.activate()` must run before creating any `AVAudioPlayer`. Do it in `AudioLibApp.init()`.

5. **No shadows. No emojis. All pill buttons.** Enforced globally via `Theme.swift`. No `.shadow()` modifiers anywhere.

6. **Stream URL expiry.** YouTube audio CDN URLs expire in ~6 hours. Catch 403/410, re-resolve once, then retry.

7. **iOS 17 target.** Use `@Observable` (not `ObservableObject`). Minimum deployment: iOS 17.0.

8. **No on-device transcoding.** If video has no AAC stream (Opus only), surface error with "Try companion server" CTA.

9. **UUID-based filenames.** Never use user-provided titles in filenames. Always `<bookID>.m4a` and `<bookID>.jpg`.

10. **Progress writes debounced.** Write `book.progressSeconds` every 5 seconds during playback and immediately on pause/seek. Never write every tick.

11. **Mini-player is a ZStack sibling** of `TabView` at `ContentView` level, not a child of any tab.

12. **Rich text uses UITextView.** SwiftUI's `TextEditor` does not support attributed strings on iOS 17.

13. **Design tokens in one place.** `Theme.swift` only. No raw hex colors in view files.
