# Handoff: AudioLib — iOS Audiobook App

## Overview

AudioLib is an iOS app that lets a user paste a YouTube link and turn it into a downloaded audiobook in a personal library, with full playback controls, bookmarks, chapter navigation, and rich-text notes that can be timestamp-linked back to a book.

This handoff covers the **complete visual design** for every screen in the spec:

- Onboarding (first launch)
- Download tab (empty + active downloads)
- Library tab (empty + populated, with persistent MiniPlayer)
- Notes tab + Note Editor (rich text + formatting toolbar)
- Full-screen Player (Spotify-style dark theme)
- 4 player modal sheets (Speed, Sleep Timer, Bookmarks, Chapters)
- Edit Book sheet
- Settings (playback, audio source, storage, danger zone, about)

## About the Design Files

The files in this bundle are **design references created in HTML/React** — prototypes showing intended look and behavior, **not production code to copy directly**.

The task is to **recreate these designs in the target iOS codebase using SwiftUI** (recommended for a modern iOS app of this kind) following Apple's Human Interface Guidelines and the codebase's existing patterns where applicable. The HTML/CSS values below (colors, font sizes, paddings) translate directly to SwiftUI modifiers — the visual targets are the source of truth, not the React JSX.

## Fidelity

**High-fidelity.** Colors, typography, spacing, layout, interactions are all final. Treat this as a pixel-perfect target. Where iOS system controls (segmented controls, sheets, bottom-sheet detents, context menus) are appropriate, **use the native equivalents** instead of recreating them by hand — the look will match more closely on real hardware that way.

The one place the design intentionally diverges from stock iOS is the **warm-paper background tone**, the **serif treatment of book titles**, and the **deep-blue Player background**. Preserve those.

---

## Visual Direction

- **Warm paper light theme** across all tabs (Download, Library, Notes, Settings)
- **Deep-blue → near-black gradient** for the full Player (the spec called for "Spotify-style, dark")
- **Teal** is the single accent color — used for: progress fills on completed books, the sleep-timer "active" state, the Note Editor's "Linked" badge, primary CTAs inside dark contexts, and the Notes tab's linked-note indicator
- **Black-ink primary CTAs** in light contexts (e.g. "Get Started", "Download one", "+" note button)
- **Georgia serif** for book titles and large display text (gives a library/reading feel)
- **SF Pro** for everything else (system UI)
- **Monospace tabular numerals** for timestamps and durations
- No emoji, no gradients beyond the Player background and the Onboarding gentle background wash

---

## Design Tokens

### Colors

```
// Light theme (Tabs, Settings, Notes, Library, Download)
paper-bg          #F1ECE2   primary background
paper-bg-alt      #E8E2D4   onboarding bottom-gradient stop
card              #FFFFFF   list cards, rows
card-soft         #F8F5EE   inset fields, empty-state circles
ink               #1B1814   primary text + primary CTAs
ink-soft          rgba(27,24,20,0.62)   secondary text
ink-mute          rgba(27,24,20,0.38)   tertiary, placeholders
ink-faint         rgba(27,24,20,0.12)   icon backgrounds, tracks
hair              rgba(27,24,20,0.08)   row separators

// Accent
teal              #1E9085
teal-soft         #D4ECE9   soft pill backgrounds
teal-ink          #0E5751   text on teal-soft

// Destructive
red               #C8443A

// Player (dark)
d-bg              #0D0D10
d-card            #1B1B20  (#1C1C1F also used in sheets)
d-ink             #FFFFFF
d-ink-soft        rgba(255,255,255,0.62)
d-ink-mute        rgba(255,255,255,0.38)
d-ink-faint       rgba(255,255,255,0.12)

// Player background gradient (top → bottom)
linear-gradient(180deg, #1B4B7A 0%, #0E1E33 60%, #0A0A12 100%)

// Continue Listening banner gradient
linear-gradient(135deg, #11332E 0%, #1B5751 100%)

// Onboarding background gradient
linear-gradient(180deg, #F5F2EB 0%, #E8DFC9 100%)

// App icon gradient
linear-gradient(160deg, #0F5751 0%, #1E9085 100%)
```

### Typography

```
Display (book titles, large headers):  Georgia, "Iowan Old Style", serif
UI:                                    SF Pro / system
Mono (timestamps, URLs, version):      ui-monospace, "SF Mono", monospace, tabular-nums

Scale:
- Large title (nav)        28 / 700 / -0.5 letter-spacing (Georgia)
- Onboarding app name      40 / 700 / -0.8 (Georgia)
- Player book title        24 / 700 / -0.4 (Georgia)
- Note Editor title        26 / 700 / -0.4 (Georgia)
- Section header           13 / 600 / +0.5 / uppercase / ink-soft
- Row title                15 / 600 / -0.2
- Row secondary            13 / regular / ink-soft
- Body                     16 / regular / -0.1
- Caption                  11–12 / regular or 600 / ink-mute
- Timestamp                11–13 / mono / tabular-nums
```

### Spacing & shape

```
Card radius          16–20 (rows 14–18, sheets 18)
Pill / button radius 10–14
App icon radius      26 (iOS app icon proportion)
Tab bar height       64 + 14 safe area
Mini player          inset 8px, 16-radius, ~56px tall, bottom: 64 (above tab bar)
Modal sheet          top-radius 18, 36×5 grabber
Cover radius         8 (rows) / 10 (Continue Listening) / 14 (Player) / size×0.06 generally
```

### Shadow

```
Card                 0 1px 3px rgba(0,0,0,0.08), 0 4px 16px rgba(0,0,0,0.06)
MiniPlayer (dark on light)
                     0 6px 22px rgba(27,24,20,0.22)
Continue listening banner
                     0 8px 24px rgba(17,51,46,0.22)
Player play button   0 6px 20px rgba(0,0,0,0.35)
App icon             0 16px 40px rgba(15,87,81,0.32), inset 0 1px 0 rgba(255,255,255,0.2)
Sheet top edge       0 -8px 30px rgba(0,0,0,0.18)
```

---

## Screens

### 1. Onboarding

**Purpose:** First-launch only. Establishes app identity, surfaces 3 feature highlights, requests notifications via the "Get Started" CTA.

**Layout (top → bottom, 32pt horizontal padding):**
- 120pt top inset
- 112×112 app icon (radius 26, headphones glyph on teal gradient) — centered
- 32pt gap
- "AudioLib" — Georgia 40/700/-0.8 — centered
- 10pt gap
- Tagline "Turn any YouTube link into an audiobook you actually own." — 17pt, 62% ink, max-width 280, centered
- `margin-auto` flex spacer
- 3 feature rows (gap 18): 36×36 teal-soft pill icon + title (15/600) + subtitle (13, 62% ink)
  1. Download from YouTube — "Paste a link, get an audiobook."
  2. A real library — "Continue listening, sorted your way."
  3. Take notes with timestamps — "Bookmark thoughts as you listen."
- 36pt gap
- **Get Started** button — ink bg, paper-fg, 52pt tall, radius 16, 17/600
- 12pt gap
- Disclosure text — 12pt, ink-mute — "We'll ask for notifications next so we can tell you when downloads finish."

**Behavior:** Tap "Get Started" → request notification permission → dismiss sheet. Sheet is non-dismissable by swipe (`.interactiveDismissDisabled(true)` in SwiftUI).

---

### 2. Download Tab

**Nav row:** Large serif title "Download" + gear icon (top-right, 36×36 glass pill, opens Settings).

**"Add Audiobook" card (dark, top of scroll):**
- Margin 16, padding 18/16, radius 20, bg ink, fg paper
- Eyebrow "ADD AUDIOBOOK" — 11/700/+0.8 / uppercase / 55% paper
- Headline "Paste a YouTube link" — 22/700/-0.4
- 14pt gap
- URL field — inset white-08 bg, radius 12, padding 12/14, link icon + monospace placeholder `youtube.com/watch?v=…`
- 12pt gap
- **Download** button — full-width, 46pt tall, radius 12
  - Enabled state: paper bg, ink fg
  - Disabled (empty URL): white-18 bg, paper-50 fg, no cursor
  - Active "Downloading…": spinner + label

**Active section:** `SECTION_HEADER "ACTIVE"` then list of DownloadRow cards (16px margin, 10px between, white card, radius 16, padding 14).

**DownloadRow structure:**
- 36×36 leading badge (varies by state: down-arrow on card-soft / check on teal-soft / wifi-x on red-soft)
- Title (15/600, single line, ellipsis, 24px right padding for the cancel button)
- State label below title (12/500, color follows state):
  - "Queued" / "Fetching info…" / "Downloading 64%" / "Mac downloading…" (companion server) / "Transferring to iPhone…" (companion server) / "Finalizing" / "Done" (teal) / "Failed" (red) / "Cancelled"
  - Optional source suffix: " · m4a" or " · Companion" in ink-mute
- 24×24 cancel button (top-right, ink-faint bg, x glyph)
- If `pct !== undefined && !error`: 4pt progress bar (teal if Done, else ink), 8pt gap, 11.5pt stats row — size left, "2.4 MB/s · ~3 min left" right, mono tabular
- If `error`: red-soft pill below with red 12.5pt copy ("Could not reach YouTube after 30s…")
- If `canStream && partial m4a`: teal-soft "▶ Tap to listen" pill below

**Empty state:** card-soft 72×72 circle with down-arrow icon, "No Active Downloads" 17/600, "Paste a YouTube link above to get started." 14/62%

---

### 3. Library Tab

**Nav row:** Large serif "Library" + sort icon + gear icon.

**Search bar** (below nav, 16px margin): white-70 bg, radius 12, search-icon + placeholder "Search title or author"

**Continue Listening banner** (only when at least one book has 0 < progress < 1):
- 4/16/18 margin, padding 16, radius 20, gradient `#11332E → #1B5751`, paper text
- 84×84 cover + content column:
  - "CONTINUE LISTENING" eyebrow — 10/700/+1.2 / uppercase / 55%
  - Title — 17/700/-0.3, ellipsis
  - Author — 13 / 70%
  - 12pt gap
  - Row: progress bar (3pt, paper fill on 18% paper track) + "3h 47m left" 11pt below + 44×44 paper play button on the right

**All books list:** `SECTION_HEADER "ALL BOOKS · 7"` then a 16-margin white card (radius 18) of LibraryRows separated by 0.5pt hairlines (inset 92px to align past the cover).

**LibraryRow:**
- 64×64 cover (radius 8)
- Title 15/600 + Author 13/soft
- Optional Series label "Series Name #N" — 11.5/600/teal-ink
- 6pt gap, then 2.5pt progress bar + remaining label ("3h 47m left" / "Finished" / "New") in tabular-nums, 11pt, right-aligned, min-width 56
- Trailing 38×38 card-soft play button

**Empty state:** large card-soft 84×84 books icon, "Your Library" 19/700 serif, "Downloaded audiobooks will appear here." subtitle, then a primary "Download one" button (ink bg, paper text, 22pt horizontal padding) → jumps to Download tab.

**Long-press / context menu on a row:** Edit Info · Delete (use native iOS context menu).

**Sort menu** (sort icon): Recently Added · Last Played · Title A–Z · Author A–Z

---

### 4. Notes Tab

**Nav row:** Large serif "Notes" + gear + **+** (ink bg, paper +) button.

**Notes list** (16-margin white card, radius 18): rows separated by 0.5pt hairlines (inset 36px past the leading bar).

**NoteRow:**
- 6pt-wide vertical bar (full-row height): teal if `linked`, else ink-faint
- Title 16/600/-0.2 (ellipsis) — optional `LINKED` 10pt teal-soft pill (top-right of title row, padding 2/7, radius 6)
- Snippet line — 13.5 / 62% / 1.35 line-height / ellipsis
- Relative time — 12 / 38% (e.g. "2 hours ago")

**Swipe-to-delete** on each row (native iOS swipe action, red).

**Empty state:** card-soft 84×84 note icon, "No Notes Yet" 19/700 serif, "Tap + to create your first note." 14/62%

#### 4a. Note Editor (push screen)

**Nav row:** back chevron · editable title (16/600, inline in nav) · **Done** button (teal bg, white, padding 8/14, radius 14)

**Body** (padding 8/20/12):
- 26/700 serif title (matches nav title, larger)
- 12pt gap
- Optional teal-soft "Linked" chip with link icon + book name + author
- 16pt gap
- Rich content area — 16/-0.1 / 1.55 line-height:
  - Inline `**bold**` and `*italic*` supported
  - Inserted-timestamp pills render as monospace 13pt on teal-soft, radius 8, inline-block (e.g. `[Atomic Habits @ 01:23:14]`)
  - Highlight selection: `rgba(30,144,133,0.18)` background on selected run
- Caret blink visible (use a 1px-wide teal block)

**Formatting toolbar** (sits above keyboard, paper-85% blurred bar, hairline top border):
- B · I · U · | · H1 · H2 · | · bullets · numbered · | · 🕐 timestamp button (teal-soft, shows current playing position e.g. "01:23")
- All buttons 36×36 radius 8; transparent bg; teal-soft + teal-ink when active
- Toolbar scrolls horizontally if cramped

**Behavior:** Title and body autosave on debounced edits (500ms). Done commits and pops.

---

### 5. MiniPlayer (persistent)

Shown above the tab bar whenever a book is loaded **and** the full Player is not open. Coordinates with Player navigation transitions (slide-up).

- Bottom: 64pt (just above tab bar), left/right: 8pt
- Radius 16, ink background, paper text, 8/10 padding
- 42×42 cover (radius 8) + title (13/600) / author (11.5 / 55%) — flex column, ellipsis
- 34×34 white-12 circle Play/Pause button (16pt glyph)
- 2pt teal progress hairline along the bottom inset 12px

**Tap the body** → expand to full Player (slide-up). **Tap play** → toggle without expanding.

---

### 6. Player (full-screen sheet)

Dark theme. Layout top → bottom:

**Nav row** (padding 10/16):
- Glass chevron-down (close) — left
- Center stack: eyebrow "PLAYING FROM LIBRARY" (11/600/0.6/uppercase/62%) + book title (13/600/white)
- Glass ••• — right (opens Edit Book sheet)

**Cover** — 310×310, radius 14, dropshadow, centered, 24pt top padding.

**Title block** (padding 20/24/0): 24/700 serif title, 14.5/62% author. (A bookmark icon may sit in the trailing slot.)

**Scrubber** (padding 24/24/8): 4pt track, white fill, 12×12 thumb with subtle shadow. Below it: tabular-nums "2:14:08" (current) / "-3:47:22" (remaining).

**Primary controls row** (padding 12/24/24):
- Skip-back (custom: circular arrow with `15` inside, 48×48) — interval matches the user's Settings choice (10/15/30/60)
- Play/Pause — 72×72 white circle, ink glyph, big dropshadow
- Skip-fwd (same custom glyph, opposite direction)

**Secondary controls row** (padding 0/16/36) — 4 evenly-spaced ClickableSecondary buttons (44×32 rounded pill icon + 10.5pt label):
- **Speed** — current rate as text "1.5×"
- **Sleep** — moon icon (filled teal when active) + countdown "22:13"
- **Chapters** — list icon (shown only if the book has chapter metadata)
- **Marks** — bookmark icon

Each opens its sheet (see 5a–d). Active state = teal-tinted background + teal label.

#### 5a. Speed Sheet (medium detent)

- Dark sheet, title "Playback Speed", trailing "Done"
- 4-column grid of 8 cells (0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0), aspect ratio 1.1, radius 14
- Inactive: white-06 bg, 1px white-08 border, white text 18/700
- Active: teal bg, white text, no border, teal-glow shadow
- Footer note: "Speed changes apply instantly to all books. Most listeners settle at **1.5×**." (12.5 / 62%)

#### 5b. Sleep Timer Sheet (medium/large detent)

- Title "Sleep Timer", trailing "Done"
- White-on-dark grouped list (`#2A2A2F` card, 14 radius): Off · 5 min · 10 min · 15 min · 30 min · 45 min · 1 hour — active row shows teal check on right
- "CUSTOM" section header
- Pill input: number field (mono tabular, 16pt) + "minutes" suffix + **Set** button (teal bg, white, padding 8/16, radius 10)
- "1–999 min" helper line below

#### 5c. Bookmarks Sheet

- Title "Bookmarks", trailing "Done"
- Full-width teal button (radius 14, padding 14, white text 15/600, bookmark icon + "Bookmark this position · 02:14:08", teal-glow shadow)
- 16pt gap
- `#2A2A2F` card with rows: mono tabular timestamp (teal 13/600) + note (white 14, or "No note" in ink-mute if blank)
- Swipe-to-delete per row (native)
- Tap row → seek and dismiss

#### 5d. Chapters Sheet

- Title "Chapters"
- `#2A2A2F` card, rows: 22×22 leading slot (chapter number in 13/600, or teal speaker icon if currently playing) + title (14.5, teal+600 if active) + mono tabular start time (13)
- Active row has `rgba(30,144,133,0.13)` row tint
- Tap row → seek and dismiss

---

### 6. Edit Book Sheet

Reached from the Player ••• menu or from the Library row context menu.

- Sheet detent ~85%, light theme
- Title "Edit Book", leading "Cancel", trailing "Save" (teal)
- 120×120 cover (radius 12) centered at top
- White card (radius 14) with 4 form rows separated by hairlines:
  - Title (string) — value right-aligned
  - Author (string)
  - Series (string, optional, placeholder "None")
  - # in Series (number, optional, placeholder "—")
- `SECTION_HEADER "DANGER ZONE"`
- Full-width white-card button: trash icon + "Delete Book & Audio File" in red (15/600)
- Disclosure: "Bookmarks and notes for this book will remain." (12 / ink-mute / line-height 1.4)

**Confirmation dialog** on delete: use native iOS `.confirmationDialog` ("Delete this book?" — destructive + cancel).

---

### 7. Settings

Reachable via gear from all three tabs.

**Nav:** back chevron + large serif "Settings".

**Playback section:** white card with "Skip interval" label and 4-pill segmented row (10s · 15s · 30s · 60s). Selected pill: ink bg + paper text. Others: card-soft bg + ink text.

**Audio Source section:** white card.
- Top: 2-segment toggle "On-Device | Companion" (segmented control style: card-soft track + white selected segment with subtle shadow)
- When Companion: form fields "Host" and "Port" (mono tabular inset card-soft pills)
- **Test Connection** result button: teal-soft pill — green 8pt dot + "Connected to mac-mini.local" (teal-ink, 13.5/600)
- Disclosure copy + "Setup instructions →" link in teal-ink/600

**Storage:** white card with two rows: "Library size 2.84 GB" / "Books 7"

**Danger Zone:** white card with red destructive row "Delete All Books" (trash icon + 15/600).
- Confirmation dialog on tap.

**About:** white card with one row "Version 1.4.2 (231)" (mono tabular).

---

## Interactions, Animations, Transitions

| From → To | Transition |
|---|---|
| Tab change | Cross-fade or none (native iOS) |
| MiniPlayer tap → Player | Slide up, 320ms, cubic-bezier(0.2, 0.7, 0.3, 1) |
| Player close (chevron-down) | Slide down, same easing |
| Any sheet (Speed, Sleep, etc.) | Native bottom sheet with appropriate detents |
| Notes list → Editor | Push (native nav stack) |
| Settings push | Push |
| Edit Book sheet | Modal sheet w/ ~85% detent, drag-down dismiss |
| Download progress | Live (driven by upstream events), bar animates smoothly |
| Spinner | 800ms linear infinite rotation |

**Hit targets** are all 44pt minimum (Apple guideline).

---

## State Management Summary

```
Onboarding:
- hasOnboarded: Bool (UserDefaults) — only show once

Downloads (one model per job):
- id, url, videoId, title, state (queued|fetchingInfo|downloading|finalizing|done|failed|cancelled)
- progressPercent, downloadedBytes, totalBytes, speed, etaSeconds
- error?, canStreamPartial (bool — true for m4a partials), source (onDevice|companion)
- companionSubstate? (macDownloading | transferringToiPhone) when source == companion

Library:
- books: [Book(id, title, author, series?, seriesIndex?, durationSec, addedAt, lastPlayedAt, currentPositionSec, coverData)]
- sort: enum {recentlyAdded, lastPlayed, titleAZ, authorAZ}
- search: String

Player:
- currentBookId?, isPlaying, positionSec
- skipIntervalSec (from Settings, default 15)
- playbackRate (0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0)
- sleepTimerEndsAt? Date, sleepTimerCountdown
- chapters: [Chapter(title, startSec)]?
- bookmarks: [Bookmark(timeSec, note?)]

Notes:
- notes: [Note(id, title, bodyAttrString, linkedBookId?, linkedPositionSec?, updatedAt)]
- editing: Note? (current draft, debounced autosave)

Settings:
- skipIntervalSec
- audioSource: onDevice | companion
- companionHost, companionPort, companionTestResult
- librarySizeBytes (derived), bookCount (derived)
- appVersion (derived)
```

**Persistence:** Books, notes, bookmarks → Core Data or SwiftData. Settings + onboarding flag → UserDefaults. Cover art + audio files → Application Support / Documents directory.

---

## Assets

- **Book covers in the design are typographic placeholders** generated in code (gradient backgrounds + serif title). In the real app, covers come from the YouTube video's thumbnail (cropped to square, blurred fallback, optional manual override in Edit Book).
- **No bitmap assets ship with the design.** All icons are inline SVG drawn from a small icon set — replace with **SF Symbols** in iOS:
  | Design icon | SF Symbol |
  |---|---|
  | arrow-down-circle | `arrow.down.circle` |
  | books | `books.vertical.fill` |
  | note | `note.text` |
  | gear | `gearshape` |
  | search | `magnifyingglass` |
  | play / pause | `play.fill` / `pause.fill` |
  | skip-back-15 / fwd-15 | `gobackward.15` / `goforward.15` |
  | moon | `moon.fill` |
  | bookmark | `bookmark` / `bookmark.fill` |
  | list (chapters) | `list.bullet` |
  | speaker (active chapter) | `speaker.wave.2.fill` |
  | more (•••) | `ellipsis` |
  | sort | `line.3.horizontal.decrease` |
  | trash | `trash` |
  | edit (pencil) | `pencil` |
  | link | `link` |
  | clock (timestamp insert) | `clock` |
  | chevron-left/right/up/down | `chevron.left` etc. |
  | check | `checkmark` |
  | wifi-x (download failed) | `wifi.exclamationmark` |

---

## Files in this bundle

- `AudioLib.html` — open this to view the full design canvas in a browser. Pan with two-finger scroll / drag, zoom with pinch / Ctrl+wheel. Each artboard can be expanded to full-screen via its ⤢ button.
- `app.jsx` — design-canvas composition: groups artboards into sections (Interactive Prototype, Onboarding, Empty States, Three Tabs, Player, Modals & Settings, Design System).
- `components.jsx` — shared tokens (`T`), book data, the Cover generator (with motif decorations per book), Icon set, ProgressBar, TabBar, MiniPlayer, Sheet shell, SectionHeader.
- `screens-1.jsx` — Onboarding, Download tab, Library tab + Continue Listening banner + LibraryRow.
- `screens-2.jsx` — Notes tab, Note Editor, full Player + Skip icons + ClickableSecondary, all 4 player sheets, Book Edit sheet, Settings.
- `ios-frame.jsx` — iOS device chrome (status bar, dynamic island, home indicator) — **for design preview only, do not port**.
- `design-canvas.jsx` — pan/zoom canvas shell — **for design preview only, do not port**.

The two "do not port" files are the design viewer scaffolding; the real iOS app does not need them.

---

## Recommended SwiftUI structure

```
AudioLib/
├── App/
│   └── AudioLibApp.swift            // @main, root TabView
├── Theme/
│   ├── Tokens.swift                 // Color, Font extensions for every token above
│   └── Components/                  // reusable views
│       ├── Cover.swift              // book cover (image + fallback typographic placeholder)
│       ├── ProgressBar.swift
│       ├── MiniPlayer.swift
│       ├── SectionHeader.swift
│       └── GlassPillButton.swift    // 36×36 nav buttons
├── Features/
│   ├── Onboarding/OnboardingView.swift
│   ├── Download/
│   │   ├── DownloadView.swift
│   │   ├── DownloadRowView.swift
│   │   └── AddAudiobookCard.swift
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   ├── LibraryRowView.swift
│   │   ├── ContinueListeningBanner.swift
│   │   └── EditBookSheet.swift
│   ├── Notes/
│   │   ├── NotesListView.swift
│   │   ├── NoteRowView.swift
│   │   └── NoteEditorView.swift     // UIViewRepresentable around UITextView for rich text
│   ├── Player/
│   │   ├── PlayerView.swift
│   │   ├── SpeedSheet.swift
│   │   ├── SleepTimerSheet.swift
│   │   ├── BookmarksSheet.swift
│   │   └── ChaptersSheet.swift
│   └── Settings/SettingsView.swift
├── Model/
│   ├── Book.swift, Note.swift, Bookmark.swift, Chapter.swift, DownloadJob.swift
│   └── AudioPlayerEngine.swift      // AVAudioPlayer/AVAudioEngine wrapper
└── Services/
    ├── YouTubeDownloadService.swift  // YouTubeKit or companion-server adapter
    └── CompanionClient.swift
```

`SwiftUI`'s `.sheet(item:)` and the new `presentationDetents([.medium, .large])` cover every modal in this design natively.

---

## Notes on rich-text in the Note Editor

SwiftUI's `TextEditor` does not natively support inline rich text (bold/italic/underline + heading styles + custom inline pills like the timestamp chip). The most pragmatic path:

- Wrap a `UITextView` via `UIViewRepresentable`
- Store body as `NSAttributedString` (archive to Data in the model)
- Implement the formatting toolbar as a SwiftUI overlay; commands dispatch to the wrapped text view
- Timestamp insert uses a custom `NSTextAttachment` (or a styled `NSAttributedString` run with custom background) — the chip shape in the design is a teal-soft monospace inline-block

---

## Open questions for the developer

- **Real YouTube downloading** — pick between in-app (YouTubeKit) and a Mac companion server. Both UIs are covered.
- **Cover art** — extract YouTube thumbnail by default; allow override in Edit Book? (Design currently has no upload affordance — add a tap-to-edit overlay on the 120×120 cover in Edit Book.)
- **Background audio** — needs the Background Modes capability and AVAudioSession `.playback` category set on app launch.
- **Companion server protocol** — needs a defined HTTP / mDNS handshake, not in this design.
