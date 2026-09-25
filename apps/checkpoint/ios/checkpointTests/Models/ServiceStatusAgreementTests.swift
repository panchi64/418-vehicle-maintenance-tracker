//
//  ServiceStatusAgreementTests.swift
//  checkpointTests
//
//  One mileage source for status. The Services list judges status by the
//  vehicle's effective (estimated-if-available) mileage; the detail screen and
//  the app icon judged it by raw `currentMileage`, so a row could say OVERDUE
//  and the screen it opened say GOOD.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceStatusAgreementTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    /// Last reading 30,000 ten days ago at ~100 mi/day, so the estimate is
    /// ~31,000 — past a 30,500 due mileage the raw reading hasn't reached.
    private func makeVehicleWithEstimateAheadOfReading() -> Vehicle {
        let lastReadingAt = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        let firstReadingAt = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        vehicle.mileageUpdatedAt = lastReadingAt
        context.insert(vehicle)
        context.insert(MileageSnapshot(vehicle: vehicle, mileage: 28000, recordedAt: firstReadingAt))
        context.insert(MileageSnapshot(vehicle: vehicle, mileage: 30000, recordedAt: lastReadingAt))
        return vehicle
    }

    private func makeService(on vehicle: Vehicle) -> Service {
        let service = Service(name: "Oil Change", dueMileage: 30500)
        service.vehicle = vehicle
        context.insert(service)
        return service
    }

    func testStatusOnVehicle_MatchesListComputation() {
        let vehicle = makeVehicleWithEstimateAheadOfReading()
        let service = makeService(on: vehicle)
        let estimate = vehicle.mileageEstimate
        XCTAssertTrue(estimate.isEstimated, "Precondition: the vehicle should have an estimate")
        XCTAssertGreaterThan(estimate.effective, 30500, "Precondition: the estimate should be past due")

        // What ServicesTab / ServiceRow compute from the resolved estimate.
        let listStatus = service.status(currentMileage: estimate.effective)

        XCTAssertEqual(service.status(on: vehicle), listStatus)
        XCTAssertEqual(service.status(on: vehicle), .overdue)
    }

    func testStatusOnVehicle_DiffersFromRawReadingWhenEstimateIsAhead() {
        // Guards the premise: if these ever agree, the test above proves nothing.
        let vehicle = makeVehicleWithEstimateAheadOfReading()
        let service = makeService(on: vehicle)

        XCTAssertNotEqual(service.status(currentMileage: vehicle.currentMileage), .overdue)
        XCTAssertEqual(service.status(on: vehicle), .overdue)
    }

    func testUpcomingItemStatus_UsesSameSource() {
        let vehicle = makeVehicleWithEstimateAheadOfReading()
        let service = makeService(on: vehicle)

        XCTAssertEqual(service.itemStatus, service.status(on: vehicle))
    }

    func testStatusOnVehicle_NoEstimate_FallsBackToReading() {
        let vehicle = Vehicle(name: "New", make: "Honda", model: "Civic", year: 2021, currentMileage: 30600)
        context.insert(vehicle)
        let service = makeService(on: vehicle)

        XCTAssertEqual(service.status(on: vehicle), service.status(currentMileage: 30600))
        XCTAssertEqual(service.status(on: vehicle), .overdue)
    }
}
