//
//  ServicesTabTests.swift
//  checkpointTests
//
//  Tests for ServicesTab view content and functionality
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class ServicesTabTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Status Filter Tests

    func testStatusFilter_AllCases() {
        // Given
        let allFilters = ServicesTab.StatusFilter.allCases

        // Then
        XCTAssertEqual(allFilters.count, 4)
        XCTAssertTrue(allFilters.contains(.all))
        XCTAssertTrue(allFilters.contains(.overdue))
        XCTAssertTrue(allFilters.contains(.dueSoon))
        XCTAssertTrue(allFilters.contains(.good))
    }

    func testStatusFilter_RawValues() {
        // Then
        XCTAssertEqual(ServicesTab.StatusFilter.all.rawValue, "All")
        XCTAssertEqual(ServicesTab.StatusFilter.overdue.rawValue, "Overdue")
        XCTAssertEqual(ServicesTab.StatusFilter.dueSoon.rawValue, "Due Soon")
        XCTAssertEqual(ServicesTab.StatusFilter.good.rawValue, "Good")
    }

    // MARK: - Search Filter Tests

    @MainActor
    func testSearchFilter_FiltersServicesByName() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let oilChange = Service(name: "Oil Change", dueMileage: 35000)
        oilChange.vehicle = vehicle

        let tireRotation = Service(name: "Tire Rotation", dueMileage: 36000)
        tireRotation.vehicle = vehicle

        let brakeInspection = Service(name: "Brake Inspection", dueMileage: 37000)
        brakeInspection.vehicle = vehicle

        modelContext.insert(oilChange)
        modelContext.insert(tireRotation)
        modelContext.insert(brakeInspection)

        let searchText = "oil"
        let services = [oilChange, tireRotation, brakeInspection]

        // When
        let filtered = services.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Oil Change")
    }

    @MainActor
    func testSearchFilter_CaseInsensitive() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let service = Service(name: "OIL CHANGE", dueMileage: 35000)
        service.vehicle = vehicle
        modelContext.insert(service)

        let searchText = "oil change"
        let services = [service]

        // When
        let filtered = services.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        // Then
        XCTAssertEqual(filtered.count, 1)
    }

    @MainActor
    func testSearchFilter_EmptySearch_ReturnsAll() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let service1 = Service(name: "Oil Change", dueMileage: 35000)
        service1.vehicle = vehicle
        let service2 = Service(name: "Tire Rotation", dueMileage: 36000)
        service2.vehicle = vehicle

        modelContext.insert(service1)
        modelContext.insert(service2)

        let searchText = ""
        let services = [service1, service2]

        // When
        let filtered = searchText.isEmpty ? services : services.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        // Then
        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - Status Filter Application Tests

    @MainActor
    func testStatusFilter_Overdue() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let overdueService = Service(name: "Overdue", dueMileage: 29000)
        overdueService.vehicle = vehicle

        let goodService = Service(name: "Good", dueMileage: 40000)
        goodService.vehicle = vehicle

        modelContext.insert(overdueService)
        modelContext.insert(goodService)

        let services = [overdueService, goodService]

        // When
        let filtered = services.filter { $0.status(currentMileage: vehicle.currentMileage) == .overdue }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Overdue")
    }

    @MainActor
    func testStatusFilter_DueSoon() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let dueSoonService = Service(name: "Due Soon", dueMileage: 30200) // Within 500 miles
        dueSoonService.vehicle = vehicle

        let goodService = Service(name: "Good", dueMileage: 40000)
        goodService.vehicle = vehicle

        modelContext.insert(dueSoonService)
        modelContext.insert(goodService)

        let services = [dueSoonService, goodService]

        // When
        let filtered = services.filter { $0.status(currentMileage: vehicle.currentMileage) == .dueSoon }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Due Soon")
    }

    @MainActor
    func testStatusFilter_Good() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let goodService = Service(name: "Good", dueMileage: 40000) // Well ahead
        goodService.vehicle = vehicle

        let overdueService = Service(name: "Overdue", dueMileage: 29000)
        overdueService.vehicle = vehicle

        modelContext.insert(goodService)
        modelContext.insert(overdueService)

        let services = [goodService, overdueService]

        // When
        let filtered = services.filter { $0.status(currentMileage: vehicle.currentMileage) == .good }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Good")
    }

    // MARK: - Service History Tests

    @MainActor
    func testServiceHistory_FilteredByVehicle() {
        // Given
        let vehicle1 = Vehicle(
            name: "Car 1",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        let vehicle2 = Vehicle(
            name: "Car 2",
            make: "Honda",
            model: "Civic",
            year: 2023,
            currentMileage: 20000
        )
        modelContext.insert(vehicle1)
        modelContext.insert(vehicle2)

        let log1 = ServiceLog(
            vehicle: vehicle1,
            performedDate: .now,
            mileageAtService: 30000
        )
        let log2 = ServiceLog(
            vehicle: vehicle2,
            performedDate: .now,
            mileageAtService: 20000
        )

        modelContext.insert(log1)
        modelContext.insert(log2)

        let allLogs = [log1, log2]

        // When - filter for vehicle1
        let vehicle1Logs = allLogs.filter { $0.vehicle?.id == vehicle1.id }

        // Then
        XCTAssertEqual(vehicle1Logs.count, 1)
        XCTAssertEqual(vehicle1Logs.first?.mileageAtService, 30000)
    }
}
