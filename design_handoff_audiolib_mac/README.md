# Handoff: AudioLib for Mac

## Overview

AudioLib for Mac is the desktop companion to the AudioLib iOS app. Same app concept — paste a YouTube link, turn it into an audiobook in a personal library, listen with bookmarks/chapters/notes — but tailored for macOS:

- **Three-column workspace** (source list → content → inspector) instead of stacked iOS tabs
- **Persistent bottom player bar** always visible (Apple Music pattern)
- **Companion mode** — the Mac doubles as the iOS app's download backend over LAN
- **Expanded Now-Playing view** when the user wants immersive listening
- **Mini-player floating window** + **menu bar extra** for background listening
- **Continuity** — progress/bookmarks/notes sync to the iPhone via iCloud

This handoff covers the **complete visual design** for every macOS screen and window:

- Onboarding window
- Library — Grid view, List view, Empty state
- Library — Book inspector (right rail with chapters)
- Downloads
- Notes — two-pane editor
- Player — Now-Playing expanded view
- Preferences window
- Floating Mini Player
- Menu bar extra

## About the Design Files

The files in this bundle are **design references created in HTML/React** — prototypes showing intended look and behavior, **not production code to copy directly**.

The task is to **recreate these designs in the target macOS codebase using SwiftUI** (with selected AppKit/NSWindow scaffolding for the things SwiftUI doesn't yet cover well — mini-player always-on-top, NSMenu-style menu bar extra, custom window chrome). Follow Apple's macOS Human Interface Guidelines and the codebase's existing patterns where applicable. The HTML/CSS values below (colors, font sizes, paddings) translate directly to SwiftUI modifiers — the visual targets are the source of truth, not the React JSX.

## Fidelity

**High-fidelity.** Colors, typography, layout, density and interactions are all final. Where native macOS controls (NSPopUpButton, NSSegmentedControl, .sheet, NSTableView, .toolbar, NSMenu, NSStatusItem) are appropriate, **use the natives** instead of hand-rolling — they'll feel more correct than the design prototype suggests.

The brand-specific things to preserve carefully:
- **Warm-paper background tone** across all primary windows
- **Georgia serif** for book titles, view titles, headlines
- **Teal accent** as the only accent color
- **Dark "ink" player bar** at the bottom (not the system materials)
- **Deep-blue gradient** in the expanded Now-Playing view

---

## Visual Direction

All tokens inherit from the iOS app — same warm-paper palette, same Georgia serif, same teal accent. Mac adjustments:

- **Denser type** (12.5pt sidebar, 13pt rows) — Mac users sit further away and tolerate more density
- **Tighter controls** — 28pt toolbar buttons, 24pt secondary buttons
- **Glass sidebar** with translucent warm-paper tint over the desktop wallpaper, traffic lights tucked into the sidebar's top-left
- **Dark ink player bar** spans full width across the bottom of the main window — always visible whenever a book is loaded
- **Expanded Now-Playing view** uses the same blue-black gradient as iOS for visual continuity

---

## Design Tokens

Same as iOS — see `iOS handoff` for the full list. Mac-specific additions:

```
// Sidebar glass
sidebar-bg          rgba(232, 226, 212, 0.62)  + backdrop-filter blur 40 saturate 180%

// Toolbar (per-view)
toolbar-bg          rgba(241, 236, 226, 0.7)   + backdrop-filter blur 20
toolbar-hairline    rgba(27, 24, 20, 0.08)     0.5px bottom

// Inspector rail
inspector-bg        rgba(255, 255, 255, 0.55)  + backdrop-filter blur 20

// Player bar
player-bar-bg       rgba(27, 24, 20, 0.97)     + backdrop-filter blur 40
player-bar-hairline rgba(27, 24, 20, 0.4)      0.5px top

// Window
window-radius       14
window-shadow       0 0 0 0.5px rgba(0,0,0,0.22), 0 24px 60px rgba(0,0,0,0.30)
preferences-radius  12
preferences-shadow  0 0 0 0.5px rgba(0,0,0,0.22), 0 18px 48px rgba(0,0,0,0.30)
mini-radius         14
mini-shadow         0 0 0 0.5px rgba(0,0,0,0.4),  0 16px 40px rgba(0,0,0,0.5)
```

**Window default sizes** (all resizable except where noted):

| Window         | Default      | Min          | Notes |
|----------------|--------------|--------------|-------|
| Main           | 1280 × 820   | 1080 × 680   | Sidebar collapsible, content + inspector flex |
| Preferences    | 720 × 540    | fixed        | Modal sheet over main, or floating panel |
| Mini Player    | 360 × 100    | fixed        | Floating, always-on-top, draggable from anywhere |
| Menu Bar Extra | 320 × auto   | fixed width  | NSStatusItem popover |
| Onboarding     | 800 × 560    | fixed        | Shown once, no traffic lights for minimize/maximize |

### Traffic light handling

In the main window, traffic lights sit **inside the sidebar's top-left**, ~14pt from the left edge, 12pt from the top. Use the standard 12pt circle size. The toolbar starts to the right of the sidebar — keep the standard close/minimize/maximize behavior.

In the **expanded Now-Playing view**, the traffic lights sit on the dark gradient — use light variants (the standard ones work fine on dark backgrounds).

In the **mini-player**, use smaller 9pt traffic lights in the top-left.

---

## Typography Scale (Mac)

```
- View title (toolbar)           Georgia    18 / 700 / -0.3
- View subtitle (toolbar)        SF Pro     11.5 / regular / 62% ink
- Hero title (Continue Listening) Georgia   28 / 700 / -0.5
- Note editor title              Georgia    32 / 700 / -0.5
- Book title (inspector)         Georgia    22 / 700 / -0.4
- Now-Playing title              Georgia    32 / 700 / -0.6
- Sidebar section header         SF Pro     10.5 / 700 / +0.8 / uppercase / ink-mute
- Sidebar item                   SF Pro     12.5 / 500 / -0.1
- Row title                      SF Pro     13 / 600 / -0.2
- Row secondary                  SF Pro     11.5 / regular / 62%
- Body                           SF Pro     15.5 / regular / -0.05 / 1.65 leading (note body)
- Caption / meta                 SF Pro     10.5–11 / 600 / +0.5 / uppercase / ink-mute
- Mono tabular                   SF Mono    10.5–13 / tabular-nums (timestamps)
```

---

## Window Architecture

The main window has three columns + a bottom bar:

```
┌─────────────────────────────────────────────────────────────────────┐
│ ╭───────╮│ Toolbar (50pt, view title + actions)                 │   │
│ │       ││─────────────────────────────────────────────────────│   │
│ │       ││                                                     │ I │
│ │ Side- ││                                                     │ n │
│ │ bar   ││            Main content (Library / Downloads /      │ s │
│ │ 232pt ││            Notes / etc)                             │ p │
│ │       ││                                                     │ . │
│ │       ││                                                     │   │
│ │       ││                                                     │ 340│
│ ╰───────╯│                                                     │ pt│
├─────────────────────────────────────────────────────────────────────┤
│ ░░ Player bar (78pt, dark, full width)                              │
└─────────────────────────────────────────────────────────────────────┘
```

- Sidebar is collapsible (View → Hide Sidebar, ⌘⌃S)
- Inspector is collapsible (View → Hide Inspector, ⌘⌃I) — only shown in Library
- Player bar appears whenever a book is loaded; hides when nothing has been opened

---

## Screen Specs

### 1. Sidebar (source list)

**Structure** — a single scroll view inside a translucent panel.

- Top (38pt): traffic lights, left-aligned, 14pt gutter
- App branding (6/16/8pt padding): 26pt teal app icon (mini version of the iOS launcher) + "AudioLib" in Georgia 17/700/-0.3
- Source groups (each preceded by an `MSidebarHeader`):
  - **LIBRARY**
    - All Books (count)
    - Continue Listening (count)
    - Recently Added (count)
    - Finished (count)
  - **DOWNLOADS**
    - Active (count)
    - Completed (count)
  - **NOTES**
    - All Notes (count)
    - Linked to Books (count)
  - **SERIES** — one row per series in the user's library (e.g. "Dune", "Remembrance of Earth's Past")
- Footer card (10pt padding, top hairline divider):
  - Companion mode badge — 7pt teal dot w/ glow + label "Companion mode" + mono sub "mac-mini.local:8080 · 2 connected"
  - Preferences… link with gear icon

**Sidebar item state:**
- Inactive: transparent bg, ink text, ink-soft icon
- Active: teal-soft bg (`rgba(30, 144, 133, 0.13)`), teal-ink text, teal icon
- Hover: white-30 bg
- Row 22pt tall, 5/10/5/10 padding, 6pt corner radius, 8pt margins

---

### 2. Toolbar (per view)

Per-view top bar (50pt tall, paper-70% background with blur, 0.5pt hairline bottom):

- Left: view title (Georgia 18/700) + small 11.5pt subtitle below
- Right: 1–4 trailing actions
  - `MIconButton` — 28pt tall, optional label
    - Primary variant: ink bg, paper fg ("New Note", "Resume")
    - Default: white-60 bg, ink fg
    - Active (toggled): teal-soft bg, teal-ink fg
  - `MSegmented` — 2-segment view toggle (Grid / List) in standard macOS segmented-control style

---

### 3. Library — Grid View (default)

Two sub-sections inside the scroll area:

**3a. Continue Listening hero strip** (top of scroll):
- 14pt radius card, 22pt padding
- Background: `linear-gradient(135deg, #11332E 0%, #1B5751 100%)`
- Box-shadow: `0 4px 20px rgba(17, 51, 46, 0.18)`
- Left: 132pt cover at radius 10
- Center column:
  - "CONTINUE LISTENING" eyebrow (10.5/700/+1.2 / uppercase / 55% paper)
  - Title — Georgia 28/700/-0.5
  - Author — 14 / 70%
  - 14pt gap, then two buttons:
    - **Resume · 3h 47m left** — paper bg, ink fg, 10pt radius, 8/18 padding, `whiteSpace: nowrap`
    - **Open** — outlined ghost button (transparent bg, 0.5pt paper-25 border, paper text)
- Right column (min-width 160, flex column, align-end):
  - "Chapter 4 · The Man Who…" — 11 / 60%
  - 180pt-wide progress bar
  - "2:14:08 / 5:58:12" timestamps

**3b. "All Books" header** (Georgia 20/700/-0.3) + sort label on the right

**3c. Grid** — `repeat(auto-fill, minmax(132px, 1fr))` with 22pt gap.

Each card (`MBookCard`):
- 132pt-wide cover (or 168pt in "big" variant)
- Title — 13/600/-0.2, 2-line clamp
- Author — 11.5/62%
- "3h 47m left" caption — 10.5 / 38% / mono tabular (only for in-progress)
- **Hover state:** 35% black overlay + 44pt paper play button in center (use SwiftUI `.onHover { hovering in ... }`)
- **In-progress:** 3pt paper bar inset 6pt on the cover bottom edge (over a 45% black track), showing % progress
- **Finished:** 20pt teal circle with white check, inset 6pt from top-right corner
- **Right-click context menu:** Play · Open in Inspector · Edit Info · Show in Finder · Delete

---

### 4. Library — List View

Standard table layout, sticky header.

Columns: `40 / 2.4fr / 1.6fr / 0.8fr / 1.3fr / 1.4fr` (cover · title · author · duration · progress · last played)

- Header row 10.5/700/+0.5/uppercase/ink-mute, paper-94% sticky background
- Rows 10/24 padding, 0.5pt hairline below
- Selected row: teal-soft tint (`rgba(30,144,133,0.07)`)
- Cover thumb 32×32, radius 4
- Progress: 3pt bar + right-aligned "62%" label in mono tabular
- "Last played" relative ("Just now", "2h ago", "Yesterday", "Sep 12", "Never")
- **Sortable columns** — click header to sort (use standard NSTableView sort indicators)

---

### 5. Library — Empty State

Centered card-soft 120pt circle with books icon, Georgia 28 "Your library is empty", 14pt body copy max-width 360pt, then two buttons side-by-side:
- **Download a book** — primary ink button
- **Import audio files…** — ghost button (for sideloading .m4a/.mp3)

---

### 6. Book Inspector (right rail, Library only)

340pt-wide column, white-55% bg with blur, 0.5pt left hairline.

- 180pt cover, centered
- 22pt Georgia title, 14pt author
- Action row: **Resume · 3h 47m** primary button (flex 1) + bookmark icon button + ••• overflow button (both 36×36, ink-06 bg, 10pt radius)
- Stats grid — 3 columns × { value 13/700, label 10/uppercase/+0.4/600 }: Duration / Progress / Speed
- "CHAPTERS" header — 11/700/+0.5/uppercase
- Chapter list — 8/10 row padding, 7pt radius, active row teal-soft tint
  - Chapter number or speaker icon (when active) — 18pt slot, 13/600 mono
  - Title (12.5, 600 if active)
  - Start time (10.5, mono tabular, right-aligned)

---

### 7. Downloads

**Toolbar:** title "Downloads" + subtitle "3 active · 1 failed · 12 completed" + Sort button (right)

**Add card** (top of scroll, 14pt radius, ink bg, paper fg, 20pt padding):
- 44pt rounded white-10 icon (link icon)
- Column: "Add an audiobook from YouTube" + monospace URL input (white-08 bg, 9pt radius, 9/12 padding)
- **Download** button (paper bg, ink fg) on the right

**Active section** — white card, rows separated by hairlines:
- 32pt leading icon (state-dependent: spinner / down-arrow / wifi-x for failed)
- Title (13.5/600) + state line (11.5/62%, red if failed)
- 140pt progress bar with % + source label below ("On-device · m4a" / "Companion")
- Optional "Listen" pill (teal-soft) if `canStreamPartial`
- "Retry" button for failed
- 22pt × icon for cancel

**Recently completed section** — same row layout but smaller (28pt icon, teal check), simpler row (title + meta + relative time).

---

### 8. Notes — Two-pane editor

**Toolbar:** title "Notes", subtitle "14 notes · 9 linked", Sort + **New Note** primary button

**Left pane (320pt wide):**
- Search input at top (white-70 bg, 7pt radius, search icon)
- Note rows — 10/16/12 padding, 0.5pt hairline below, 3pt teal left border on selected, teal-soft-08 bg on selected
- Title (13.5/600/-0.2) + relative time (10.5/mute) on top row, 2-line clamped snippet (11.5/soft, 1.35 leading) below
- "LINKED" badge (10/700/teal-ink on teal-soft, 4pt radius, 0.3 letter-spacing/uppercase) with link icon

**Right pane (editor):**
- Toolbar (42pt tall, white-40 bg, hairline bottom): Bold · Italic · Underline · | · H1 · H2 · | · • list · 1. list · | · **Insert · 02:14:08** (teal-soft pill, current playing time)
  - Right side: "Last saved · just now" (11/mute)
- Body (28/56/40 padding, white-04 paper-warm bg):
  - Title — Georgia 32/700/-0.5, contenteditable
  - Linked-book chip — same as iOS, teal-soft pill with book icon
  - Body — 15.5/-0.05, 1.65 leading, max-width 640pt, supports bold/italic/timestamp pills/highlights

**Behavior:** autosave debounced 500ms, no explicit save action.

---

### 9. Player Bar (persistent, bottom of main window)

78pt tall, full width, dark ink bg with 0.5pt top hairline.

**Layout** — three flex zones:

**Left (280pt):**
- 54pt cover (radius 6) — click expands to Now Playing
- Title (13/600/white) + author (11.5/55%)
- 26pt bookmark icon button (overflow)

**Center (flex, max 760pt):**
- Top row: prev-chapter ‹ · skip-back 15 · **Play/Pause** (32pt paper circle) · skip-fwd 15 · next-chapter ›
  - Skip icons are custom: 22pt circular arrow with the seconds number inside
- Bottom row: timestamp (10.5/mono/55%) — 4pt scrubber — remaining timestamp

**Right (280pt):**
- "1.5×" pill (text only)
- Moon icon + countdown ("22:13") — teal when sleep timer active
- Queue icon (list)
- Bookmark icon
- Volume: speaker icon + 78pt slider w/ paper thumb
- **Expand** chevron-up button (26pt, white-08 bg) — opens Now-Playing

---

### 10. Player — Now Playing (expanded full window)

Slides up to cover the main window. Same window chrome.

- 48pt top bar: traffic lights + "NOW PLAYING" eyebrow centered + chevron-down close button (28pt, white-10 bg) right
- Body — flex row, 20/56/12 padding, 56pt gap:
  - **Left:** 420pt cover, then centered Georgia 32 title, 16 author, 11 uppercase chapter caption
  - **Right:** tabbed pane (Chapters / Bookmarks / Notes) — pill-style tabs in `white-06` container, then a scrolling chapter list (same shape as the inspector chapter list, but larger — 14pt rows, teal-soft-18 active highlight)
- Bottom — flexShrink 0, 8/56/28 padding:
  - Scrubber row (4pt bar, 13pt thumb, 60pt mono timestamps on each side)
  - Transport row centered, gap 36: skip-back-36 · 64pt paper play/pause circle · skip-fwd-36
  - Secondary row centered, gap 28: Speed (text 1.5×), Sleep (moon icon + 22:13), Bookmark (icon), New Note (pencil icon) — each is a 52×36 rounded pill on `white-08` with an 11pt label

Background: `radial-gradient(ellipse at 30% 20%, #2A4D6F 0%, #0E1E33 50%, #0A0A12 100%)`

---

### 11. Preferences Window

720 × 540 floating window, only red/yellow traffic lights enabled (zoom disabled per macOS Preferences convention).

**Top toolbar** (paper-60 bg, hairline bottom): 5 tabs, each tab is a button with a 20pt icon stacked above an 11pt label.

- General
- **Playback** (active)
- Companion
- Storage
- About

**Body** (24/40 padding) uses a 180pt-label / 1fr-control grid with 16pt gap:

- **Skip interval** — 4 pill buttons (10s · **15s** · 30s · 60s)
- **Default playback speed** — segmented control with 6 speeds
- **On launch resume** — checkbox "Resume the last book automatically"
- **Sleep timer when paused** — checkbox "Pause the sleep timer when playback pauses"
- **Hotkeys** — 2-column grid of label + key-cap badges:
  - Play / Pause — Space
  - Back 15s — ⌘ ←
  - Forward 15s — ⌘ →
  - New Note — ⌘ N
  - Bookmark — ⌘ B
  - Sleep Timer — ⌘ ⌥ S

The other 4 panes (General, Companion, Storage, About) follow the same form pattern. Companion in particular needs:
- "Run AudioLib as Companion" toggle
- Host (read-only, ".local" hostname)
- Port (number)
- Connected devices list (read-only, "iPhone — Andrew's iPhone — connected 12 min ago")
- "Allow downloads on cellular" toggle (off by default)

---

### 12. Mini Player (floating window)

360 × 100, always-on-top, dark.

- 9pt traffic lights top-left (only close enabled)
- 60pt cover (radius 7) on the left
- Center: title (13/600/white), author + chapter (11/60%), 2.5pt progress bar + remaining timestamp
- Right: 28pt skip-back, **36pt paper play/pause circle**, 28pt skip-fwd

**Behavior:** dragging anywhere on the window moves it (use `NSWindow.isMovableByWindowBackground = true`). Closing returns to the main window.

Toggle via View menu → Mini Player (⌘M) or by clicking a "switch to mini" button somewhere in the main window.

---

### 13. Menu Bar Extra

320pt-wide popover off the menu bar icon (NSStatusItem).

- Header row (8pt padding): 42pt cover + title/author/progress text + 30pt ink play/pause button
- Progress bar (3pt, teal) below the row
- Hairline separator
- Menu items (7/10 padding, 6pt hover radius, 12.5/500):
  - **Sleep Timer · 22 min** (teal accent — currently active)
  - Bookmark this position
  - Open in AudioLib
  - Quit AudioLib

Use `NSMenu` with custom view items, or build it inside SwiftUI using `MenuBarExtra` (macOS 13+).

---

### 14. Onboarding Window

Same dimensions and behavior as iOS — shown once on first launch.

800 × 560, no toolbar, only red traffic light enabled. Two-column layout:

**Left:**
- 96pt teal app icon
- "Welcome to AudioLib." — Georgia 44/700/-0.8 (two lines)
- 16pt body copy max-width 320
- "Get Started" primary button (ink, 4pt teal-shadow)

**Right** — vertical stack of 4 feature cards (white-55 bg, 12pt radius, 0.5pt warm border), each with a 36pt teal-soft icon + title (13.5/600) + 12pt subtitle. Features:
1. Faster downloads (companion mode)
2. A library worth owning
3. Notes linked to time
4. Continuity with iPhone

---

## Interactions

### Keyboard shortcuts (all configurable in Preferences)

| Action               | Default |
|----------------------|---------|
| Play / Pause         | Space   |
| Back 15s             | ⌘ ←     |
| Forward 15s          | ⌘ →     |
| New Note             | ⌘ N     |
| Bookmark             | ⌘ B     |
| Sleep Timer          | ⌘ ⌥ S   |
| Hide Sidebar         | ⌘ ⌃ S   |
| Hide Inspector       | ⌘ ⌃ I   |
| Grid / List toggle   | ⌘ 1 / ⌘ 2 |
| Search               | ⌘ F     |
| New Note (text mode) | ⌘ N     |
| Toggle Mini Player   | ⌘ ⇧ M   |
| Preferences          | ⌘ ,     |
| Quit                 | ⌘ Q     |

### Window transitions

| Action                            | Transition |
|-----------------------------------|------------|
| Sidebar item change               | Cross-fade content, 180ms |
| Library Grid ⇄ List               | Cross-fade, 200ms |
| Player bar → Expanded             | Slide-up animation, 320ms, cubic-bezier(0.2, 0.7, 0.3, 1) |
| Expanded → Player bar             | Slide-down, same easing |
| Open Preferences                  | Standard sheet or floating panel, native |
| Open Mini Player                  | Hide main window OR keep both open (decide with PM) |
| Inspector open/close              | Slide-in from right, 220ms |

### Drag and drop

- **Drop a YouTube URL** anywhere on the window → adds it to Downloads
- **Drop an audio file** (.m4a/.mp3) onto the Library → imports it
- **Drag a book** from Library → drops into another folder (export the audio file)
- **Drag a chapter timestamp** from the Inspector → inserts a "@ 01:23:14" link into the Note Editor (or into any other app like Notes/Drafts)

### Right-click context menus

- **Library card:** Play · Pause · Open in Inspector · Edit Info · Show Audio File in Finder · Move to Series… · Mark Finished · Delete
- **Notes list row:** Open · Duplicate · Export as Markdown · Delete
- **Chapter row:** Play from here · Bookmark this chapter · Copy chapter URL
- **Bookmark row:** Edit Note · Go to Time · Delete

---

## State (additions over iOS)

```swift
@AppStorage("sidebar.collapsed") var sidebarCollapsed: Bool = false
@AppStorage("inspector.collapsed") var inspectorCollapsed: Bool = false
@AppStorage("library.view") var libraryView: LibraryView = .grid   // .grid | .list
@AppStorage("companion.enabled") var companionEnabled: Bool = true
@AppStorage("companion.allowCellular") var allowCellular: Bool = false
@AppStorage("ui.miniPlayer") var miniPlayerOpen: Bool = false
@AppStorage("ui.menuBarExtra") var menuBarExtraEnabled: Bool = true
@AppStorage("hotkeys.playPause") var hotkeyPlayPause: KeyCombo = .space
// ... and one per configurable hotkey

// Window state — preserve window frame across launches automatically via NSWindow.setFrameAutosaveName
```

Everything else (books, notes, bookmarks, downloads, audio engine) is shared with iOS via **CloudKit / iCloud Drive** sync — the user's library is the same on both devices.

---

## Recommended SwiftUI structure

```
AudioLib-Mac/
├── App/
│   └── AudioLibApp.swift           // @main, WindowGroup + Settings + MenuBarExtra
├── Theme/
│   ├── Tokens.swift                // Color, Font extensions
│   └── Components/                 // shared with iOS (in a SPM module)
├── Features/
│   ├── MainWindow/
│   │   ├── MainView.swift          // NavigationSplitView (sidebar / content / detail)
│   │   ├── Sidebar.swift           // SidebarSection, SidebarItem, CompanionFooter
│   │   └── PlayerBar.swift         // bottom 78pt bar — wraps all NowPlayingState
│   ├── Library/
│   │   ├── LibraryView.swift       // owns Grid/List toggle + Continue Listening hero
│   │   ├── LibraryGridView.swift
│   │   ├── LibraryListView.swift
│   │   ├── BookCard.swift          // with .onHover for play overlay
│   │   └── BookInspector.swift     // right-rail
│   ├── Downloads/
│   │   ├── DownloadsView.swift
│   │   └── DownloadRow.swift
│   ├── Notes/
│   │   ├── NotesView.swift         // two-pane HSplitView
│   │   ├── NotesListSidebar.swift
│   │   └── NoteEditorView.swift    // NSViewRepresentable around NSTextView
│   ├── Player/
│   │   ├── NowPlayingView.swift    // full-window expanded view
│   │   ├── PlayerBar.swift         // shared with MainWindow
│   │   ├── MiniPlayerWindow.swift  // NSWindow subclass, always-on-top
│   │   └── MenuBarExtraView.swift  // MenuBarExtra content
│   ├── Preferences/
│   │   ├── PreferencesWindow.swift  // TabView of:
│   │   ├── GeneralPane.swift
│   │   ├── PlaybackPane.swift
│   │   ├── CompanionPane.swift
│   │   ├── StoragePane.swift
│   │   └── AboutPane.swift
│   └── Onboarding/OnboardingWindow.swift
├── Services/
│   ├── AudioPlayerEngine.swift     // AVAudioEngine — shared with iOS via SPM
│   ├── YouTubeDownloadService.swift
│   ├── CompanionServer.swift       // NWListener over TCP, mDNS via NWBrowser
│   └── CloudKitSync.swift          // Books, Notes, Bookmarks (mirrors iOS schema)
└── Model/                          // shared with iOS
```

Key APIs:
- **`NavigationSplitView`** for the three-column main layout
- **`.toolbar` on the detail view** for the per-view toolbar — gives free traffic-light + standard chrome
- **`.inspector(isPresented:)`** for the right inspector (macOS 14+)
- **`MenuBarExtra("AudioLib", systemImage: "headphones")`** for menu bar
- **`WindowGroup` + `Window(id: "mini")`** for the floating mini player; configure with `.windowStyle(.hiddenTitleBar)` + `.windowLevel(.floating)` (macOS 15+) or fall back to a `NSPanel` for always-on-top
- **`.background(.thinMaterial)`** for the glass sidebar (paper-warm tint isn't a stock material — write a custom `BackdropFilter` view that layers a paper-bg-62 over `Material.regular`)

---

## Companion server protocol (open question)

The Mac doubles as the iOS app's download backend. When enabled in Preferences:

1. Start an `NWListener` on TCP port 8080 (configurable)
2. Advertise the service via Bonjour (`_audiolib._tcp.local.`) so iOS can auto-discover
3. Authenticate with a pairing code (shown on Mac, entered on iOS) on first connection
4. iOS hands off a YouTube URL → Mac downloads it → streams the m4a back to iOS

**This protocol is not specified in this design.** The UI assumes it works and shows the right state ("Mac downloading…", "Transferring to iPhone…"); the implementation is engineering's call.

---

## Assets

- **Book covers** are typographic placeholders in the design — replace with extracted YouTube thumbnails (cropped to square) plus the user's manual override in Edit Book.
- **Icons** are inline SVG in the design — replace with **SF Symbols** (same mapping as iOS handoff, see below for the few Mac-only ones).

| Design icon | SF Symbol |
|---|---|
| Sidebar headphones glyph | `headphones` |
| Speaker (active chapter) | `speaker.wave.2.fill` |
| Bookmark filled | `bookmark.fill` |
| Sort | `arrow.up.arrow.down` or `line.3.horizontal.decrease.circle` |
| Companion mode dot | (custom — colored circle with glow) |
| Mini player traffic light | (custom — 9pt instead of 12pt) |
| Hotkey key-cap | (custom — 22pt rounded rect with 0.5pt border + bottom inner shadow) |

---

## Files in this bundle

- `AudioLib Mac.html` — open this to view every Mac window in the design canvas. Pan and zoom; each artboard can be expanded to full-screen via its ⤢ button.
- `mac-app.jsx` — design-canvas composition for the Mac app (Library, Downloads, Notes, Player, Preferences, Mini Player, Menu Bar, Onboarding, Design System).
- `mac-shell.jsx` — main window shell + sidebar + toolbar + bottom player bar — the chrome shared across all views.
- `mac-screens.jsx` — every view body (library grid/list, book inspector, downloads, notes + editor, expanded Now-Playing, Preferences, mini player, menu bar extra, onboarding).
- `components.jsx` — shared tokens, cover generator, icon set, progress bar, book data (shared with iOS).
- `screens-2.jsx` — iOS auxiliary screens; not used by the Mac app but referenced by `mac-app.jsx` for the design system view.
- `design-canvas.jsx` — pan/zoom canvas viewer — **for design preview only, do not port**.

---

## Open questions for the developer

- **Companion protocol** — pairing flow, error handling, connection persistence, mDNS advertisement
- **Mini Player window class** — modern `Window` with `.windowLevel(.floating)` vs custom `NSPanel`? (target macOS version dictates this)
- **CloudKit schema parity** — make sure Book/Note/Bookmark/Chapter records have stable identifiers across iOS and Mac, otherwise sync collisions
- **Sandboxing** — App Sandbox should be on; user-selectable file imports use the standard NSOpenPanel
- **AVAudioSession** is iOS-only; on Mac use AVAudioEngine + remote-command center (`MPRemoteCommandCenter`) to make the Touch Bar / media keys / Lock-screen-style controls work
