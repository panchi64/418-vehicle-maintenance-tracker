//
//  ShellNavigationTests.swift
//  checkpointUITests
//
//  The app shell: the system tab bar (Home, Services, Costs), the per-tab
//  navigation stacks details are pushed onto, and the tab-root toolbar
//  (Settings leading, add-service trailing).
//
//  Replaces GestureInteractionTests, which exercised the custom tab bar's
//  swipe-between-tabs gesture. The system TabView has no such gesture, so a
//  horizontal swipe must now leave the tab alone.
//
//  Labels are the English strings; run under an English simulator locale.
//  Every test skips rather than fails when onboarding covers the shell.
//

import XCTest

final class ShellNavigationTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private var tabBar: XCUIElement { app.tabBars.firstMatch }

    private func tab(_ label: String) -> XCUIElement {
        tabBar.buttons[label]
    }

    /// The shell is covered by onboarding on a fresh install.
    private func requireShell() throws {
        guard tabBar.waitForExistence(timeout: 5), tabBar.isHittable else {
            throw XCTSkip("Tab bar not reachable (onboarding is likely showing)")
        }
    }

    // MARK: - Tab bar

    @MainActor
    func testTabBar_ListsHomeServicesCostsInOrder() throws {
        try requireShell()

        let labels = tabBar.buttons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(labels, ["Home", "Services", "Costs"])
    }

    @MainActor
    func testTabBar_HomeIsSelectedAtLaunch() throws {
        try requireShell()

        XCTAssertTrue(tab("Home").isSelected, "Home is the default tab")
    }

    @MainActor
    func testTabBarTap_SwitchesToCorrectTab() throws {
        try requireShell()

        for label in ["Services", "Costs", "Home"] {
            tab(label).tap()
            XCTAssertTrue(tab(label).isSelected, "Tapping \(label) should select it")
        }
    }

    @MainActor
    func testHorizontalSwipe_DoesNotSwitchTabs() throws {
        try requireShell()
        tab("Home").tap()

        app.windows.firstMatch.swipeLeft()

        XCTAssertTrue(tab("Home").isSelected, "The system tab bar has no swipe-between-tabs gesture")
    }

    @MainActor
    func testVerticalScroll_DoesNotSwitchTabs() throws {
        try requireShell()
        tab("Services").tap()

        app.windows.firstMatch.swipeUp()

        XCTAssertTrue(tab("Services").isSelected, "Vertical scroll should not switch tabs")
    }

    // MARK: - Toolbar

    @MainActor
    func testTabRoot_HasSettingsAndAddServiceInTheNavigationBar() throws {
        try requireShell()

        for label in ["Home", "Services", "Costs"] {
            tab(label).tap()
            XCTAssertTrue(app.buttons["toolbar.settings"].exists, "\(label) root shows Settings")
            XCTAssertTrue(app.buttons["toolbar.addService"].exists, "\(label) root shows add service")
        }
    }

    @MainActor
    func testSettingsButton_PresentsSettingsSheet() throws {
        try requireShell()

        app.buttons["toolbar.settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
    }

    // MARK: - Push navigation

    @MainActor
    func testDocumentLibrary_IsPushedOntoTheServicesStack() throws {
        try requireShell()
        tab("Services").tap()

        let library = app.buttons["Document library"]
        guard library.waitForExistence(timeout: 3) else {
            throw XCTSkip("No vehicle selected, so no document library link")
        }
        // The link sits at the bottom of the tab's scroll content.
        var attempts = 0
        while !library.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        library.tap()

        let documentsBar = app.navigationBars["Documents"]
        XCTAssertTrue(documentsBar.waitForExistence(timeout: 3), "Documents should push, not present")
        // Pushed: a back button, and the tab bar is still there.
        XCTAssertTrue(documentsBar.buttons.element(boundBy: 0).exists)
        XCTAssertTrue(tab("Services").exists)

        documentsBar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(documentsBar.waitForNonExistence(timeout: 3), "Back pops to the Services root")
    }
}
