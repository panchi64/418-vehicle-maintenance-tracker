//
//  ServiceFilteringTests.swift
//  checkpointTests
//
//  Tests for [Service].forVehicle() extension — filtering and urgency sorting
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceFilteringTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Filtering Tests

    @MainActor
    func testForVehicle_filtersCorrectly() {
        // Given: Two vehicles with different services
        let vehicle1 = Vehicle(name: "Car A", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let vehicle2 = Vehicle(name: "Car B", make: "Honda", model: "Civic", year: 2021, currentMileage: 20000)

        let service1 = Service(name: "Oil Change", dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now))
        service1.vehicle = vehicle1

        let service2 = Service(name: "Tire Rotation", dueDate: Calendar.current.date(byAdding: .day, value: 15, to: .now))
        service2.vehicle = vehicle1

        let service3 = Service(name: "Brake Inspection", dueDate: Calendar.current.date(byAdding: .day, value: 10, to: .now))
        service3.vehicle = vehicle2

        let allServices = [service1, service2, service3]

        // When
        let filtered = allServices.forVehicle(vehicle1)

        // Then
        XCTAssertEqual(filtered.count, 2, "Should return only services for vehicle1")
        XCTAssertTrue(filtered.allSatisfy { $0.vehicle?.id == vehicle1.id })
    }

    @MainActor
    func testForVehicle_sortsByUrgency() {
        // Given: Vehicle with services of varying urgency
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let calendar = Calendar.current

        let farAway = Service(
            name: "Far Away",
            dueDate: calendar.date(byAdding: .day, value: 90, to: .now)
        )
        farAway.vehicle = vehicle

        let urgent = Service(
            name: "Urgent",
            dueDate: calendar.date(byAdding: .day, value: 5, to: .now)
        )
        urgent.vehicle = vehicle

        let medium = Service(
            name: "Medium",
            dueDate: calendar.date(byAdding: .day, value: 30, to: .now)
        )
        medium.vehicle = vehicle

        let allServices = [farAway, urgent, medium]

        // When
        let sorted = allServices.forVehicle(vehicle)

        // Then: Most urgent (fewest days) should be first
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].name, "Urgent", "Most urgent service should be first")
        XCTAssertEqual(sorted[1].name, "Medium")
        XCTAssertEqual(sorted[2].name, "Far Away", "Least urgent service should be last")
    }

    @MainActor
    func testForVehicle_emptyArray() {
        // Given
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022)
        let allServices: [Service] = []

        // When
        let filtered = allServices.forVehicle(vehicle)

        // Then
        XCTAssertTrue(filtered.isEmpty, "Empty input should return empty output")
    }

    @MainActor
    func testForVehicle_noMatchingServices() {
        // Given: Services belonging to a different vehicle
        let vehicle1 = Vehicle(name: "Car A", make: "Toyota", model: "Camry", year: 2022)
        let vehicle2 = Vehicle(name: "Car B", make: "Honda", model: "Civic", year: 2021)

        let service = Service(name: "Oil Change", dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now))
        service.vehicle = vehicle2

        let allServices = [service]

        // When
        let filtered = allServices.forVehicle(vehicle1)

        // Then
        XCTAssertTrue(filtered.isEmpty, "Should return empty when no services belong to the vehicle")
    }
}
