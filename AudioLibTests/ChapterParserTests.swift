import XCTest
@testable import AudioLib

final class ChapterParserTests: XCTestCase {

    func testBasicTimestamps() {
        let description = """
        0:00 Introduction
        5:30 Chapter 1 - The Beginning
        1:23:45 Chapter 2 - The Middle
        """
        let chapters = ChapterParser.parse(from: description)
        XCTAssertEqual(chapters.count, 3)
        XCTAssertEqual(chapters[0].startSeconds, 0)
        XCTAssertEqual(chapters[1].startSeconds, 330)
        XCTAssertEqual(chapters[2].startSeconds, 5025)
    }

    func testEmptyDescription() {
        let chapters = ChapterParser.parse(from: "")
        XCTAssertTrue(chapters.isEmpty)
    }

    func testNoTimestamps() {
        let chapters = ChapterParser.parse(from: "This is a great audiobook with no timestamps")
        XCTAssertTrue(chapters.isEmpty)
    }

    func testChapterTitles() {
        let description = "1:00 First Chapter\n2:30 Second Chapter"
        let chapters = ChapterParser.parse(from: description)
        XCTAssertEqual(chapters[0].title, "First Chapter")
        XCTAssertEqual(chapters[1].title, "Second Chapter")
    }
}
