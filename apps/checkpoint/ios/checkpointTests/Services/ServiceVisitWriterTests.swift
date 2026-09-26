//
//  ServiceVisitWriterTests.swift
//  checkpointTests
//
//  One visit, one total, a log per service: tracked services complete and
//  chain forward, new ones are created, and the odometer follows F11.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceVisitWriterTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var vehicle: Vehicle!

    override func setUp() {
        super.setUp()
        container = .inMemoryForTesting()
        context = container.mainContext
        vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020, currentMileage: 45_000)
        vehicle.mileageUpdatedAt = Date(timeIntervalSinceNow: -86_400)
        context.insert(vehicle)
    }

    override func tearDown() {
        container = nil
        context = nil
        vehicle = nil
        super.tearDown()
    }

    func test_record_trackedAndNew_oneVisitOneTotal() throws {
        let oil = Service(name: "Oil Change", dueMileage: 45_500, intervalMiles: 5_000, isRecurring: true)
        oil.vehicle = vehicle
        context.insert(oil)

        let visit = ServiceVisitWriter.record(
            [.tracked(oil), .new(name: "Cabin Air Filter", intervalMonths: 12, intervalMiles: nil)],
            on: vehicle,
            details: .init(performedDate: .now, mileage: 45_200, totalCost: 140, shopName: "Firestone"),
            in: context
        )

        XCTAssertEqual(visit.logs?.count, 2)
        XCTAssertEqual(visit.totalCost, 140)
        XCTAssertEqual(visit.costCategory, .maintenance)
        XCTAssertEqual(visit.shopName, "Firestone")
        XCTAssertTrue(visit.logs?.allSatisfy { $0.cost == nil } ?? false)
        XCTAssertFalse(oil.hasDueTracking, "The tracked occurrence closes")

        let services = try context.fetch(FetchDescriptor<Service>())
        let successor = services.first { $0.name == "Oil Change" && $0.hasDueTracking }
        XCTAssertEqual(successor?.dueMileage, 50_200, "Chains forward from the visit's odometer")
        let cabin = try XCTUnwrap(services.first { $0.name == "Cabin Air Filter" })
        XCTAssertTrue(cabin.isRecurring)
        XCTAssertNotNil(cabin.dueDate)
        XCTAssertEqual(vehicle.currentMileage, 45_200)
    }

    func test_record_noCost_leavesCategoryEmpty() {
        let visit = ServiceVisitWriter.record(
            [.new(name: "Detailing", intervalMonths: nil, intervalMiles: nil)],
            on: vehicle,
            details: .init(performedDate: .now, mileage: 45_000),
            in: context
        )
        XCTAssertNil(visit.totalCost)
        XCTAssertNil(visit.costCategory)
        XCTAssertFalse(visit.logs?.first?.service?.hasDueTracking ?? true)
    }

    func test_record_backfill_doesNotMoveTheOdometer() {
        let longAgo = Date(timeIntervalSinceNow: -86_400 * 200)
        ServiceVisitWriter.record(
            [.new(name: "Brake Inspection", intervalMonths: nil, intervalMiles: nil)],
            on: vehicle,
            details: .init(performedDate: longAgo, mileage: 60_000),
            in: context
        )
        XCTAssertEqual(vehicle.currentMileage, 45_000, "F11: an older reading is history, not news")
    }
}
