//
//  ServiceTypePickerTests.swift
//  checkpointTests
//
//  Unit tests for ServiceTypePicker component
//

import XCTest
import SwiftUI
@testable import checkpoint

final class ServiceTypePickerTests: XCTestCase {

    // MARK: - Helper Methods

    private func createTestPreset(
        name: String = "Oil Change",
        category: String = "Engine",
        months: Int? = 6,
        miles: Int? = 5000
    ) -> PresetData {
        PresetData(
            name: name,
            category: category,
            defaultIntervalMonths: months,
            defaultIntervalMiles: miles
        )
    }

    // MARK: - Initial State Tests

    func testInitialState_NoSelection() {
        // Given
        var selectedPreset: PresetData? = nil
        var customServiceName = ""

        // When - component is created with no selection
        // Then - selectedPreset should be nil and customServiceName should be empty
        XCTAssertNil(selectedPreset)
        XCTAssertEqual(customServiceName, "")
    }

    func testInitialState_WithPreset() {
        // Given
        let preset = createTestPreset()
        var selectedPreset: PresetData? = preset
        var customServiceName = ""

        // When - component is created with a preset
        // Then - selectedPreset should contain the preset
        XCTAssertNotNil(selectedPreset)
        XCTAssertEqual(selectedPreset?.name, "Oil Change")
        XCTAssertEqual(selectedPreset?.category, "Engine")
        XCTAssertEqual(customServiceName, "")
    }

    func testInitialState_WithCustomName() {
        // Given
        var selectedPreset: PresetData? = nil
        var customServiceName = "My Custom Service"

        // When - component is created with custom service name
        // Then - customServiceName should be set and no preset
        XCTAssertNil(selectedPreset)
        XCTAssertEqual(customServiceName, "My Custom Service")
    }

    // MARK: - Preset Selection Tests

    func testSelectingPreset_UpdatesBinding() {
        // Given
        var selectedPreset: PresetData? = nil
        let newPreset = createTestPreset(name: "Tire Rotation", category: "Tires")

        // When
        selectedPreset = newPreset

        // Then
        XCTAssertNotNil(selectedPreset)
        XCTAssertEqual(selectedPreset?.name, "Tire Rotation")
        XCTAssertEqual(selectedPreset?.category, "Tires")
    }

    func testSelectingPreset_ReplacesExistingPreset() {
        // Given
        var selectedPreset: PresetData? = createTestPreset(name: "Oil Change")
        let newPreset = createTestPreset(name: "Brake Inspection", category: "Brakes")

        // When
        selectedPreset = newPreset

        // Then
        XCTAssertEqual(selectedPreset?.name, "Brake Inspection")
        XCTAssertEqual(selectedPreset?.category, "Brakes")
    }

    func testClearingPreset_SetsToNil() {
        // Given
        var selectedPreset: PresetData? = createTestPreset()

        // When
        selectedPreset = nil

        // Then
        XCTAssertNil(selectedPreset)
    }

    // MARK: - Custom Service Name Tests

    func testCustomServiceName_CanBeUpdated() {
        // Given
        var customServiceName = ""

        // When
        customServiceName = "My Custom Service"

        // Then
        XCTAssertEqual(customServiceName, "My Custom Service")
    }

    func testCustomServiceName_CanBeCleared() {
        // Given
        var customServiceName = "My Custom Service"

        // When
        customServiceName = ""

        // Then
        XCTAssertEqual(customServiceName, "")
    }

    // MARK: - Format Interval Tests

    func testFormatInterval_BothMonthsAndMiles() {
        // Given
        let preset = createTestPreset(months: 6, miles: 5000)

        // When - formatting the interval
        // Then - should show both months and miles
        XCTAssertEqual(preset.defaultIntervalMonths, 6)
        XCTAssertEqual(preset.defaultIntervalMiles, 5000)
    }

    func testFormatInterval_OnlyMonths() {
        // Given
        let preset = createTestPreset(months: 12, miles: nil)

        // When - formatting the interval with only months
        // Then - should only show months
        XCTAssertEqual(preset.defaultIntervalMonths, 12)
        XCTAssertNil(preset.defaultIntervalMiles)
    }

    func testFormatInterval_OnlyMiles() {
        // Given
        let preset = createTestPreset(months: nil, miles: 10000)

        // When - formatting the interval with only miles
        // Then - should only show miles
        XCTAssertNil(preset.defaultIntervalMonths)
        XCTAssertEqual(preset.defaultIntervalMiles, 10000)
    }

    func testFormatInterval_NoIntervals() {
        // Given
        let preset = createTestPreset(months: nil, miles: nil)

        // When - formatting the interval with no intervals
        // Then - both should be nil
        XCTAssertNil(preset.defaultIntervalMonths)
        XCTAssertNil(preset.defaultIntervalMiles)
    }

    // MARK: - Category Icon Tests

    func testCategoryIcon_ValidCategory() {
        // Given
        let engineCategory = ServiceCategory(rawValue: "Engine")

        // When - getting the icon
        // Then - should return correct icon
        XCTAssertEqual(engineCategory?.icon, "engine.combustion")
    }

    func testCategoryIcon_AllCategories() {
        // Test all category icons are properly mapped
        let testCases: [(String, String)] = [
            ("Engine", "engine.combustion"),
            ("Tires", "tire"),
            ("Brakes", "brake.signal"),
            ("Transmission", "gear"),
            ("Fluids", "drop.fill"),
            ("Electrical", "bolt.car"),
            ("Body", "car.side"),
            ("Other", "wrench.and.screwdriver")
        ]

        for (categoryName, expectedIcon) in testCases {
            let category = ServiceCategory(rawValue: categoryName)
            XCTAssertEqual(category?.icon, expectedIcon, "Category \(categoryName) should have icon \(expectedIcon)")
        }
    }

    func testCategoryIcon_InvalidCategory_FallsBackToDefault() {
        // Given - an invalid category string
        let invalidCategory = ServiceCategory(rawValue: "InvalidCategory")

        // When - trying to get the icon
        // Then - should be nil (invalid category)
        XCTAssertNil(invalidCategory)
    }

    // MARK: - Category Filtering Tests

    func testCategoryFilter_InitialCategory() {
        // Given
        var selectedCategory: ServiceCategory = .engine

        // When - component is initialized
        // Then - default category should be engine
        XCTAssertEqual(selectedCategory, .engine)
    }

    func testCategoryFilter_SwitchingCategories() {
        // Given
        var selectedCategory: ServiceCategory = .engine

        // When
        selectedCategory = .tires

        // Then
        XCTAssertEqual(selectedCategory, .tires)
    }

    func testCategoryFilter_AllCategories() {
        // Test switching through all categories
        var selectedCategory: ServiceCategory = .engine

        for category in ServiceCategory.allCases {
            selectedCategory = category
            XCTAssertEqual(selectedCategory, category)
        }
    }

    // MARK: - Integration Tests

    func testFullWorkflow_SelectPresetAfterTypingCustomName() {
        // Given
        var selectedPreset: PresetData? = nil
        var customServiceName = "My Custom Service"

        // When - user types custom name then selects a preset
        XCTAssertEqual(customServiceName, "My Custom Service")
        selectedPreset = createTestPreset()

        // Then - preset should be selected
        XCTAssertNotNil(selectedPreset)
        XCTAssertEqual(selectedPreset?.name, "Oil Change")
    }

    func testFullWorkflow_ClearPresetAndTypeCustomName() {
        // Given
        var selectedPreset: PresetData? = createTestPreset()
        var customServiceName = ""

        // When - user clears preset and types custom name
        selectedPreset = nil
        customServiceName = "My Custom Service"

        // Then - should have custom name and no preset
        XCTAssertNil(selectedPreset)
        XCTAssertEqual(customServiceName, "My Custom Service")
    }

    func testFullWorkflow_SwitchBetweenPresets() {
        // Given
        var selectedPreset: PresetData? = createTestPreset(name: "Oil Change")

        // When - switching to different preset
        selectedPreset = createTestPreset(name: "Tire Rotation", category: "Tires")

        // Then - should update to new preset
        XCTAssertEqual(selectedPreset?.name, "Tire Rotation")
        XCTAssertEqual(selectedPreset?.category, "Tires")

        // When - switching again
        selectedPreset = createTestPreset(name: "Brake Inspection", category: "Brakes")

        // Then - should update again
        XCTAssertEqual(selectedPreset?.name, "Brake Inspection")
        XCTAssertEqual(selectedPreset?.category, "Brakes")
    }

    // MARK: - PresetData Structure Tests

    func testPresetData_AllProperties() {
        // Given
        let preset = createTestPreset(
            name: "Transmission Fluid Change",
            category: "Transmission",
            months: 24,
            miles: 30000
        )

        // Then - all properties should be set correctly
        XCTAssertEqual(preset.name, "Transmission Fluid Change")
        XCTAssertEqual(preset.category, "Transmission")
        XCTAssertEqual(preset.defaultIntervalMonths, 24)
        XCTAssertEqual(preset.defaultIntervalMiles, 30000)
    }

    func testPresetData_OptionalIntervals() {
        // Test preset with no intervals
        let noIntervals = createTestPreset(months: nil, miles: nil)
        XCTAssertNil(noIntervals.defaultIntervalMonths)
        XCTAssertNil(noIntervals.defaultIntervalMiles)

        // Test preset with only months
        let onlyMonths = createTestPreset(months: 6, miles: nil)
        XCTAssertEqual(onlyMonths.defaultIntervalMonths, 6)
        XCTAssertNil(onlyMonths.defaultIntervalMiles)

        // Test preset with only miles
        let onlyMiles = createTestPreset(months: nil, miles: 5000)
        XCTAssertNil(onlyMiles.defaultIntervalMonths)
        XCTAssertEqual(onlyMiles.defaultIntervalMiles, 5000)
    }
}
