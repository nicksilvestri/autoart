import XCTest

final class ThresholdUITests: XCTestCase {
    func testEditorAppearsWithControls() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["Threshold"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.sliders["thresholdSlider"].exists)
        XCTAssertTrue(app.buttons["shareButton"].exists)
        XCTAssertTrue(app.buttons["resetButton"].exists)
    }
}
