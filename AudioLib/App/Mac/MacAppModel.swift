#if os(macOS)
import SwiftUI
import Observation

enum LibraryViewMode: String { case grid, list }

/// Shared UI state for the Mac app — sidebar selection, layout toggles, and
/// the expanded-player flag. A singleton so the mini-player window and menu-bar
/// extra can reach the same state the main window uses.
@Observable
final class MacAppModel {
    static let shared = MacAppModel()

    var selection: MacSection = .allBooks

    /// Book shown in the right-hand inspector (Library only). Defaults to the
    /// currently-playing book when nothing is explicitly selected.
    var inspectorBookID: UUID? = nil

    var libraryViewMode: LibraryViewMode {
        didSet { UserDefaults.standard.set(libraryViewMode.rawValue, forKey: "mac.libraryView") }
    }
    var sidebarCollapsed = false
    var inspectorVisible: Bool {
        didSet { UserDefaults.standard.set(inspectorVisible, forKey: "mac.inspectorVisible") }
    }
    var showExpandedPlayer = false

    private init() {
        let mode = UserDefaults.standard.string(forKey: "mac.libraryView")
        libraryViewMode = LibraryViewMode(rawValue: mode ?? "grid") ?? .grid
        inspectorVisible = UserDefaults.standard.object(forKey: "mac.inspectorVisible") as? Bool ?? true
    }
}
#endif
