import XCTest
@testable import AudioLib

final class FileStoreTests: XCTestCase {

    func testAudioURLIsUUIDNamed() {
        let id = UUID()
        let url = FileStore.audioURL(for: id)
        XCTAssertTrue(url.lastPathComponent == "\(id.uuidString).m4a")
    }

    func testArtURLIsUUIDNamed() {
        let id = UUID()
        let url = FileStore.artURL(for: id)
        XCTAssertTrue(url.lastPathComponent == "\(id.uuidString).jpg")
    }

    func testAudioDirExists() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: FileStore.audioDir.path))
    }

    func testArtDirExists() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: FileStore.artDir.path))
    }

    func testMoveAudio() throws {
        let id = UUID()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        try "fake audio data".write(to: tempURL, atomically: true, encoding: .utf8)
        let dest = try FileStore.moveAudio(from: tempURL, bookID: id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
        // Cleanup
        FileStore.deleteBook(id: id)
    }

    func testDeleteBook() throws {
        let id = UUID()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        try "fake".write(to: tempURL, atomically: true, encoding: .utf8)
        _ = try FileStore.moveAudio(from: tempURL, bookID: id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: FileStore.audioURL(for: id).path))
        FileStore.deleteBook(id: id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: FileStore.audioURL(for: id).path))
    }
}
