//
//  ServiceCompletionFlowTests.swift
//  checkpointTests
//
//  Integration tests: create vehicle → add service → log completion → verify due date recalculation
//  Tests use Service.recalculateDueDates() — the same method used by all completion flows.
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
}
