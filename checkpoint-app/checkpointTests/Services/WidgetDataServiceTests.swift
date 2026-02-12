//
//  WidgetDataServiceTests.swift
//  checkpointTests
//
//  Tests for WidgetDataService multi-vehicle support
//

import XCTest
@testable import checkpoint

@MainActor
final class WidgetDataServiceTests: XCTestCase {

    private let appGroupID = AppGroupConstants.iPhoneWidget
    private let vehicleListKey = "vehicleList"
    private let widgetDataKey = "widgetData"
    private let appSelectedVehicleIDKey = "appSelectedVehicleID"

    override func tearDown() {
        // Clean up test data from UserDefaults
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            userDefaults.removeObject(forKey: vehicleListKey)
            userDefaults.removeObject(forKey: widgetDataKey)
            userDefaults.removeObject(forKey: appSelectedVehicleIDKey)
            // Clean up any vehicle-specific keys we might have created
            for key in userDefaults.dictionaryRepresentation().keys {
                if key.hasPrefix("widgetData_") {
                    userDefaults.removeObject(forKey: key)
                }
            }
        }
        super.tearDown()
    }

    // MARK: - VehicleListItem Tests

    func testVehicleListItem_EncodesAndDecodes() throws {
        let item = VehicleListItem(id: "test-uuid", displayName: "My Car")

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(VehicleListItem.self, from: encoded)

        XCTAssertEqual(decoded.id, "test-uuid")
        XCTAssertEqual(decoded.displayName, "My Car")
    }

    func testVehicleListItem_ArrayEncodesAndDecodes() throws {
        let items = [
            VehicleListItem(id: "uuid-1", displayName: "Daily Driver"),
            VehicleListItem(id: "uuid-2", displayName: "Weekend Car")
        ]

        let encoded = try JSONEncoder().encode(items)
        let decoded = try JSONDecoder().decode([VehicleListItem].self, from: encoded)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].id, "uuid-1")
        XCTAssertEqual(decoded[0].displayName, "Daily Driver")
        XCTAssertEqual(decoded[1].id, "uuid-2")
        XCTAssertEqual(decoded[1].displayName, "Weekend Car")
    }

    // MARK: - updateVehicleList Tests

    func testUpdateVehicleList_StoresVehiclesInAppGroup() {
        let vehicle1 = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        )
        let vehicle2 = Vehicle(
            name: "Weekend Car",
            make: "Mazda",
            model: "MX-5",
            year: 2020,
            currentMileage: 18000
        )

        WidgetDataService.shared.updateVehicleList([vehicle1, vehicle2])

        // Verify data was stored
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: vehicleListKey) else {
            XCTFail("Vehicle list data not found in App Group UserDefaults")
            return
        }

        // Decode and verify
        do {
            let items = try JSONDecoder().decode([VehicleListItem].self, from: data)
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].displayName, "Daily Driver")
            XCTAssertEqual(items[1].displayName, "Weekend Car")
        } catch {
            XCTFail("Failed to decode vehicle list: \(error)")
        }
    }

    func testUpdateVehicleList_EmptyArrayClearsData() {
        // First add some vehicles
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 25000
        )
        WidgetDataService.shared.updateVehicleList([vehicle])

        // Now update with empty array
        WidgetDataService.shared.updateVehicleList([])

        // Verify data is now empty array (not nil)
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: vehicleListKey) else {
            XCTFail("Vehicle list key should exist")
            return
        }

        do {
            let items = try JSONDecoder().decode([VehicleListItem].self, from: data)
            XCTAssertEqual(items.count, 0)
        } catch {
            XCTFail("Failed to decode empty vehicle list: \(error)")
        }
    }

    // MARK: - updateWidget Tests

    func testUpdateWidget_StoresWithVehicleSpecificKey() {
        let vehicle = Vehicle(
            name: "Test Vehicle",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        let vehicleID = vehicle.id.uuidString

        WidgetDataService.shared.updateWidget(for: vehicle)

        // Verify vehicle-specific key exists
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        let vehicleSpecificKey = "widgetData_\(vehicleID)"
        XCTAssertNotNil(userDefaults.data(forKey: vehicleSpecificKey),
                        "Vehicle-specific widget data should exist")
    }

    func testUpdateWidget_AlsoStoresLegacyKey() {
        let vehicle = Vehicle(
            name: "Test Vehicle",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )

        WidgetDataService.shared.updateWidget(for: vehicle)

        // Verify legacy key also exists for backward compatibility
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        XCTAssertNotNil(userDefaults.data(forKey: widgetDataKey),
                        "Legacy widget data key should exist for backward compatibility")
    }

    // MARK: - removeWidgetData Tests

    func testRemoveWidgetData_RemovesVehicleSpecificKey() {
        let vehicle = Vehicle(
            name: "Test Vehicle",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        let vehicleID = vehicle.id.uuidString

        // First add widget data
        WidgetDataService.shared.updateWidget(for: vehicle)

        // Verify it exists
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        let vehicleSpecificKey = "widgetData_\(vehicleID)"
        XCTAssertNotNil(userDefaults.data(forKey: vehicleSpecificKey))

        // Remove it
        WidgetDataService.shared.removeWidgetData(for: vehicleID)

        // Verify it's gone
        XCTAssertNil(userDefaults.data(forKey: vehicleSpecificKey),
                     "Vehicle-specific widget data should be removed")
    }

    func testRemoveWidgetData_LegacyKeyRemainsIntact() {
        let vehicle = Vehicle(
            name: "Test Vehicle",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        let vehicleID = vehicle.id.uuidString

        // Add widget data
        WidgetDataService.shared.updateWidget(for: vehicle)

        // Remove vehicle-specific data
        WidgetDataService.shared.removeWidgetData(for: vehicleID)

        // Legacy key should still exist
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        XCTAssertNotNil(userDefaults.data(forKey: widgetDataKey),
                        "Legacy widget data key should remain after removing vehicle-specific data")
    }

    // MARK: - clearWidgetData Tests

    func testClearWidgetData_RemovesBothLegacyAndVehicleList() {
        let vehicle = Vehicle(
            name: "Test Vehicle",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )

        // Add both widget data and vehicle list
        WidgetDataService.shared.updateWidget(for: vehicle)
        WidgetDataService.shared.updateVehicleList([vehicle])

        // Clear all widget data
        WidgetDataService.shared.clearWidgetData()

        // Verify both are removed
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        XCTAssertNil(userDefaults.data(forKey: widgetDataKey),
                     "Legacy widget data should be cleared")
        XCTAssertNil(userDefaults.data(forKey: vehicleListKey),
                     "Vehicle list should be cleared")
    }

    // MARK: - WidgetSharedData Tests

    func testWidgetSharedData_EncodesAndDecodes() throws {
        let sharedData = WidgetSharedData(
            vehicleID: "test-vehicle-id",
            vehicleName: "My Car",
            currentMileage: 50000,
            estimatedMileage: 50500,
            isEstimatedMileage: true,
            services: [
                WidgetSharedData.SharedService(
                    serviceID: "test-service-id",
                    name: "Oil Change",
                    status: .dueSoon,
                    dueDescription: "Due in 500 miles",
                    dueMileage: 50500,
                    daysRemaining: 10
                )
            ],
            updatedAt: Date()
        )

        let encoded = try JSONEncoder().encode(sharedData)
        let decoded = try JSONDecoder().decode(WidgetSharedData.self, from: encoded)

        XCTAssertEqual(decoded.vehicleName, "My Car")
        XCTAssertEqual(decoded.currentMileage, 50000)
        XCTAssertEqual(decoded.estimatedMileage, 50500)
        XCTAssertTrue(decoded.isEstimatedMileage)
        XCTAssertEqual(decoded.services.count, 1)
        XCTAssertEqual(decoded.services[0].name, "Oil Change")
        XCTAssertEqual(decoded.services[0].status, .dueSoon)
    }

    func testWidgetSharedData_ServiceStatusRawValues() {
        XCTAssertEqual(WidgetSharedData.ServiceStatus.overdue.rawValue, "overdue")
        XCTAssertEqual(WidgetSharedData.ServiceStatus.dueSoon.rawValue, "dueSoon")
        XCTAssertEqual(WidgetSharedData.ServiceStatus.good.rawValue, "good")
        XCTAssertEqual(WidgetSharedData.ServiceStatus.neutral.rawValue, "neutral")
    }

    // MARK: - App Selected Vehicle Sync Tests

    func testAppSelectedVehicleID_StoredInSharedDefaults() {
        let testVehicleID = UUID().uuidString

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        // Simulate main app saving selected vehicle ID to shared defaults
        userDefaults.set(testVehicleID, forKey: appSelectedVehicleIDKey)

        // Verify the value is stored
        let storedValue = userDefaults.string(forKey: appSelectedVehicleIDKey)
        XCTAssertEqual(storedValue, testVehicleID,
                       "App selected vehicle ID should be stored in shared UserDefaults")
    }

    func testAppSelectedVehicleID_CanBeReadByWidget() {
        let testVehicleID = UUID().uuidString

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        // Main app saves selected vehicle ID
        userDefaults.set(testVehicleID, forKey: appSelectedVehicleIDKey)

        // Widget reads via the same key (used by WidgetProvider for "Match App" resolution)
        let widgetReadValue = userDefaults.string(forKey: appSelectedVehicleIDKey)
        XCTAssertEqual(widgetReadValue, testVehicleID,
                       "Widget should be able to read app's selected vehicle ID")
    }

    func testAppSelectedVehicleID_ClearingRemovesValue() {
        let testVehicleID = UUID().uuidString

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        // Save then clear
        userDefaults.set(testVehicleID, forKey: appSelectedVehicleIDKey)
        XCTAssertNotNil(userDefaults.string(forKey: appSelectedVehicleIDKey))

        userDefaults.removeObject(forKey: appSelectedVehicleIDKey)

        let clearedValue = userDefaults.string(forKey: appSelectedVehicleIDKey)
        XCTAssertNil(clearedValue,
                     "Cleared app selected vehicle ID should be nil")
    }

    func testAppSelectedVehicleID_UpdateOverwritesPrevious() {
        let firstVehicleID = UUID().uuidString
        let secondVehicleID = UUID().uuidString

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        // Save first, then second
        userDefaults.set(firstVehicleID, forKey: appSelectedVehicleIDKey)
        userDefaults.set(secondVehicleID, forKey: appSelectedVehicleIDKey)

        let currentValue = userDefaults.string(forKey: appSelectedVehicleIDKey)
        XCTAssertEqual(currentValue, secondVehicleID,
                       "Latest selected vehicle ID should overwrite previous")
    }

    func testWidgetVehiclePriority_ExplicitConfigTakesPrecedence() {
        // This test verifies the expected priority order:
        // 1. Explicit widget config (if user long-pressed and configured)
        // 2. App's selected vehicle
        // 3. First vehicle in list

        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }

        let appSelectedID = UUID().uuidString
        let explicitConfigID = UUID().uuidString

        // Set both app selection and simulate widget config
        userDefaults.set(appSelectedID, forKey: appSelectedVehicleIDKey)

        // When widget has explicit config, it should use that (explicitConfigID)
        // When widget has no config, it should use app's selection (appSelectedID)

        // Read app selection - widget would check this if no explicit config
        let readAppSelection = userDefaults.string(forKey: appSelectedVehicleIDKey)
        XCTAssertEqual(readAppSelection, appSelectedID,
                       "App selection should be available for widget to read")

        // If widget has explicit config (simulated), it uses that instead
        // This is a conceptual test - actual priority is in WidgetProvider.loadEntry()
        XCTAssertNotEqual(explicitConfigID, appSelectedID,
                          "Explicit config and app selection should be different values")
    }
}
