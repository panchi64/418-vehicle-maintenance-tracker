//
//  GestureInteractionTests.swift
//  checkpointUITests
//
//  UI tests for gesture interactions - tap vs swipe on cards in swipeable contexts
//

import XCTest

final class GestureInteractionTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tap Gesture Tests

    @MainActor
    func testTapOnCard_OpensServiceDetail() throws {
        // Skip if no vehicle/services exist (app may be empty on first launch)
        // Look for any card that might be tappable
        let homeTab = app.buttons["HOME"]

        // Ensure we're on home tab
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
        }

        // Wait for content to load
        sleep(1)

        // Look for a NextUpCard or any service card
        // These typically contain service names or status text
        let serviceCards = app.staticTexts.matching(identifier: "ServiceCard")

        if serviceCards.count > 0 {
            let firstCard = serviceCards.firstMatch
            firstCard.tap()

            // Verify navigation occurred (detail view should appear)
            // Service detail views typically have a "Mark Done" or edit button
            let detailIndicator = app.buttons["Mark Done"].exists ||
                                  app.navigationBars.buttons["Edit"].exists ||
                                  app.staticTexts["SERVICE DETAILS"].exists

            XCTAssertTrue(detailIndicator, "Tapping a card should navigate to detail view")
        } else {
            // No services to test - skip gracefully
            throw XCTSkip("No service cards found to test tap interaction")
        }
    }

    // MARK: - Tab Switching Tests

    @MainActor
    func testSwipeLeft_SwitchesToNextTab() throws {
        // Start on Home tab
        let homeTab = app.buttons["HOME"]
        if homeTab.exists {
            homeTab.tap()
        }

        sleep(1)

        // Get current tab state
        let servicesTabBefore = app.buttons["SERVICES"].isSelected
        let costsTabBefore = app.buttons["COSTS"].isSelected

        // Perform swipe left gesture
        let window = app.windows.firstMatch
        window.swipeLeft()

        sleep(1)

        // After swiping left from Home, we should be on Costs tab
        // (tabs are ordered: Services, Home, Costs)
        let costsTab = app.buttons["COSTS"]
        if costsTab.exists {
            XCTAssertTrue(costsTab.isSelected, "Swiping left from Home should switch to Costs tab")
        }
    }

    @MainActor
    func testSwipeRight_SwitchesToPreviousTab() throws {
        // Start on Home tab
        let homeTab = app.buttons["HOME"]
        if homeTab.exists {
            homeTab.tap()
        }

        sleep(1)

        // Perform swipe right gesture
        let window = app.windows.firstMatch
        window.swipeRight()

        sleep(1)

        // After swiping right from Home, we should be on Services tab
        let servicesTab = app.buttons["SERVICES"]
        if servicesTab.exists {
            XCTAssertTrue(servicesTab.isSelected, "Swiping right from Home should switch to Services tab")
        }
    }

    // MARK: - Swipe on Card Should Not Open Detail

    @MainActor
    func testSwipeOnCard_DoesNotOpenDetail() throws {
        // Start on Home tab
        let homeTab = app.buttons["HOME"]
        if homeTab.exists {
            homeTab.tap()
        }

        sleep(1)

        // Look for any card element
        // The key test is that swiping changes tabs without opening detail
        let window = app.windows.firstMatch

        // Perform a horizontal swipe (tab change gesture)
        window.swipeLeft()

        sleep(1)

        // Verify we changed tabs (not opened a detail view)
        // If we're in a detail view, there would be a back button or "Mark Done"
        let isInDetailView = app.navigationBars.buttons.element(boundBy: 0).label == "Back" ||
                             app.buttons["Mark Done"].exists

        XCTAssertFalse(isInDetailView, "Swiping should switch tabs, not open service detail")

        // Verify we're on Costs tab now (swiped left from Home)
        let costsTab = app.buttons["COSTS"]
        if costsTab.exists {
            XCTAssertTrue(costsTab.isSelected, "Should be on Costs tab after swiping left")
        }
    }

    // MARK: - Scroll Tests

    @MainActor
    func testVerticalScroll_DoesNotSwitchTabs() throws {
        // Go to Services tab (likely to have scrollable content)
        let servicesTab = app.buttons["SERVICES"]
        if servicesTab.exists {
            servicesTab.tap()
        }

        sleep(1)

        // Perform vertical scroll
        let window = app.windows.firstMatch
        window.swipeUp()

        sleep(1)

        // Should still be on Services tab
        if servicesTab.exists {
            XCTAssertTrue(servicesTab.isSelected, "Vertical scroll should not switch tabs")
        }
    }

    // MARK: - Tab Bar Direct Tap

    @MainActor
    func testTabBarTap_SwitchesToCorrectTab() throws {
        // Tap Services tab
        let servicesTab = app.buttons["SERVICES"]
        if servicesTab.exists {
            servicesTab.tap()
            sleep(1)
            XCTAssertTrue(servicesTab.isSelected, "Tapping Services tab should select it")
        }

        // Tap Costs tab
        let costsTab = app.buttons["COSTS"]
        if costsTab.exists {
            costsTab.tap()
            sleep(1)
            XCTAssertTrue(costsTab.isSelected, "Tapping Costs tab should select it")
        }

        // Tap Home tab
        let homeTab = app.buttons["HOME"]
        if homeTab.exists {
            homeTab.tap()
            sleep(1)
            XCTAssertTrue(homeTab.isSelected, "Tapping Home tab should select it")
        }
    }
}
