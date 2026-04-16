import XCTest

final class AudioLibUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTabBarExists() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
