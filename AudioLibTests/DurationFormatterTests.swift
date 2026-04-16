import XCTest
@testable import AudioLib

final class DurationFormatterTests: XCTestCase {

    func testSecondsOnly() {
        XCTAssertEqual(DurationFormatter.format(seconds: 45), "45s")
        XCTAssertEqual(DurationFormatter.format(seconds: 0), "0s")
        XCTAssertEqual(DurationFormatter.format(seconds: 59), "59s")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(DurationFormatter.format(seconds: 60), "1m 00s")
        XCTAssertEqual(DurationFormatter.format(seconds: 728), "12m 08s")
        XCTAssertEqual(DurationFormatter.format(seconds: 3599), "59m 59s")
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(DurationFormatter.format(seconds: 3600), "1h 00m")
        XCTAssertEqual(DurationFormatter.format(seconds: 16320), "4h 32m")
    }

    func testRemainingString() {
        let remaining = DurationFormatter.remainingString(total: 3600, progress: 900)
        XCTAssertTrue(remaining.contains("45"))
        XCTAssertTrue(remaining.lowercased().contains("remaining"))
    }
}
