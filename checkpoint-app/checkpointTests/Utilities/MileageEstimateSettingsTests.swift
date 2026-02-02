//
//  MileageEstimateSettingsTests.swift
//  checkpointTests
//
//  Tests for MileageEstimateSettings
//

import XCTest
@testable import checkpoint

@MainActor
final class MileageEstimateSettingsTests: XCTestCase {

    private let showEstimatesKey = "showMileageEstimates"

    override func tearDown() {
        // Reset to default after each test
        MileageEstimateSettings.shared.showEstimates = true
        super.tearDown()
    }

    // MARK: - Default Value Tests

    func testShowEstimates_DefaultsToTrue() {
        // Fresh instance should default to true
        XCTAssertTrue(MileageEstimateSettings.shared.showEstimates)
    }

    // MARK: - Persistence Tests

    func testShowEstimates_WhenSetToFalse_PersistsValue() {
        MileageEstimateSettings.shared.showEstimates = false

        XCTAssertFalse(MileageEstimateSettings.shared.showEstimates)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: showEstimatesKey))
    }

    func testShowEstimates_WhenSetToTrue_PersistsValue() {
        // First set to false
        MileageEstimateSettings.shared.showEstimates = false

        // Then set back to true
        MileageEstimateSettings.shared.showEstimates = true

        XCTAssertTrue(MileageEstimateSettings.shared.showEstimates)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: showEstimatesKey))
    }

    // MARK: - Toggle Tests

    func testShowEstimates_CanToggle() {
        let initial = MileageEstimateSettings.shared.showEstimates

        MileageEstimateSettings.shared.showEstimates = !initial
        XCTAssertEqual(MileageEstimateSettings.shared.showEstimates, !initial)

        MileageEstimateSettings.shared.showEstimates = initial
        XCTAssertEqual(MileageEstimateSettings.shared.showEstimates, initial)
    }

    // MARK: - Singleton Tests

    func testShared_ReturnsSameInstance() {
        let instance1 = MileageEstimateSettings.shared
        let instance2 = MileageEstimateSettings.shared

        XCTAssertTrue(instance1 === instance2, "Shared should return the same instance")
    }
}
