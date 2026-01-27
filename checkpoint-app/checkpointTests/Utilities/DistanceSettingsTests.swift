//
//  DistanceSettingsTests.swift
//  checkpointTests
//
//  Tests for DistanceSettings persistence and widget access
//

import XCTest
@testable import checkpoint

@MainActor
final class DistanceSettingsTests: XCTestCase {

    private let unitKey = "distanceUnit"
    private let appGroupID = "group.com.418-studio.checkpoint.shared"

    override func setUp() {
        super.setUp()
        // Reset to default before each test
        UserDefaults.standard.removeObject(forKey: unitKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: unitKey)
    }

    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: unitKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: unitKey)
        super.tearDown()
    }

    // MARK: - Default Value Tests

    func testDefaultValueIsMiles() {
        // After registerDefaults, the default should be miles
        DistanceSettings.registerDefaults()

        // Read directly from UserDefaults to verify default registration
        let rawValue = UserDefaults.standard.string(forKey: unitKey)
        XCTAssertEqual(rawValue, "miles", "Default value should be miles")
    }

    // MARK: - Persistence Tests

    func testUnitPersistsToStandardUserDefaults() {
        let settings = DistanceSettings.shared

        // Start with miles to ensure clean state
        settings.unit = .miles

        // Change to kilometers
        settings.unit = .kilometers

        // Wait briefly for persistence (UserDefaults batches writes)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // Synchronize to ensure writes are flushed
        UserDefaults.standard.synchronize()

        // Verify it's persisted
        let rawValue = UserDefaults.standard.string(forKey: unitKey)
        XCTAssertEqual(rawValue, "kilometers", "Unit should persist to standard UserDefaults")
    }

    func testUnitPersistsToAppGroup() {
        let settings = DistanceSettings.shared

        // Change to kilometers
        settings.unit = .kilometers

        // Verify it's synced to App Group
        let rawValue = UserDefaults(suiteName: appGroupID)?.string(forKey: unitKey)
        XCTAssertEqual(rawValue, "kilometers", "Unit should sync to App Group UserDefaults")
    }

    // MARK: - Widget Access Tests

    func testWidgetUnitReadsFromAppGroup() {
        // Set value directly in App Group (simulating main app)
        UserDefaults(suiteName: appGroupID)?.set("kilometers", forKey: unitKey)

        // Widget should read it
        let widgetUnit = DistanceSettings.widgetUnit()
        XCTAssertEqual(widgetUnit, .kilometers, "Widget should read from App Group")
    }

    func testWidgetUnitDefaultsToMilesWhenNoValue() {
        // Don't set any value
        let widgetUnit = DistanceSettings.widgetUnit()
        XCTAssertEqual(widgetUnit, .miles, "Widget should default to miles")
    }

    // MARK: - Singleton Tests

    func testSharedInstanceReturnsSameInstance() {
        let instance1 = DistanceSettings.shared
        let instance2 = DistanceSettings.shared
        XCTAssertTrue(instance1 === instance2, "Shared should return same instance")
    }

    // MARK: - Change Observation Tests

    func testUnitChangeUpdatesValue() {
        let settings = DistanceSettings.shared

        // Start with miles
        settings.unit = .miles
        XCTAssertEqual(settings.unit, .miles)

        // Change to kilometers
        settings.unit = .kilometers
        XCTAssertEqual(settings.unit, .kilometers)

        // Change back to miles
        settings.unit = .miles
        XCTAssertEqual(settings.unit, .miles)
    }
}
