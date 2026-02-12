//
//  AppGroupConstantsTests.swift
//  checkpointTests
//
//  Tests for AppGroupConstants — verify constant values and uniqueness
//

import XCTest
@testable import checkpoint

final class AppGroupConstantsTests: XCTestCase {
    func testIPhoneWidgetGroupID_matchesExpectedValue() {
        XCTAssertEqual(AppGroupConstants.iPhoneWidget, "group.com.418-studio.checkpoint.shared")
    }

    func testWatchAppGroupID_matchesExpectedValue() {
        XCTAssertEqual(AppGroupConstants.watchApp, "group.com.418-studio.checkpoint.watch")
    }

    func testGroupIDs_areDifferent() {
        XCTAssertNotEqual(AppGroupConstants.iPhoneWidget, AppGroupConstants.watchApp)
    }
}
