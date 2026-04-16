import Foundation

struct FileStore {

    static let audioDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let artDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("art", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func audioURL(for bookID: UUID) -> URL {
        audioDir.appendingPathComponent("\(bookID.uuidString).m4a")
    }

    static func artURL(for bookID: UUID) -> URL {
        artDir.appendingPathComponent("\(bookID.uuidString).jpg")
    }

    /// Atomically move a temp download file to its final audio destination.
    @discardableResult
    static func moveAudio(from tempURL: URL, bookID: UUID) throws -> URL {
        let dest = audioURL(for: bookID)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    /// Atomically move a temp file to its final art destination.
    @discardableResult
    static func moveArt(from tempURL: URL, bookID: UUID) throws -> URL {
        let dest = artURL(for: bookID)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    /// Delete both audio and art files for a book.
    static func deleteBook(id: UUID) {
        try? FileManager.default.removeItem(at: audioURL(for: id))
        try? FileManager.default.removeItem(at: artURL(for: id))
    }
}
