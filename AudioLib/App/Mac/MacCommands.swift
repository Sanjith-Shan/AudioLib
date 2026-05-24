#if os(macOS)
import SwiftUI
import CoreData

/// Playback + View menus with the handoff's keyboard shortcuts.
/// (Space is intentionally not bound globally so it keeps working while
/// typing in the note editor; ⌘P toggles play/pause instead.)
struct PlaybackCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    private static let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]

    var body: some Commands {
        // File ▸ New Note (⌘N)
        CommandGroup(replacing: .newItem) {
            Button("New Note") { newNote() }
                .keyboardShortcut("n", modifiers: .command)
        }

        CommandMenu("Playback") {
            Button("Play / Pause") { PlayerController.shared.togglePlayPause() }
                .keyboardShortcut("p", modifiers: .command)
            Divider()
            Button("Skip Forward") { PlayerController.shared.skipForward() }
                .keyboardShortcut(.rightArrow, modifiers: .command)
            Button("Skip Backward") { PlayerController.shared.skipBackward() }
                .keyboardShortcut(.leftArrow, modifiers: .command)
            Divider()
            Button("Increase Speed") { adjustRate(faster: true) }
                .keyboardShortcut("]", modifiers: .command)
            Button("Decrease Speed") { adjustRate(faster: false) }
                .keyboardShortcut("[", modifiers: .command)
            Divider()
            Button("Bookmark This Position") { PlayerController.shared.addBookmark() }
                .keyboardShortcut("b", modifiers: .command)
            Button(sleepActive ? "Cancel Sleep Timer" : "Sleep Timer · 15 min") { toggleSleep() }
                .keyboardShortcut("s", modifiers: [.command, .option])
        }

        CommandMenu("View") {
            Button("Show Grid") { setView(.grid) }.keyboardShortcut("1", modifiers: .command)
            Button("Show List") { setView(.list) }.keyboardShortcut("2", modifiers: .command)
            Divider()
            Button("Toggle Sidebar") { MacAppModel.shared.sidebarCollapsed.toggle() }
                .keyboardShortcut("s", modifiers: [.command, .control])
            Button("Toggle Inspector") { MacAppModel.shared.inspectorVisible.toggle() }
                .keyboardShortcut("i", modifiers: [.command, .control])
            Divider()
            Button("Now Playing") { MacAppModel.shared.showExpandedPlayer.toggle() }
                .keyboardShortcut("0", modifiers: .command)
            Button("Mini Player") { openWindow(id: "mini") }
                .keyboardShortcut("m", modifiers: [.command, .shift])
        }
    }

    // MARK: - Actions

    private var sleepActive: Bool { PlayerController.shared.isSleepTimerActive }

    private func toggleSleep() {
        let p = PlayerController.shared
        p.setSleepTimer(seconds: p.isSleepTimerActive ? nil : 15 * 60)
    }

    private func setView(_ mode: LibraryViewMode) {
        MacAppModel.shared.libraryViewMode = mode
        if MacAppModel.shared.selection.pane != .library {
            MacAppModel.shared.selection = .allBooks
        }
    }

    private func adjustRate(faster: Bool) {
        let player = PlayerController.shared
        let idx = Self.rates.enumerated().min { abs($0.1 - player.playbackRate) < abs($1.1 - player.playbackRate) }?.0 ?? 1
        let next = faster ? min(idx + 1, Self.rates.count - 1) : max(idx - 1, 0)
        player.setRate(Self.rates[next])
    }

    private func newNote() {
        let ctx = PersistenceController.shared.container.viewContext
        let note = NoteDoc(context: ctx)
        note.id = UUID()
        note.title = "New Note"
        note.createdAt = Date()
        note.updatedAt = Date()
        note.rtfData = try? NSAttributedString(string: "").data(
            from: NSRange(location: 0, length: 0),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        try? ctx.save()
        MacAppModel.shared.selection = .notesAll
    }
}
#endif
