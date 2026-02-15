//
//  ServiceCompletionFlowTests.swift
//  checkpointTests
//
//  Integration tests: create vehicle → add service → log completion → verify due date recalculation
//  Mirrors the logic in MarkServiceDoneSheet.markAsDone()
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceCompletionFlowTests: XCTestCase {

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

    // MARK: - Service Completion Tests

    @MainActor
    func testServiceCompletion_updatesDueDate() {
        // Given: Vehicle and service with 6-month interval
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),  // overdue
            intervalMonths: 6
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        let performedDate = Date.now

        // When: Simulate service completion (mirrors MarkServiceDoneSheet logic)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: 50000
        )
        modelContext.insert(log)

        service.lastPerformed = performedDate
        service.lastMileage = 50000

        if let months = service.intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        }

        // Then: Due date should be 6 months from now
        XCTAssertNotNil(service.dueDate)
        let expectedDueDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: service.dueDate!, to: expectedDueDate).day ?? 99
        XCTAssertEqual(daysDifference, 0, "Due date should be exactly 6 months from performed date")
    }

    @MainActor
    func testServiceCompletion_updatesLastPerformed() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Tire Rotation",
            lastPerformed: Calendar.current.date(byAdding: .month, value: -6, to: .now),
            intervalMonths: 6
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        let performedDate = Date.now

        // When: Simulate service completion
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: 50000
        )
        modelContext.insert(log)

        service.lastPerformed = performedDate
        service.lastMileage = 50000

        // Then
        XCTAssertNotNil(service.lastPerformed)
        let secondsDifference = abs(service.lastPerformed!.timeIntervalSince(performedDate))
        XCTAssertLessThan(secondsDifference, 1.0, "lastPerformed should match the log's performed date")
        XCTAssertEqual(service.lastMileage, 50000)
    }

    @MainActor
    func testServiceCompletion_clearsDueDateWhenNoInterval() {
        // Given: Vehicle and service with a due date but NO recurring interval
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Brake Inspection",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),  // overdue
            dueMileage: 49000  // also overdue by mileage
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        let performedDate = Date.now
        let mileageAtService = 50000

        // When: Simulate service completion (mirrors MarkServiceDoneSheet logic)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageAtService
        )
        modelContext.insert(log)

        service.lastPerformed = performedDate
        service.lastMileage = mileageAtService

        if let months = service.intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        } else {
            service.dueDate = nil
        }
        if let miles = service.intervalMiles, miles > 0 {
            service.dueMileage = mileageAtService + miles
        } else {
            service.dueMileage = nil
        }

        // Then: Due date and mileage should be cleared (no recurring schedule)
        XCTAssertNil(service.dueDate, "Due date should be cleared for non-recurring service")
        XCTAssertNil(service.dueMileage, "Due mileage should be cleared for non-recurring service")
        // Service should become neutral status
        XCTAssertEqual(service.status(currentMileage: 50000), .neutral)
    }

    @MainActor
    func testServiceCompletion_keepsDueDateWhenHasInterval() {
        // Given: Vehicle and service with a due date AND recurring intervals
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: 49000,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        let performedDate = Date.now
        let mileageAtService = 50000

        // When: Simulate service completion
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageAtService
        )
        modelContext.insert(log)

        service.lastPerformed = performedDate
        service.lastMileage = mileageAtService

        if let months = service.intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        } else {
            service.dueDate = nil
        }
        if let miles = service.intervalMiles, miles > 0 {
            service.dueMileage = mileageAtService + miles
        } else {
            service.dueMileage = nil
        }

        // Then: Due date and mileage should be recalculated
        XCTAssertNotNil(service.dueDate, "Due date should be set for recurring service")
        let expectedDueDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: service.dueDate!, to: expectedDueDate).day ?? 99
        XCTAssertEqual(daysDifference, 0, "Due date should be 6 months from performed date")
        XCTAssertEqual(service.dueMileage, 55000, "Due mileage should be 50000 + 5000")
    }

    @MainActor
    func testServiceCompletion_updatesDueMileage() {
        // Given: Vehicle and service with 5000-mile interval
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueMileage: 49000,  // already overdue by mileage
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        let mileageAtService = 50200

        // When: Simulate service completion
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: mileageAtService
        )
        modelContext.insert(log)

        service.lastPerformed = Date.now
        service.lastMileage = mileageAtService

        if let miles = service.intervalMiles, miles > 0 {
            service.dueMileage = mileageAtService + miles
        }

        // Update vehicle mileage if service mileage is higher
        if mileageAtService > vehicle.currentMileage {
            vehicle.currentMileage = mileageAtService
            vehicle.mileageUpdatedAt = Date.now
        }

        // Then: Due mileage should be service mileage + interval
        XCTAssertEqual(service.dueMileage, 55200, "Due mileage should be 50200 + 5000 = 55200")
        XCTAssertEqual(service.lastMileage, 50200)
        XCTAssertEqual(vehicle.currentMileage, 50200, "Vehicle mileage should update when service mileage is higher")
    }
}
