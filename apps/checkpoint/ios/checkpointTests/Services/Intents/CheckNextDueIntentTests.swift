//
//  CheckNextDueIntentTests.swift
//  checkpointTests
//
//  Tests for CheckNextDueIntent dialog formatting
//

import XCTest
@testable import checkpoint

final class CheckNextDueIntentTests: XCTestCase {
    private let appGroupID = AppGroupConstants.iPhoneWidget
    private let widgetDataKey = "widgetData"

    override func tearDown() {
        // Clean up test data
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: widgetDataKey)
        super.tearDown()
    }

    // MARK: - SiriServiceStatus Tests

    func test_siriServiceStatus_dialogPrefix_overdue() {
        XCTAssertEqual(SiriServiceStatus.overdue.dialogPrefix, "Overdue")
    }

    func test_siriServiceStatus_dialogPrefix_dueSoon() {
        XCTAssertEqual(SiriServiceStatus.dueSoon.dialogPrefix, "Due soon")
    }

    func test_siriServiceStatus_dialogPrefix_good() {
        XCTAssertEqual(SiriServiceStatus.good.dialogPrefix, "Coming up")
    }

    func test_siriServiceStatus_dialogPrefix_neutral() {
        XCTAssertEqual(SiriServiceStatus.neutral.dialogPrefix, "Scheduled")
    }

    // MARK: - Intent Creation Tests

    func test_checkNextDueIntent_hasCorrectTitle() {
        // The title should be set correctly
        let title = CheckNextDueIntent.title
        XCTAssertNotNil(title)
    }

    func test_checkNextDueIntent_vehicleParameterIsOptional() {
        // Should be able to create intent without vehicle
        let intent = CheckNextDueIntent()
        XCTAssertNil(intent.vehicle)
    }
}
