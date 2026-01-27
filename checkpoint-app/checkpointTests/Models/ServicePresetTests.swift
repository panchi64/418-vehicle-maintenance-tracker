//
//  ServicePresetTests.swift
//  checkpointTests
//
//  Unit tests for ServicePreset model and ServiceCategory enum
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServicePresetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure tests run with miles as the default
        DistanceSettings.shared.unit = .miles
    }

    override func tearDown() {
        // Reset to miles after tests
        DistanceSettings.shared.unit = .miles
        super.tearDown()
    }

    // MARK: - ServiceCategory Enum Tests

    func testServiceCategoryAllCases() {
        // Test that all expected cases exist
        let expectedCases: [ServiceCategory] = [
            .engine, .tires, .brakes, .transmission,
            .fluids, .electrical, .body, .other
        ]

        XCTAssertEqual(ServiceCategory.allCases.count, 8, "Should have exactly 8 service categories")
        XCTAssertEqual(ServiceCategory.allCases, expectedCases, "All cases should match expected values")
    }

    func testServiceCategoryRawValues() {
        XCTAssertEqual(ServiceCategory.engine.rawValue, "Engine")
        XCTAssertEqual(ServiceCategory.tires.rawValue, "Tires")
        XCTAssertEqual(ServiceCategory.brakes.rawValue, "Brakes")
        XCTAssertEqual(ServiceCategory.transmission.rawValue, "Transmission")
        XCTAssertEqual(ServiceCategory.fluids.rawValue, "Fluids")
        XCTAssertEqual(ServiceCategory.electrical.rawValue, "Electrical")
        XCTAssertEqual(ServiceCategory.body.rawValue, "Body")
        XCTAssertEqual(ServiceCategory.other.rawValue, "Other")
    }

    func testServiceCategoryIcons() {
        XCTAssertEqual(ServiceCategory.engine.icon, "engine.combustion")
        XCTAssertEqual(ServiceCategory.tires.icon, "tire")
        XCTAssertEqual(ServiceCategory.brakes.icon, "brake.signal")
        XCTAssertEqual(ServiceCategory.transmission.icon, "gear")
        XCTAssertEqual(ServiceCategory.fluids.icon, "drop.fill")
        XCTAssertEqual(ServiceCategory.electrical.icon, "bolt.car")
        XCTAssertEqual(ServiceCategory.body.icon, "car.side")
        XCTAssertEqual(ServiceCategory.other.icon, "wrench.and.screwdriver")
    }

    func testServiceCategoryEncodingDecoding() throws {
        // Test that enum can be encoded and decoded
        let category = ServiceCategory.engine
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(category)
        let decoded = try decoder.decode(ServiceCategory.self, from: encoded)

        XCTAssertEqual(decoded, category)
    }

    // MARK: - ServicePreset Initialization Tests

    func testServicePresetInitialization_WithAllParameters() {
        let preset = ServicePreset(
            name: "Oil Change",
            category: .engine,
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000,
            isCustom: false
        )

        XCTAssertEqual(preset.name, "Oil Change")
        XCTAssertEqual(preset.category, .engine)
        XCTAssertEqual(preset.defaultIntervalMonths, 6)
        XCTAssertEqual(preset.defaultIntervalMiles, 5000)
        XCTAssertFalse(preset.isCustom)
    }

    func testServicePresetInitialization_WithDefaultParameters() {
        let preset = ServicePreset(
            name: "Tire Rotation",
            category: .tires
        )

        XCTAssertEqual(preset.name, "Tire Rotation")
        XCTAssertEqual(preset.category, .tires)
        XCTAssertNil(preset.defaultIntervalMonths)
        XCTAssertNil(preset.defaultIntervalMiles)
        XCTAssertFalse(preset.isCustom, "isCustom should default to false")
    }

    func testServicePresetInitialization_CustomPreset() {
        let preset = ServicePreset(
            name: "Custom Service",
            category: .other,
            defaultIntervalMonths: 12,
            defaultIntervalMiles: 15000,
            isCustom: true
        )

        XCTAssertEqual(preset.name, "Custom Service")
        XCTAssertEqual(preset.category, .other)
        XCTAssertEqual(preset.defaultIntervalMonths, 12)
        XCTAssertEqual(preset.defaultIntervalMiles, 15000)
        XCTAssertTrue(preset.isCustom)
    }

    func testServicePresetInitialization_OnlyMonths() {
        let preset = ServicePreset(
            name: "Annual Inspection",
            category: .other,
            defaultIntervalMonths: 12
        )

        XCTAssertEqual(preset.defaultIntervalMonths, 12)
        XCTAssertNil(preset.defaultIntervalMiles)
    }

    func testServicePresetInitialization_OnlyMiles() {
        let preset = ServicePreset(
            name: "High Mileage Service",
            category: .engine,
            defaultIntervalMiles: 100000
        )

        XCTAssertNil(preset.defaultIntervalMonths)
        XCTAssertEqual(preset.defaultIntervalMiles, 100000)
    }

    // MARK: - intervalDescription Computed Property Tests

    func testIntervalDescription_BothMonthsAndMiles() {
        let preset = ServicePreset(
            name: "Oil Change",
            category: .engine,
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000
        )

        XCTAssertEqual(preset.intervalDescription, "Every 6 months or 5,000 miles")
    }

    func testIntervalDescription_OnlyMonths_Singular() {
        let preset = ServicePreset(
            name: "Monthly Check",
            category: .other,
            defaultIntervalMonths: 1
        )

        XCTAssertEqual(preset.intervalDescription, "Every 1 month")
    }

    func testIntervalDescription_OnlyMonths_Plural() {
        let preset = ServicePreset(
            name: "Annual Inspection",
            category: .other,
            defaultIntervalMonths: 12
        )

        XCTAssertEqual(preset.intervalDescription, "Every 12 months")
    }

    func testIntervalDescription_OnlyMiles() {
        let preset = ServicePreset(
            name: "High Mileage Service",
            category: .engine,
            defaultIntervalMiles: 100000
        )

        XCTAssertEqual(preset.intervalDescription, "Every 100,000 miles")
    }

    func testIntervalDescription_NoIntervals() {
        let preset = ServicePreset(
            name: "As Needed Service",
            category: .other
        )

        XCTAssertNil(preset.intervalDescription, "Should return nil when no intervals are set")
    }

    func testIntervalDescription_WithLargeMileage() {
        let preset = ServicePreset(
            name: "Major Service",
            category: .engine,
            defaultIntervalMonths: 24,
            defaultIntervalMiles: 50000
        )

        XCTAssertEqual(preset.intervalDescription, "Every 24 months or 50,000 miles")
    }

    func testIntervalDescription_WithSmallMileage() {
        let preset = ServicePreset(
            name: "Frequent Service",
            category: .fluids,
            defaultIntervalMonths: 3,
            defaultIntervalMiles: 3000
        )

        XCTAssertEqual(preset.intervalDescription, "Every 3 months or 3,000 miles")
    }

    // MARK: - isCustom Flag Tests

    func testIsCustomFlag_DefaultIsFalse() {
        let preset = ServicePreset(
            name: "Standard Service",
            category: .engine
        )

        XCTAssertFalse(preset.isCustom)
    }

    func testIsCustomFlag_CanBeSetToTrue() {
        let preset = ServicePreset(
            name: "Custom Service",
            category: .other,
            isCustom: true
        )

        XCTAssertTrue(preset.isCustom)
    }

    func testIsCustomFlag_CanBeSetToFalse() {
        let preset = ServicePreset(
            name: "Standard Service",
            category: .engine,
            isCustom: false
        )

        XCTAssertFalse(preset.isCustom)
    }

    // MARK: - Integration Tests

    func testServicePreset_AllCategories() {
        // Test creating presets for all categories
        for category in ServiceCategory.allCases {
            let preset = ServicePreset(
                name: "Test \(category.rawValue) Service",
                category: category,
                defaultIntervalMonths: 6,
                defaultIntervalMiles: 5000
            )

            XCTAssertEqual(preset.category, category)
            XCTAssertNotNil(preset.category.icon, "Category \(category.rawValue) should have an icon")
        }
    }

    func testServicePreset_MutabilityOfProperties() {
        let preset = ServicePreset(
            name: "Oil Change",
            category: .engine,
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000,
            isCustom: false
        )

        // Test that properties can be modified
        preset.name = "Full Synthetic Oil Change"
        preset.category = .fluids
        preset.defaultIntervalMonths = 12
        preset.defaultIntervalMiles = 10000
        preset.isCustom = true

        XCTAssertEqual(preset.name, "Full Synthetic Oil Change")
        XCTAssertEqual(preset.category, .fluids)
        XCTAssertEqual(preset.defaultIntervalMonths, 12)
        XCTAssertEqual(preset.defaultIntervalMiles, 10000)
        XCTAssertTrue(preset.isCustom)
    }

    func testServicePreset_IntervalDescriptionUpdatesWithPropertyChanges() {
        let preset = ServicePreset(
            name: "Service",
            category: .other,
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000
        )

        XCTAssertEqual(preset.intervalDescription, "Every 6 months or 5,000 miles")

        // Change to only months
        preset.defaultIntervalMiles = nil
        XCTAssertEqual(preset.intervalDescription, "Every 6 months")

        // Change to only miles
        preset.defaultIntervalMonths = nil
        preset.defaultIntervalMiles = 10000
        XCTAssertEqual(preset.intervalDescription, "Every 10,000 miles")

        // Remove all intervals
        preset.defaultIntervalMiles = nil
        XCTAssertNil(preset.intervalDescription)
    }
}
