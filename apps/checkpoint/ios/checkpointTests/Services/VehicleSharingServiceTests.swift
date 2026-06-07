//
//  VehicleSharingServiceTests.swift
//  checkpointTests
//
//  Tests for the cross-app odometer bridge: the shared mileage-commit helper
//  (Vehicle.recordMileage) and the queued-update validation rule.
//

import XCTest
import SwiftData
@testable import checkpoint

final class VehicleSharingServiceTests: XCTestCase {
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

    // MARK: - Vehicle.recordMileage

    @MainActor
    func test_recordMileage_updatesValueAndCreatesSnapshot() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        modelContext.insert(vehicle)

        let created = vehicle.recordMileage(50300, source: .biombo, in: modelContext)

        XCTAssertTrue(created)
        XCTAssertEqual(vehicle.currentMileage, 50300)
        XCTAssertNotNil(vehicle.mileageUpdatedAt)
        let snapshots = vehicle.mileageSnapshots ?? []
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.mileage, 50300)
        XCTAssertEqual(snapshots.first?.source, .biombo)
    }

    @MainActor
    func test_recordMileage_throttlesToOneSnapshotPerDay() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        modelContext.insert(vehicle)

        let first = vehicle.recordMileage(50100, source: .manual, in: modelContext)
        let second = vehicle.recordMileage(50200, source: .biombo, in: modelContext)

        XCTAssertTrue(first)
        XCTAssertFalse(second, "A second reading the same day should not create another snapshot")
        XCTAssertEqual(vehicle.currentMileage, 50200, "Value still updates even when snapshot is throttled")
        XCTAssertEqual(vehicle.mileageSnapshots?.count, 1)
    }

    // MARK: - shouldApply validation

    func test_shouldApply_acceptsForwardReadings() {
        XCTAssertTrue(VehicleSharingService.shouldApply(mileage: 51000, toCurrentMileage: 50000))
        XCTAssertTrue(VehicleSharingService.shouldApply(mileage: 50000, toCurrentMileage: 50000))
    }

    func test_shouldApply_rejectsBackwardOrNonPositive() {
        XCTAssertFalse(VehicleSharingService.shouldApply(mileage: 49000, toCurrentMileage: 50000))
        XCTAssertFalse(VehicleSharingService.shouldApply(mileage: 0, toCurrentMileage: 0))
        XCTAssertFalse(VehicleSharingService.shouldApply(mileage: -5, toCurrentMileage: 0))
    }
}
