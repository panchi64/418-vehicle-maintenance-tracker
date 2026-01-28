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

    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let vehicleListKey = "vehicleList"
    private let widgetDataKey = "widgetData"

    override func tearDown() {
        // Clean up test data from UserDefaults
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            userDefaults.removeObject(forKey: vehicleListKey)
            userDefaults.removeObject(forKey: widgetDataKey)
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
            vehicleName: "My Car",
            currentMileage: 50000,
            estimatedMileage: 50500,
            isEstimatedMileage: true,
            services: [
                WidgetSharedData.SharedService(
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
}
