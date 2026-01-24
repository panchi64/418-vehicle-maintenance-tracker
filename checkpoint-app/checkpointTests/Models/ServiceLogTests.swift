//
//  ServiceLogTests.swift
//  checkpointTests
//
//  Unit tests for ServiceLog model
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceLogTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitializationWithAllParameters() throws {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Oil Change")
        let performedDate = Date.now
        let mileageAtService = 30000
        let cost = Decimal(45.99)
        let notes = "Oil change completed"
        let createdAt = Date.now

        // When
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageAtService,
            cost: cost,
            notes: notes,
            createdAt: createdAt
        )

        // Then
        XCTAssertNotNil(log.service)
        XCTAssertNotNil(log.vehicle)
        XCTAssertEqual(log.performedDate, performedDate)
        XCTAssertEqual(log.mileageAtService, mileageAtService)
        XCTAssertEqual(log.cost, cost)
        XCTAssertEqual(log.notes, notes)
        XCTAssertEqual(log.createdAt, createdAt)
    }

    func testInitializationWithOptionalParametersAsNil() throws {
        // Given
        let performedDate = Date.now
        let mileageAtService = 30000

        // When
        let log = ServiceLog(
            performedDate: performedDate,
            mileageAtService: mileageAtService
        )

        // Then
        XCTAssertNil(log.service)
        XCTAssertNil(log.vehicle)
        XCTAssertEqual(log.performedDate, performedDate)
        XCTAssertEqual(log.mileageAtService, mileageAtService)
        XCTAssertNil(log.cost)
        XCTAssertNil(log.notes)
        XCTAssertNotNil(log.createdAt)
    }

    func testInitializationWithDefaultCreatedAt() throws {
        // Given
        let performedDate = Date.now
        let mileageAtService = 30000

        // When
        let log = ServiceLog(
            performedDate: performedDate,
            mileageAtService: mileageAtService
        )

        // Then
        // createdAt should be close to now (within 1 second)
        let timeDifference = abs(log.createdAt.timeIntervalSince(Date.now))
        XCTAssertLessThan(timeDifference, 1.0)
    }

    // MARK: - formattedCost Tests

    func testFormattedCostWithValidCost() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: Decimal(45.99)
        )

        // When
        let formattedCost = log.formattedCost

        // Then
        XCTAssertNotNil(formattedCost)
        XCTAssertEqual(formattedCost, "$45.99")
    }

    func testFormattedCostWithNoCost() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: nil
        )

        // When
        let formattedCost = log.formattedCost

        // Then
        XCTAssertNil(formattedCost)
    }

    func testFormattedCostWithZeroCost() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: Decimal(0)
        )

        // When
        let formattedCost = log.formattedCost

        // Then
        XCTAssertNotNil(formattedCost)
        XCTAssertEqual(formattedCost, "$0.00")
    }

    func testFormattedCostWithLargeCost() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: Decimal(1234.56)
        )

        // When
        let formattedCost = log.formattedCost

        // Then
        XCTAssertNotNil(formattedCost)
        XCTAssertEqual(formattedCost, "$1,234.56")
    }

    func testFormattedCostWithCentsOnly() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: Decimal(0.99)
        )

        // When
        let formattedCost = log.formattedCost

        // Then
        XCTAssertNotNil(formattedCost)
        XCTAssertEqual(formattedCost, "$0.99")
    }

    // MARK: - daysSincePerformed Tests

    func testDaysSincePerformedToday() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // When
        let daysSince = log.daysSincePerformed

        // Then
        XCTAssertEqual(daysSince, 0)
    }

    func testDaysSincePerformedYesterday() throws {
        // Given
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date.now)!
        let log = ServiceLog(
            performedDate: yesterday,
            mileageAtService: 30000
        )

        // When
        let daysSince = log.daysSincePerformed

        // Then
        XCTAssertEqual(daysSince, 1)
    }

    func testDaysSincePerformedWeekAgo() throws {
        // Given
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date.now)!
        let log = ServiceLog(
            performedDate: weekAgo,
            mileageAtService: 30000
        )

        // When
        let daysSince = log.daysSincePerformed

        // Then
        XCTAssertEqual(daysSince, 7)
    }

    func testDaysSincePerformedMonthAgo() throws {
        // Given
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date.now)!
        let log = ServiceLog(
            performedDate: monthAgo,
            mileageAtService: 30000
        )

        // When
        let daysSince = log.daysSincePerformed

        // Then
        XCTAssertEqual(daysSince, 30)
    }

    func testDaysSincePerformedFutureDate() throws {
        // Given
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date.now)!
        let log = ServiceLog(
            performedDate: tomorrow,
            mileageAtService: 30000
        )

        // When
        let daysSince = log.daysSincePerformed

        // Then
        // Should return negative value for future dates (approximately -1)
        // We allow for some tolerance due to timing
        XCTAssertLessThanOrEqual(daysSince, 0)
        XCTAssertGreaterThanOrEqual(daysSince, -1)
    }

    // MARK: - Relationship Tests

    func testRelationshipWithService() throws {
        // Given
        let service = Service(name: "Oil Change")
        let log = ServiceLog(
            service: service,
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // When & Then
        XCTAssertNotNil(log.service)
        XCTAssertEqual(log.service?.name, "Oil Change")
    }

    func testRelationshipWithVehicle() throws {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // When & Then
        XCTAssertNotNil(log.vehicle)
        XCTAssertEqual(log.vehicle?.make, "Toyota")
        XCTAssertEqual(log.vehicle?.model, "Camry")
        XCTAssertEqual(log.vehicle?.year, 2022)
    }

    func testRelationshipWithBothServiceAndVehicle() throws {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Oil Change")
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // When & Then
        XCTAssertNotNil(log.service)
        XCTAssertNotNil(log.vehicle)
        XCTAssertEqual(log.service?.name, "Oil Change")
        XCTAssertEqual(log.vehicle?.make, "Toyota")
    }

    func testNoRelationships() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // When & Then
        XCTAssertNil(log.service)
        XCTAssertNil(log.vehicle)
    }

    // MARK: - Edge Case Tests

    func testMileageAtServiceZero() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 0
        )

        // When & Then
        XCTAssertEqual(log.mileageAtService, 0)
    }

    func testMileageAtServiceHighValue() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 250000
        )

        // When & Then
        XCTAssertEqual(log.mileageAtService, 250000)
    }

    func testNotesEmptyString() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            notes: ""
        )

        // When & Then
        XCTAssertNotNil(log.notes)
        XCTAssertEqual(log.notes, "")
    }

    func testNotesLongString() throws {
        // Given
        let longNotes = String(repeating: "This is a very long note. ", count: 50)
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            notes: longNotes
        )

        // When & Then
        XCTAssertNotNil(log.notes)
        XCTAssertEqual(log.notes, longNotes)
    }

    // MARK: - Cost Category Tests

    func testCostCategoryInitialization() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: Decimal(100),
            costCategory: .maintenance
        )

        // Then
        XCTAssertEqual(log.costCategory, .maintenance)
    }

    func testCostCategoryNil() throws {
        // Given
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000
        )

        // Then
        XCTAssertNil(log.costCategory)
    }

    func testCostCategoryAllTypes() throws {
        // Given
        let maintenanceLog = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            costCategory: .maintenance
        )
        let repairLog = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            costCategory: .repair
        )
        let upgradeLog = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            costCategory: .upgrade
        )

        // Then
        XCTAssertEqual(maintenanceLog.costCategory, .maintenance)
        XCTAssertEqual(repairLog.costCategory, .repair)
        XCTAssertEqual(upgradeLog.costCategory, .upgrade)
    }
}
