import XCTest
@testable import AudioLib

final class AudioLibTests: XCTestCase {

    func testDurationFormatterSeconds() {
        XCTAssertEqual(DurationFormatter.string(from: 45), "45s")
    }

    func testDurationFormatterMinutes() {
        XCTAssertEqual(DurationFormatter.string(from: 728), "12m 08s")
    }

    func testDurationFormatterHours() {
        let result = DurationFormatter.string(from: 16320) // 4h 32m
        XCTAssertEqual(result, "4h 32m")
    }

    func testDurationFormatterRemaining() {
        let result = DurationFormatter.remainingString(total: 7200, progress: 3600)
        XCTAssertEqual(result, "1h 00m remaining")
    }
}
