//
//  SettingsViewTests.swift
//  checkpointTests
//
//  Tests for SettingsView and DistanceUnitPicker
//

import XCTest
import SwiftUI
@testable import checkpoint

@MainActor
final class SettingsViewTests: XCTestCase {

    private let unitKey = "distanceUnit"
    private let appGroupID = AppGroupConstants.iPhoneWidget

    override func setUp() {
        super.setUp()
        // Reset to default before each test
        UserDefaults.standard.removeObject(forKey: unitKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: unitKey)
        DistanceSettings.registerDefaults()
    }

    override func tearDown() {
        // Reset to miles after tests
        DistanceSettings.shared.unit = .miles
        super.tearDown()
    }

    // MARK: - DistanceUnitPicker Tests

    func testPickerDisplaysBothOptions() {
        // Verify both units are available in allCases
        XCTAssertEqual(DistanceUnit.allCases.count, 2)
        XCTAssertTrue(DistanceUnit.allCases.contains(.miles))
        XCTAssertTrue(DistanceUnit.allCases.contains(.kilometers))
    }

    func testSelectionUpdatesDistanceSettings() {
        let settings = DistanceSettings.shared

        // Initially should be miles (default)
        XCTAssertEqual(settings.unit, .miles)

        // Change to kilometers
        settings.unit = .kilometers
        XCTAssertEqual(settings.unit, .kilometers)

        // Verify persistence
        let rawValue = UserDefaults.standard.string(forKey: unitKey)
        XCTAssertEqual(rawValue, "kilometers")
    }

    func testUnitDisplayNames() {
        XCTAssertEqual(DistanceUnit.miles.displayName, "Miles")
        XCTAssertEqual(DistanceUnit.kilometers.displayName, "Kilometers")
    }

    // MARK: - SettingsView Integration Tests

    func testSettingsViewCanBeCreated() {
        // This is a basic smoke test to ensure the view can be instantiated
        let view = SettingsView()
        XCTAssertNotNil(view)
    }

    func testDistanceUnitPickerCanBeCreated() {
        // Basic smoke test for the picker
        let picker = DistanceUnitPickerView()
        XCTAssertNotNil(picker)
    }
}
