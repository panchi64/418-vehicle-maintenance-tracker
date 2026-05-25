//
//  AnalyticsSettingsTests.swift
//  checkpointTests
//
//  Tests for analytics settings persistence and defaults
//

import XCTest
@testable import checkpoint

final class AnalyticsSettingsTests: XCTestCase {

    private let testSuite = "com.418-studio.checkpoint.analyticsTests"

    override func setUp() {
        super.setUp()
        // Clean up test defaults
        UserDefaults.standard.removeObject(forKey: "analyticsEnabled")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "analyticsEnabled")
        super.tearDown()
    }

    // MARK: - Default Values

    @MainActor
    func test_registerDefaults_setsEnabledToTrue() {
        // Remove any existing value first
        UserDefaults.standard.removeObject(forKey: "analyticsEnabled")
        AnalyticsSettings.registerDefaults()

        let settings = AnalyticsSettings.shared
        XCTAssertTrue(settings.isEnabled, "Analytics should be enabled by default (opt-out model)")
    }

    // MARK: - Persistence

    @MainActor
    func test_isEnabled_persistsToUserDefaults() {
        let settings = AnalyticsSettings.shared

        settings.isEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "analyticsEnabled"),
                       "Disabling analytics should persist to UserDefaults")

        settings.isEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "analyticsEnabled"),
                      "Enabling analytics should persist to UserDefaults")
    }

    @MainActor
    func test_isEnabled_readsFromUserDefaults() {
        UserDefaults.standard.set(false, forKey: "analyticsEnabled")
        XCTAssertFalse(AnalyticsSettings.shared.isEnabled,
                       "Should read false from UserDefaults")

        UserDefaults.standard.set(true, forKey: "analyticsEnabled")
        XCTAssertTrue(AnalyticsSettings.shared.isEnabled,
                      "Should read true from UserDefaults")
    }
}
