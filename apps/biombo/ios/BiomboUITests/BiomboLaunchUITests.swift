import XCTest

@MainActor
final class BiomboLaunchUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppLaunches() {
        let app = launchApp()
        XCTAssertTrue(
            app.staticTexts["app.title"].waitForExistence(timeout: 5),
            "Biombo header should be visible"
        )
    }

    func testListModeShowsEmptyStateWhenNoData() {
        let app = launchApp()
        app.buttons["viewMode.list"].tap()
        XCTAssertTrue(
            app.otherElements["list.emptyState"].waitForExistence(timeout: 3),
            "List view with no cached prices should surface the empty state"
        )
    }

    func testMapModeRendersAppleMap() {
        let app = launchApp()
        app.buttons["viewMode.map"].tap()
        XCTAssertTrue(
            app.maps.firstMatch.waitForExistence(timeout: 5),
            "Map view should embed an Apple MapKit view"
        )
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSkipOnboarding"]
        app.launch()
        return app
    }
}
