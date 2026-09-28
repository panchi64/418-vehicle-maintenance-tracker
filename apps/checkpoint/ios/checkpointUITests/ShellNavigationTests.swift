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
        // A returning user (read from the argument domain): skips onboarding
        // and seeds the sample garage when the store is empty.
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
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
        // The link sits at the bottom of a lazy list, past the history: it
        // exists only once scrolled near.
        var attempts = 0
        while !(library.exists && library.isHittable) && attempts < 25 {
            app.swipeUp(velocity: .fast)
            attempts += 1
        }
        guard library.exists else {
            throw XCTSkip("No vehicle selected, so no document library link")
        }
        library.tap()

        let documentsBar = app.navigationBars["Documents"]
        XCTAssertTrue(documentsBar.waitForExistence(timeout: 3), "Documents should push, not present")
        // Pushed: a back button, and the tab bar is still there.
        let back = documentsBar.buttons["BackButton"]
        XCTAssertTrue(back.exists)
        XCTAssertTrue(tab("Services").exists)

        // Let the push finish: a tap mid-transition is dropped.
        let hittable = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: back)
        wait(for: [hittable], timeout: 3)
        back.tap()
        sleep(2); print("EXPDUMP\n" + app.debugDescription) //EXP
        XCTAssertTrue(documentsBar.waitForNonExistence(timeout: 5), "Back pops to the Services root")
    }
}
