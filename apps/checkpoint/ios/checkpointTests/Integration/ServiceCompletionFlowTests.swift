//
//  ServiceCompletionFlowTests.swift
//  checkpointTests
//
//  Integration tests for completing a scheduled service.
//  - Service.recalculateDueDates() tests cover the in-place primitive (still
//    used as a low-level helper by other tests).
//  - ServiceCompletionService.completeService() tests cover the chain-spawn
//    flow that production completion paths now go through.
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

    // MARK: - recalculateDueDates Tests

    @MainActor
    func testRecalculateDueDates_advancesDueDateWithInterval() {
        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            intervalMonths: 6
        )
        modelContext.insert(service)

        let performedDate = Date.now

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: 50000)

        // Then
        XCTAssertNotNil(service.dueDate)
        let expectedDueDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: service.dueDate!, to: expectedDueDate).day ?? 99
        XCTAssertEqual(daysDifference, 0, "Due date should be exactly 6 months from performed date")
        XCTAssertEqual(service.lastPerformed, performedDate)
        XCTAssertEqual(service.lastMileage, 50000)
    }

    @MainActor
    func testRecalculateDueDates_advancesDueMileageWithInterval() {
        let service = Service(
            name: "Oil Change",
            dueMileage: 49000,
            intervalMiles: 5000
        )
        modelContext.insert(service)

        // When
        service.recalculateDueDates(performedDate: Date.now, mileage: 50200)

        // Then
        XCTAssertEqual(service.dueMileage, 55200, "Due mileage should be 50200 + 5000 = 55200")
        XCTAssertEqual(service.lastMileage, 50200)
    }

    @MainActor
    func testRecalculateDueDates_advancesBothWithIntervals() {
        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: 49000,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        modelContext.insert(service)

        let performedDate = Date.now

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: 50000)

        // Then
        XCTAssertNotNil(service.dueDate, "Due date should be set for recurring service")
        let expectedDueDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: service.dueDate!, to: expectedDueDate).day ?? 99
        XCTAssertEqual(daysDifference, 0)
        XCTAssertEqual(service.dueMileage, 55000, "Due mileage should be 50000 + 5000")
    }

    @MainActor
    func testRecalculateDueDates_clearsDueDatesWithoutInterval() {
        let service = Service(
            name: "Brake Inspection",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: 49000
        )
        modelContext.insert(service)

        // When
        service.recalculateDueDates(performedDate: Date.now, mileage: 50000)

        // Then
        XCTAssertNil(service.dueDate, "Due date should be cleared for non-recurring service")
        XCTAssertNil(service.dueMileage, "Due mileage should be cleared for non-recurring service")
        XCTAssertEqual(service.status(currentMileage: 50000), .neutral)
    }

    @MainActor
    func testRecalculateDueDates_treatsZeroIntervalAsNone() {
        let service = Service(
            name: "Windshield Repair",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            dueMileage: 49000,
            intervalMonths: 0,
            intervalMiles: 0
        )
        modelContext.insert(service)

        // When
        service.recalculateDueDates(performedDate: Date.now, mileage: 50000)

        // Then: 0-value intervals should be treated the same as nil
        XCTAssertNil(service.dueDate)
        XCTAssertNil(service.dueMileage)
    }

    @MainActor
    func testRecalculateDueDates_setsLastPerformedAndMileage() {
        let service = Service(
            name: "Tire Rotation",
            lastPerformed: Calendar.current.date(byAdding: .month, value: -6, to: .now),
            intervalMonths: 6
        )
        modelContext.insert(service)

        let performedDate = Date.now

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: 50000)

        // Then
        let secondsDifference = abs(service.lastPerformed!.timeIntervalSince(performedDate))
        XCTAssertLessThan(secondsDifference, 1.0, "lastPerformed should match the performed date")
        XCTAssertEqual(service.lastMileage, 50000)
    }

    // MARK: - ServiceCompletionService (chain-spawn) Tests

    @MainActor
    func testCompleteService_recurring_spawnsNextOccurrence() {
        let vehicle = Vehicle(name: "Test", make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        modelContext.insert(vehicle)

        let original = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .month, value: -1, to: .now),
            dueMileage: 49000,
            intervalMonths: 6,
            intervalMiles: 5000,
            isRecurring: true
        )
        original.vehicle = vehicle
        modelContext.insert(original)

        let performedDate = Date.now
        let next = ServiceCompletionService.completeService(
            original,
            performedDate: performedDate,
            mileage: 50000,
            in: modelContext
        )

        XCTAssertNotNil(next, "Recurring service should spawn a successor")
        XCTAssertEqual(next?.name, "Oil Change")
        XCTAssertEqual(next?.intervalMonths, 6)
        XCTAssertEqual(next?.intervalMiles, 5000)
        XCTAssertTrue(next?.isRecurring == true)
        XCTAssertEqual(next?.vehicle?.id, vehicle.id)
        XCTAssertEqual(next?.dueMileage, 55000, "Next due mileage = completion mileage + interval")
        let expectedDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)!
        let dayDelta = Calendar.current.dateComponents([.day], from: next!.dueDate!, to: expectedDate).day ?? 99
        XCTAssertEqual(dayDelta, 0, "Next due date should be 6 months from completion")

        // Closed (original) service is reduced to a historical record.
        XCTAssertNil(original.dueDate, "Closed service should have no future due date")
        XCTAssertNil(original.dueMileage)
        XCTAssertNil(original.intervalMonths, "Intervals carry forward to spawn, not the corpse")
        XCTAssertNil(original.intervalMiles)
        XCTAssertEqual(original.lastMileage, 50000)
        XCTAssertNotNil(original.lastPerformed)
    }

    @MainActor
    func testCompleteService_nonRecurring_doesNotSpawn() {
        let vehicle = Vehicle(name: "Test", make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        modelContext.insert(vehicle)

        let oneShot = Service(
            name: "Brake Inspection",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now),
            isRecurring: false
        )
        oneShot.vehicle = vehicle
        modelContext.insert(oneShot)

        let next = ServiceCompletionService.completeService(
            oneShot,
            performedDate: Date.now,
            mileage: 50000,
            in: modelContext
        )

        XCTAssertNil(next, "Non-recurring service should not spawn a successor")
        XCTAssertNil(oneShot.dueDate)
        XCTAssertNotNil(oneShot.lastPerformed)
    }

    @MainActor
    func testCompleteService_recurringWithoutPolicy_doesNotSpawn() {
        let vehicle = Vehicle(name: "Test", make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        modelContext.insert(vehicle)

        // isRecurring=true but no intervals — defensive guard
        let stranded = Service(name: "Mystery Service", isRecurring: true)
        stranded.vehicle = vehicle
        modelContext.insert(stranded)

        let next = ServiceCompletionService.completeService(
            stranded,
            performedDate: Date.now,
            mileage: 50000,
            in: modelContext
        )

        XCTAssertNil(next, "Recurring service with no interval policy should not spawn an empty successor")
    }
}
