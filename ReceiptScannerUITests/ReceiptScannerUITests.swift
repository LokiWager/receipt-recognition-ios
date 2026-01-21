import XCTest

final class ReceiptScannerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app launches with the Home tab
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Scan"].exists)
        XCTAssertTrue(app.tabBars.buttons["Analytics"].exists)
    }

    @MainActor
    func testNavigationTitle() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify navigation title exists
        XCTAssertTrue(app.navigationBars["Receipts"].exists)
    }

    @MainActor
    func testEmptyStateDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify empty state message is displayed when no receipts
        XCTAssertTrue(app.staticTexts["No Receipts"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
