//
//  AdaptiveLayoutTests.swift
//  checkpointUITests
//
//  Regular width (iPad; the Duo's inner display): Services and Costs show
//  list | detail columns. A row opens its detail beside the list, another row
//  replaces it (no back button), and the root toolbar still works.
//
//  Runs on iPad only — compact width is `ShellNavigationTests`. Launches as a
//  returning user (`-hasCompletedOnboarding YES`, read from the argument
//  domain), which seeds the sample garage when the store is empty. Labels are
//  the English strings; run under an English simulator locale.
//

import XCTest

final class AdaptiveLayoutTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(
            UIDevice.current.userInterfaceIdiom == .pad,
            "Regular-width columns: run on an iPad simulator"
        )
        app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// The Services or Costs tab, from the sidebar or the top tab bar —
    /// whichever the adaptable tab view is showing.
    private func openTab(_ label: String) {
        let tab = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d OR elementType == %d)",
                                  label,
                                  XCUIElement.ElementType.button.rawValue,
                                  XCUIElement.ElementType.cell.rawValue,
                                  XCUIElement.ElementType.staticText.rawValue))
            .firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "\(label) tab should exist")
        tab.tap()
    }

    private func row(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    private func detailTitle(_ title: String) -> XCUIElement {
        app.navigationBars[title]
    }

    // MARK: - Services

    @MainActor
    func testServiceRow_OpensDetailBesideTheList() throws {
        openTab("Services")
        let oilChange = row("Oil change")
        XCTAssertTrue(oilChange.waitForExistence(timeout: 10))

        oilChange.tap()

        XCTAssertTrue(detailTitle("Oil change").waitForExistence(timeout: 5), "Detail opens")
        XCTAssertTrue(oilChange.isHittable, "The list stays visible beside the detail")
        XCTAssertTrue(app.buttons["toolbar.addService"].isHittable, "The list column keeps its toolbar")
    }

    @MainActor
    func testAnotherRow_ReplacesTheDetailWithNoBackButton() throws {
        openTab("Services")
        let oilChange = row("Oil change")
        XCTAssertTrue(oilChange.waitForExistence(timeout: 10))
        oilChange.tap()
        XCTAssertTrue(detailTitle("Oil change").waitForExistence(timeout: 5))

        row("Tire rotation").tap()

        let tireRotation = detailTitle("Tire rotation")
        XCTAssertTrue(tireRotation.waitForExistence(timeout: 5), "The new row's detail shows")
        XCTAssertFalse(detailTitle("Oil change").exists, "…replacing the previous one")
        XCTAssertFalse(tireRotation.buttons["BackButton"].exists, "A replaced detail has nothing to go back to")
    }

    @MainActor
    func testDocumentLibrary_OpensInTheDetailColumn() throws {
        openTab("Services")
        let library = app.buttons["Document library"]
        // Scroll the list column, not the window's centre (the detail).
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        // Past a long history: the sample garage has two years of logs.
        for _ in 0..<25 where !(library.exists && library.isHittable) {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(library.isHittable, "Document library row should be reachable")

        library.tap()

        XCTAssertTrue(detailTitle("Documents").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toolbar.settings"].isHittable, "The list column stays beside Documents")
        XCTAssertFalse(detailTitle("Documents").buttons["BackButton"].exists, "Documents replaces, not pushes")
    }

    // MARK: - Costs

    @MainActor
    func testCosts_ShowsThePlaceholderUntilAnExpenseIsChosen() throws {
        openTab("Costs")
        XCTAssertTrue(app.staticTexts["No Expense Selected"].waitForExistence(timeout: 10))
    }

    // MARK: - Toolbar

    @MainActor
    func testSettings_OpensFromTheListColumn() throws {
        openTab("Services")
        let settings = app.buttons["toolbar.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))

        settings.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
