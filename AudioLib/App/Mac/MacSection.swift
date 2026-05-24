#if os(macOS)
import Foundation

/// The selectable items in the Mac sidebar source list.
enum MacSection: Hashable, Identifiable {
    case allBooks
    case continueListening
    case recentlyAdded
    case finished
    case downloadsActive
    case downloadsCompleted
    case notesAll
    case notesLinked
    case series(String)

    var id: String {
        switch self {
        case .allBooks:          return "all-books"
        case .continueListening: return "continue"
        case .recentlyAdded:     return "recent"
        case .finished:          return "finished"
        case .downloadsActive:   return "downloads"
        case .downloadsCompleted:return "completed"
        case .notesAll:          return "all-notes"
        case .notesLinked:       return "linked-notes"
        case .series(let name):  return "series-\(name)"
        }
    }

    /// Which content pane renders this section.
    enum Pane { case library, downloads, notes }

    var pane: Pane {
        switch self {
        case .downloadsActive, .downloadsCompleted: return .downloads
        case .notesAll, .notesLinked:               return .notes
        default:                                     return .library
        }
    }

    var title: String {
        switch self {
        case .allBooks:          return "All Books"
        case .continueListening: return "Continue Listening"
        case .recentlyAdded:     return "Recently Added"
        case .finished:          return "Finished"
        case .downloadsActive:   return "Downloads"
        case .downloadsCompleted:return "Downloads"
        case .notesAll:          return "Notes"
        case .notesLinked:       return "Notes"
        case .series(let name):  return name
        }
    }

    var systemImage: String {
        switch self {
        case .allBooks:          return "books.vertical"
        case .continueListening: return "play.circle"
        case .recentlyAdded:     return "clock"
        case .finished:          return "checkmark.circle"
        case .downloadsActive:   return "arrow.down.circle"
        case .downloadsCompleted:return "checkmark.circle.fill"
        case .notesAll:          return "note.text"
        case .notesLinked:       return "link"
        case .series:            return "books.vertical"
        }
    }
}
#endif
