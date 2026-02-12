//
//  MileageUpdateFlowTests.swift
//  checkpointTests
//
//  Integration tests: update mileage → verify snapshot → pace calculation
//

import XCTest
import SwiftData
@testable import checkpoint

final class MileageUpdateFlowTests: XCTestCase {

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

    // MARK: - Mileage Update Tests

    @MainActor
    func testMileageUpdate_createsSnapshot() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000,
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -7, to: .now)
        )
        modelContext.insert(vehicle)

        // When: Simulate mileage update with snapshot
        let newMileage = 50300
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = Date.now

        let snapshot = MileageSnapshot(
            vehicle: vehicle,
            mileage: newMileage,
            recordedAt: Date.now,
            source: .manual
        )
        modelContext.insert(snapshot)

        // Then: Snapshot should be stored and linked to vehicle
        let snapshots = vehicle.mileageSnapshots ?? []
        XCTAssertEqual(snapshots.count, 1, "Should have one snapshot")
        XCTAssertEqual(snapshots.first?.mileage, 50300)
        XCTAssertEqual(snapshots.first?.source, .manual)
    }

    @MainActor
    func testMileageUpdate_updatesVehicleMileage() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000,
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
        )
        modelContext.insert(vehicle)

        // When
        let newMileage = 50450
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = Date.now

        // Then
        XCTAssertEqual(vehicle.currentMileage, 50450)
        XCTAssertNotNil(vehicle.mileageUpdatedAt)

        let daysSinceUpdate = vehicle.daysSinceMileageUpdate
        XCTAssertNotNil(daysSinceUpdate)
        XCTAssertEqual(daysSinceUpdate, 0, "Should show 0 days since update")
    }

    @MainActor
    func testMultipleSnapshots_calculatesPace() {
        // Given: Vehicle with snapshots spanning 10 days at ~40 miles/day
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50400,
            mileageUpdatedAt: Date.now
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        var snapshots: [MileageSnapshot] = []

        // Create snapshots over 10 days showing ~40 miles/day
        for dayOffset in stride(from: 10, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now)!
            let mileage = 50400 - (dayOffset * 40)

            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: mileage,
                recordedAt: date,
                source: .manual
            )
            modelContext.insert(snapshot)
            snapshots.append(snapshot)
        }

        vehicle.mileageSnapshots = snapshots

        // When
        let pace = vehicle.dailyMilesPace

        // Then: Pace should be approximately 40 miles/day
        XCTAssertNotNil(pace, "Should have pace with 10 days of data (>= 7 day minimum)")
        XCTAssertEqual(pace!, 40.0, accuracy: 5.0, "Pace should be approximately 40 miles/day")
    }

    @MainActor
    func testInsufficientSnapshots_returnsNilPace() {
        // Given: Vehicle with snapshots spanning only 3 days (under 7-day minimum)
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50120,
            mileageUpdatedAt: Date.now
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        var snapshots: [MileageSnapshot] = []

        for dayOffset in stride(from: 3, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now)!
            let mileage = 50120 - (dayOffset * 40)

            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: mileage,
                recordedAt: date,
                source: .manual
            )
            modelContext.insert(snapshot)
            snapshots.append(snapshot)
        }

        vehicle.mileageSnapshots = snapshots

        // When
        let pace = vehicle.dailyMilesPace

        // Then
        XCTAssertNil(pace, "Should return nil with fewer than 7 days of data")
    }
}
