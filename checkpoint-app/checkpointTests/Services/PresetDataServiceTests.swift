//
//  PresetDataServiceTests.swift
//  checkpointTests
//
//  Unit tests for PresetDataService
//

import XCTest
@testable import checkpoint

final class PresetDataServiceTests: XCTestCase {

    var service: PresetDataService!

    override func setUp() {
        super.setUp()
        service = PresetDataService.shared
        // Reset cache by creating a new instance for testing
        // Since we're using shared singleton, we test with it directly
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Load Presets Tests

    func testLoadPresetsReturnsCorrectCount() {
        // When
        let presets = service.loadPresets()

        // Then
        XCTAssertEqual(presets.count, 10, "Should load exactly 10 presets from JSON")
    }

    func testLoadPresetsReturnsCorrectPresetNames() {
        // When
        let presets = service.loadPresets()
        let presetNames = Set(presets.map { $0.name })

        // Then
        let expectedNames: Set<String> = [
            "Oil Change",
            "Tire Rotation",
            "Brake Inspection",
            "Air Filter",
            "Cabin Air Filter",
            "Transmission Fluid",
            "Coolant Flush",
            "Spark Plugs",
            "Battery Check",
            "Wiper Blades"
        ]

        XCTAssertEqual(presetNames, expectedNames, "Should contain all expected preset names")
    }

    func testLoadPresetsReturnsValidData() {
        // When
        let presets = service.loadPresets()

        // Then
        XCTAssertFalse(presets.isEmpty, "Presets should not be empty")

        for preset in presets {
            XCTAssertFalse(preset.name.isEmpty, "Preset name should not be empty")
            XCTAssertFalse(preset.category.isEmpty, "Preset category should not be empty")
        }
    }

    func testLoadPresetsContainsOilChange() {
        // When
        let presets = service.loadPresets()
        let oilChange = presets.first { $0.name == "Oil Change" }

        // Then
        XCTAssertNotNil(oilChange, "Should contain Oil Change preset")
        XCTAssertEqual(oilChange?.category, "engine")
        XCTAssertEqual(oilChange?.defaultIntervalMonths, 6)
        XCTAssertEqual(oilChange?.defaultIntervalMiles, 5000)
    }

    func testLoadPresetsContainsBatteryCheck() {
        // When
        let presets = service.loadPresets()
        let batteryCheck = presets.first { $0.name == "Battery Check" }

        // Then
        XCTAssertNotNil(batteryCheck, "Should contain Battery Check preset")
        XCTAssertEqual(batteryCheck?.category, "electrical")
        XCTAssertEqual(batteryCheck?.defaultIntervalMonths, 12)
        XCTAssertNil(batteryCheck?.defaultIntervalMiles, "Battery Check should have nil mileage interval")
    }

    // MARK: - Category Filter Tests

    func testPresetsForCategoryEngine() {
        // When
        let enginePresets = service.presets(for: .engine)

        // Then
        XCTAssertEqual(enginePresets.count, 4, "Should have 4 engine presets")

        let names = Set(enginePresets.map { $0.name })
        XCTAssertTrue(names.contains("Oil Change"))
        XCTAssertTrue(names.contains("Air Filter"))
        XCTAssertTrue(names.contains("Cabin Air Filter"))
        XCTAssertTrue(names.contains("Spark Plugs"))
    }

    func testPresetsForCategoryTires() {
        // When
        let tiresPresets = service.presets(for: .tires)

        // Then
        XCTAssertEqual(tiresPresets.count, 1, "Should have 1 tires preset")
        XCTAssertEqual(tiresPresets.first?.name, "Tire Rotation")
    }

    func testPresetsForCategoryBrakes() {
        // When
        let brakesPresets = service.presets(for: .brakes)

        // Then
        XCTAssertEqual(brakesPresets.count, 1, "Should have 1 brakes preset")
        XCTAssertEqual(brakesPresets.first?.name, "Brake Inspection")
    }

    func testPresetsForCategoryTransmission() {
        // When
        let transmissionPresets = service.presets(for: .transmission)

        // Then
        XCTAssertEqual(transmissionPresets.count, 1, "Should have 1 transmission preset")
        XCTAssertEqual(transmissionPresets.first?.name, "Transmission Fluid")
    }

    func testPresetsForCategoryFluids() {
        // When
        let fluidsPresets = service.presets(for: .fluids)

        // Then
        XCTAssertEqual(fluidsPresets.count, 1, "Should have 1 fluids preset")
        XCTAssertEqual(fluidsPresets.first?.name, "Coolant Flush")
    }

    func testPresetsForCategoryElectrical() {
        // When
        let electricalPresets = service.presets(for: .electrical)

        // Then
        XCTAssertEqual(electricalPresets.count, 1, "Should have 1 electrical preset")
        XCTAssertEqual(electricalPresets.first?.name, "Battery Check")
    }

    func testPresetsForCategoryBody() {
        // When
        let bodyPresets = service.presets(for: .body)

        // Then
        XCTAssertEqual(bodyPresets.count, 1, "Should have 1 body preset")
        XCTAssertEqual(bodyPresets.first?.name, "Wiper Blades")
    }

    func testPresetsForCategoryOther() {
        // When
        let otherPresets = service.presets(for: .other)

        // Then
        XCTAssertEqual(otherPresets.count, 0, "Should have 0 other presets")
    }

    // MARK: - Available Categories Tests

    func testAvailableCategoriesReturnsCorrectSet() {
        // When
        let categories = service.availableCategories()

        // Then
        XCTAssertEqual(categories.count, 7, "Should have 7 categories with presets")

        let categorySet = Set(categories)
        XCTAssertTrue(categorySet.contains(.engine))
        XCTAssertTrue(categorySet.contains(.tires))
        XCTAssertTrue(categorySet.contains(.brakes))
        XCTAssertTrue(categorySet.contains(.transmission))
        XCTAssertTrue(categorySet.contains(.fluids))
        XCTAssertTrue(categorySet.contains(.electrical))
        XCTAssertTrue(categorySet.contains(.body))
        XCTAssertFalse(categorySet.contains(.other), "Other category should not be in available categories")
    }

    func testAvailableCategoriesDoesNotIncludeEmptyCategories() {
        // When
        let categories = service.availableCategories()

        // Then
        XCTAssertFalse(categories.contains(.other), "Should not include categories with no presets")
    }

    // MARK: - Caching Tests

    func testLoadPresetsReturnsCachedData() {
        // Given
        let firstLoad = service.loadPresets()
        let firstCount = firstLoad.count

        // When - Load again
        let secondLoad = service.loadPresets()
        let secondCount = secondLoad.count

        // Then - Should return same data (from cache)
        XCTAssertEqual(firstCount, secondCount, "Second load should return same count from cache")
        XCTAssertEqual(firstLoad.map { $0.name }, secondLoad.map { $0.name }, "Should return same presets from cache")
    }

    func testCachingBehaviorAcrossMultipleCalls() {
        // When - Make multiple calls
        let load1 = service.loadPresets()
        let load2 = service.loadPresets()
        let load3 = service.loadPresets()

        // Then - All should return same data
        XCTAssertEqual(load1.count, load2.count)
        XCTAssertEqual(load2.count, load3.count)
        XCTAssertEqual(load1.map { $0.name }.sorted(), load2.map { $0.name }.sorted())
        XCTAssertEqual(load2.map { $0.name }.sorted(), load3.map { $0.name }.sorted())
    }

    // MARK: - Data Validation Tests

    func testPresetsHaveValidIntervalData() {
        // When
        let presets = service.loadPresets()

        // Then
        for preset in presets {
            // Each preset should have at least one interval (months or miles)
            let hasInterval = preset.defaultIntervalMonths != nil || preset.defaultIntervalMiles != nil
            XCTAssertTrue(hasInterval, "Preset '\(preset.name)' should have at least one interval")

            // If months are set, they should be positive
            if let months = preset.defaultIntervalMonths {
                XCTAssertGreaterThan(months, 0, "Preset '\(preset.name)' months should be positive")
            }

            // If miles are set, they should be positive
            if let miles = preset.defaultIntervalMiles {
                XCTAssertGreaterThan(miles, 0, "Preset '\(preset.name)' miles should be positive")
            }
        }
    }

    func testPresetsHaveValidCategories() {
        // When
        let presets = service.loadPresets()
        let validCategories = Set(ServiceCategory.allCases.map { $0.rawValue.lowercased() })

        // Then
        for preset in presets {
            XCTAssertTrue(
                validCategories.contains(preset.category.lowercased()),
                "Preset '\(preset.name)' has invalid category '\(preset.category)'"
            )
        }
    }
}
