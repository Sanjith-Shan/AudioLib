import CoreData
import Foundation

// MARK: - Book extensions

extension Book {
    /// Fraction of playback completed (0.0–1.0).
    var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(progressSeconds / durationSeconds, 1.0)
    }

    /// URL to the audio file in the app's Documents/audio directory.
    /// FileStore (Phase 3) will provide the canonical implementation;
    /// this stub uses the standard documents path.
    var audioURL: URL? {
        guard !audioFilename.isEmpty else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("audio/\(audioFilename)")
    }

    /// URL to the cover art file in the app's Documents/art directory.
    var artURL: URL? {
        guard let filename = artFilename, !filename.isEmpty else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("art/\(filename)")
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
