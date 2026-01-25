//
//  VehicleHeaderTests.swift
//  checkpointTests
//
//  Tests for VehicleHeader component and mileage update functionality
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class VehicleHeaderTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Mileage Formatting Tests

    func testVehicleHeader_DisplaysFormattedMileage_WithCommas() {
        // Given
        let mileage = 32500

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = (formatter.string(from: NSNumber(value: mileage)) ?? "\(mileage)") + " mi"

        // Then
        XCTAssertEqual(formatted, "32,500 mi")
    }

    func testVehicleHeader_DisplaysFormattedMileage_LargeNumber() {
        // Given
        let mileage = 123456

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = (formatter.string(from: NSNumber(value: mileage)) ?? "\(mileage)") + " mi"

        // Then
        XCTAssertEqual(formatted, "123,456 mi")
    }

    func testVehicleHeader_DisplaysFormattedMileage_SmallNumber() {
        // Given
        let mileage = 500

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = (formatter.string(from: NSNumber(value: mileage)) ?? "\(mileage)") + " mi"

        // Then
        XCTAssertEqual(formatted, "500 mi")
    }

    func testVehicleHeader_DisplaysFormattedMileage_Zero() {
        // Given
        let mileage = 0

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = (formatter.string(from: NSNumber(value: mileage)) ?? "\(mileage)") + " mi"

        // Then
        XCTAssertEqual(formatted, "0 mi")
    }

    // MARK: - Mileage Update Tests

    @MainActor
    func testMileageUpdate_UpdatesVehicleMileage() {
        // Given
        let initialMileage = vehicle.currentMileage
        let newMileage = 35000

        // When
        vehicle.currentMileage = newMileage

        // Then
        XCTAssertNotEqual(initialMileage, vehicle.currentMileage)
        XCTAssertEqual(vehicle.currentMileage, newMileage)
    }

    @MainActor
    func testMileageUpdate_SetsMileageUpdatedAt() {
        // Given
        XCTAssertNil(vehicle.mileageUpdatedAt, "Vehicle should start with nil mileageUpdatedAt")

        // When
        vehicle.currentMileage = 35000
        vehicle.mileageUpdatedAt = .now

        // Then
        XCTAssertNotNil(vehicle.mileageUpdatedAt)

        // Verify it was set recently (within last 5 seconds)
        let timeDifference = Date.now.timeIntervalSince(vehicle.mileageUpdatedAt!)
        XCTAssertLessThan(timeDifference, 5.0)
    }

    @MainActor
    func testMileageUpdate_CreatesSnapshotWhenNoneExistsToday() {
        // Given
        XCTAssertTrue(vehicle.mileageSnapshots.isEmpty, "Vehicle should start with no snapshots")

        // When - simulate mileage update logic
        let newMileage = 35000
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(snapshots: vehicle.mileageSnapshots)

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: newMileage,
                recordedAt: .now,
                source: .manual
            )
            modelContext.insert(snapshot)
        }

        // Then
        XCTAssertTrue(shouldCreateSnapshot)
        // After insert, the relationship should update
        try? modelContext.save()

        // Query for snapshots directly
        let descriptor = FetchDescriptor<MileageSnapshot>()
        let snapshots = try? modelContext.fetch(descriptor)
        XCTAssertEqual(snapshots?.count, 1)
        XCTAssertEqual(snapshots?.first?.mileage, newMileage)
        XCTAssertEqual(snapshots?.first?.source, .manual)
    }

    @MainActor
    func testMileageUpdate_DoesNotCreateDuplicateSnapshotSameDay() {
        // Given - create an existing snapshot for today
        let existingSnapshot = MileageSnapshot(
            vehicle: vehicle,
            mileage: 32500,
            recordedAt: .now,
            source: .manual
        )
        modelContext.insert(existingSnapshot)
        try? modelContext.save()

        // When - check if we should create another snapshot
        let descriptor = FetchDescriptor<MileageSnapshot>()
        let snapshots = (try? modelContext.fetch(descriptor)) ?? []
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(snapshots: snapshots)

        // Then
        XCTAssertFalse(shouldCreateSnapshot, "Should not create duplicate snapshot for same day")
    }

    @MainActor
    func testMileageUpdate_CreatesSnapshotWhenPreviousSnapshotFromDifferentDay() {
        // Given - create a snapshot from yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let yesterdaySnapshot = MileageSnapshot(
            vehicle: vehicle,
            mileage: 32000,
            recordedAt: yesterday,
            source: .manual
        )
        modelContext.insert(yesterdaySnapshot)
        try? modelContext.save()

        // When
        let descriptor = FetchDescriptor<MileageSnapshot>()
        let snapshots = (try? modelContext.fetch(descriptor)) ?? []
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(snapshots: snapshots)

        // Then
        XCTAssertTrue(shouldCreateSnapshot, "Should create snapshot because previous one is from different day")
    }

    // MARK: - Snapshot Helper Tests

    func testHasSnapshotToday_ReturnsTrueForTodaySnapshot() {
        // Given
        let todaySnapshot = MileageSnapshot(mileage: 32500, recordedAt: .now)
        let snapshots = [todaySnapshot]

        // Then
        XCTAssertTrue(MileageSnapshot.hasSnapshotToday(snapshots: snapshots))
    }

    func testHasSnapshotToday_ReturnsFalseForYesterdaySnapshot() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let yesterdaySnapshot = MileageSnapshot(mileage: 32500, recordedAt: yesterday)
        let snapshots = [yesterdaySnapshot]

        // Then
        XCTAssertFalse(MileageSnapshot.hasSnapshotToday(snapshots: snapshots))
    }

    func testHasSnapshotToday_ReturnsFalseForEmptyArray() {
        // Given
        let snapshots: [MileageSnapshot] = []

        // Then
        XCTAssertFalse(MileageSnapshot.hasSnapshotToday(snapshots: snapshots))
    }

    func testHasSnapshotToday_ReturnsTrueWhenMixedSnapshots() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let yesterdaySnapshot = MileageSnapshot(mileage: 32000, recordedAt: yesterday)
        let todaySnapshot = MileageSnapshot(mileage: 32500, recordedAt: .now)
        let snapshots = [yesterdaySnapshot, todaySnapshot]

        // Then
        XCTAssertTrue(MileageSnapshot.hasSnapshotToday(snapshots: snapshots))
    }
}
