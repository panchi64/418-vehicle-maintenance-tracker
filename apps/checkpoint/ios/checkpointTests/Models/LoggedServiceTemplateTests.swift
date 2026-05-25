//
//  LoggedServiceTemplateTests.swift
//  checkpointTests
//
//  Tests the structural-field carry-forward used by "Use last entry".
//

import XCTest
@testable import checkpoint

final class LoggedServiceTemplateTests: XCTestCase {

    @MainActor
    func testInit_CopiesServiceNameAndIntervals() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        let service = Service(name: "Oil Change", intervalMonths: 6, intervalMiles: 5000)
        service.vehicle = vehicle
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date(),
            mileageAtService: 30000,
            cost: 45,
            costCategory: .maintenance,
            notes: "Synthetic 0W-20"
        )

        let template = LoggedServiceTemplate(from: log)

        XCTAssertEqual(template.serviceName, "Oil Change")
        XCTAssertEqual(template.cost, 45)
        XCTAssertEqual(template.costCategory, .maintenance)
        XCTAssertEqual(template.notes, "Synthetic 0W-20")
        XCTAssertEqual(template.intervalMonths, 6)
        XCTAssertEqual(template.intervalMiles, 5000)
        XCTAssertTrue(template.hasRecurringIntervals)
    }

    @MainActor
    func testInit_HandlesMissingOptionalFields() {
        let log = ServiceLog(
            service: nil,
            vehicle: nil,
            performedDate: Date(),
            mileageAtService: 0,
            cost: nil,
            costCategory: nil,
            notes: nil
        )

        let template = LoggedServiceTemplate(from: log)

        XCTAssertEqual(template.serviceName, "")
        XCTAssertNil(template.cost)
        XCTAssertNil(template.costCategory)
        XCTAssertNil(template.notes)
        XCTAssertNil(template.intervalMonths)
        XCTAssertNil(template.intervalMiles)
        XCTAssertFalse(template.hasRecurringIntervals)
    }

    @MainActor
    func testHasRecurringIntervals_OnlyMonths() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        let service = Service(name: "Inspection", intervalMonths: 12)
        service.vehicle = vehicle
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 0)
        XCTAssertTrue(LoggedServiceTemplate(from: log).hasRecurringIntervals)
    }

    @MainActor
    func testHasRecurringIntervals_OnlyMiles() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        let service = Service(name: "Tire Rotation", intervalMiles: 7500)
        service.vehicle = vehicle
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 0)
        XCTAssertTrue(LoggedServiceTemplate(from: log).hasRecurringIntervals)
    }

    @MainActor
    func testCostString_TrimsTrailingZeros() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        let log = ServiceLog(
            service: service, vehicle: vehicle,
            performedDate: Date(), mileageAtService: 30000,
            cost: Decimal(string: "45.00")
        )

        XCTAssertEqual(LoggedServiceTemplate(from: log).costString, "45")
    }

    @MainActor
    func testCostString_PreservesNonZeroDecimals() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        let log = ServiceLog(
            service: service, vehicle: vehicle,
            performedDate: Date(), mileageAtService: 30000,
            cost: Decimal(string: "45.99")
        )

        XCTAssertEqual(LoggedServiceTemplate(from: log).costString, "45.99")
    }

    @MainActor
    func testCostString_EmptyWhenCostMissing() {
        let log = ServiceLog(service: nil, vehicle: nil, performedDate: Date(), mileageAtService: 0, cost: nil)
        XCTAssertEqual(LoggedServiceTemplate(from: log).costString, "")
    }
}
