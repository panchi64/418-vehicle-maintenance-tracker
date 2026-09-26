//
//  SiriDataProviderTests.swift
//  checkpointTests
//
//  Tests for SiriDataProvider reading from App Groups
//

import XCTest
@testable import checkpoint

final class SiriDataProviderTests: XCTestCase {
    private let appGroupID = AppGroupConstants.iPhoneWidget
    private let widgetDataKey = "widgetData"
    private let vehicleListKey = "vehicleList"

    override func setUp() {
        super.setUp()
        // Clean up any existing data before each test
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            userDefaults.removeObject(forKey: widgetDataKey)
            userDefaults.removeObject(forKey: vehicleListKey)
            userDefaults.synchronize()
        }
    }

    override func tearDown() {
        // Clean up test data
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            userDefaults.removeObject(forKey: widgetDataKey)
            userDefaults.removeObject(forKey: vehicleListKey)
            userDefaults.synchronize()
        }
        super.tearDown()
    }

    // MARK: - loadServiceData Tests

    func test_loadServiceData_withValidData_returnsServices() {
        // Given
        let testData = createTestWidgetData(
            vehicleName: "Test Car",
            services: [
                ("Oil Change", "dueSoon", "Due in 5 days", 5),
                ("Tire Rotation", "good", "Due in 30 days", 30)
            ]
        )
        saveWidgetData(testData)

        // When
        let result = SiriDataProvider.loadServiceData()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.vehicleName, "Test Car")
        XCTAssertEqual(result?.services.count, 2)
        XCTAssertEqual(result?.services.first?.name, "Oil Change")
        XCTAssertEqual(result?.services.first?.status, .dueSoon)
    }

    func test_loadServiceData_withNoData_returnsNil() {
        // Given - no data in UserDefaults

        // When
        let result = SiriDataProvider.loadServiceData()

        // Then
        XCTAssertNil(result)
    }

    func test_loadServiceData_withOverdueService_returnsOverdueStatus() {
        // Given
        let testData = createTestWidgetData(
            vehicleName: "Test Car",
            services: [
                ("Brake Pads", "overdue", "3 days overdue", -3)
            ]
        )
        saveWidgetData(testData)

        // When
        let result = SiriDataProvider.loadServiceData()

        // Then
        XCTAssertEqual(result?.services.first?.status, .overdue)
        XCTAssertEqual(result?.services.first?.daysRemaining, -3)
    }

    // MARK: - loadVehicleList Tests

    func test_loadVehicleList_withValidData_returnsVehicles() {
        // Given
        let vehicles = [
            VehicleListItem(id: "uuid-1", displayName: "Daily Driver"),
            VehicleListItem(id: "uuid-2", displayName: "Weekend Car")
        ]
        saveVehicleList(vehicles)

        // When
        let result = SiriDataProvider.loadVehicleList()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.displayName, "Daily Driver")
    }

    func test_loadVehicleList_withNoData_returnsEmptyArray() {
        // Given - no data

        // When
        let result = SiriDataProvider.loadVehicleList()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Helpers

    private func createTestWidgetData(
        vehicleName: String,
        services: [(name: String, status: String, description: String, daysRemaining: Int)]
    ) -> Data {
        let serviceArray = services.map { service in
            """
            {
                "name": "\(service.name)",
                "status": "\(service.status)",
                "dueDescription": "\(service.description)",
                "dueMileage": null,
                "daysRemaining": \(service.daysRemaining)
            }
            """
        }.joined(separator: ",")

        let json = """
        {
            "vehicleName": "\(vehicleName)",
            "currentMileage": 50000,
            "services": [\(serviceArray)],
            "updatedAt": 0
        }
        """
        return json.data(using: .utf8)!
    }

    private func saveWidgetData(_ data: Data) {
        UserDefaults(suiteName: appGroupID)?.set(data, forKey: widgetDataKey)
    }

    private func saveVehicleList(_ vehicles: [VehicleListItem]) {
        let data = try? JSONEncoder().encode(vehicles)
        UserDefaults(suiteName: appGroupID)?.set(data, forKey: vehicleListKey)
    }
}
