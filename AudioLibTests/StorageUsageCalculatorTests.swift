import XCTest
@testable import AudioLib

final class StorageUsageCalculatorTests: XCTestCase {

    func testFormattedBytes() {
        let u = StorageUsageCalculator.Usage(audioBytes: 500, artBytes: 0)
        XCTAssertTrue(u.formatted().contains("B"))
    }

    func testFormattedMegabytes() {
        let u = StorageUsageCalculator.Usage(audioBytes: 15_000_000, artBytes: 500_000)
        XCTAssertTrue(u.formatted().contains("MB"))
    }

    func testFormattedGigabytes() {
        let u = StorageUsageCalculator.Usage(audioBytes: 2_500_000_000, artBytes: 0)
        XCTAssertTrue(u.formatted().contains("GB"))
    }

    func testCalculateReturnsValidUsage() {
        let usage = StorageUsageCalculator.calculate()
        XCTAssertGreaterThanOrEqual(usage.totalBytes, 0)
    }
}
