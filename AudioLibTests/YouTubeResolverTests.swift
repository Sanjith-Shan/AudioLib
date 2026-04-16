import XCTest
@testable import AudioLib

final class MockResolver: YouTubeResolver {
    var shouldFail = false
    func resolve(url: URL) async throws -> YTMetadata {
        if shouldFail { throw YouTubeResolverError.invalidURL }
        return YTMetadata(
            videoID: "test123",
            title: "Test Audiobook",
            uploader: "Test Channel",
            durationSeconds: 3600,
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")!,
            audioStreamURL: URL(string: "https://example.com/audio.m4a")!,
            fileExtension: "m4a",
            chapters: [
                YTChapter(title: "Intro", startSeconds: 0),
                YTChapter(title: "Chapter 1", startSeconds: 120)
            ]
        )
    }
}

final class YouTubeResolverTests: XCTestCase {

    func testMockResolverSuccess() async throws {
        let resolver = MockResolver()
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let metadata = try await resolver.resolve(url: url)
        XCTAssertEqual(metadata.videoID, "test123")
        XCTAssertEqual(metadata.title, "Test Audiobook")
        XCTAssertEqual(metadata.chapters.count, 2)
    }

    func testMockResolverFailure() async {
        let resolver = MockResolver()
        resolver.shouldFail = true
        let url = URL(string: "https://www.youtube.com/watch?v=test")!
        do {
            _ = try await resolver.resolve(url: url)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is YouTubeResolverError)
        }
    }
}
