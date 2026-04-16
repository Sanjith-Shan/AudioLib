import CoreData
import Foundation

// MARK: - Book extensions

extension Book {
    /// Fraction of playback completed (0.0–1.0).
    var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(progressSeconds / durationSeconds, 1.0)
    }

    /// URL to the audio file managed by FileStore.
    var audioURL: URL {
        FileStore.audioURL(for: id)
    }

    /// URL to the cover art file managed by FileStore, or nil if no art has been downloaded.
    var artURL: URL? {
        artFilename != nil ? FileStore.artURL(for: id) : nil
    }

    /// Chapters sorted by startSeconds ascending.
    var chaptersArray: [Chapter] {
        (chapters as? Set<Chapter>)?.sorted { $0.startSeconds < $1.startSeconds } ?? []
    }

    /// Bookmarks sorted by timeSeconds ascending.
    var bookmarksArray: [Bookmark] {
        (bookmarks as? Set<Bookmark>)?.sorted { $0.timeSeconds < $1.timeSeconds } ?? []
    }

    /// Factory method: creates and inserts a new Book managed object.
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        sourceURL: String,
        audioFilename: String
    ) -> Book {
        let book = Book(context: context)
        book.id = UUID()
        book.title = title
        book.sourceURL = sourceURL
        book.audioFilename = audioFilename
        book.dateAdded = Date()
        book.durationSeconds = 0
        book.progressSeconds = 0
        book.playbackRate = 1.0
        book.seriesIndex = 0
        return book
    }
}

// MARK: - NoteDoc extensions

extension NoteDoc {
    /// Factory method: creates and inserts a new NoteDoc managed object.
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        linkedBookID: UUID? = nil
    ) -> NoteDoc {
        let note = NoteDoc(context: context)
        note.id = UUID()
        note.title = title
        note.createdAt = Date()
        note.updatedAt = Date()
        note.linkedBookID = linkedBookID
        return note
    }
}
