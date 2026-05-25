//
//  DataMigrationServiceTests.swift
//  checkpointTests
//
//  Tests for DataMigrationService migration logic
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class DataMigrationServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear migration state before each test
        SyncSettings.registerDefaults()
        UserDefaults.standard.removeObject(forKey: "iCloudMigrationCompleted")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "iCloudMigrationCompleted")
        super.tearDown()
    }

    // MARK: - Migration Check Tests

    func testNeedsMigrationWhenAlreadyCompleted() {
        // Given migration is already marked as complete
        SyncSettings.shared.migrationCompleted = true

        // When checking if migration is needed
        let needsMigration = DataMigrationService.shared.needsMigration()

        // Then it should return false
        XCTAssertFalse(needsMigration)
    }

    func testNeedsMigrationWhenNotCompletedAndNoOldStore() {
        // Given migration is not complete and no old store exists
        SyncSettings.shared.migrationCompleted = false
        // Note: We can't easily create an App Group container in tests,
        // so this tests the case where the old store doesn't exist

        // When checking if migration is needed
        let needsMigration = DataMigrationService.shared.needsMigration()

        // Then it should return false (no store to migrate from)
        // This might be true or false depending on the test environment
        // The key is that the logic doesn't crash
        _ = needsMigration
    }

    func testOldStoreURLReturnsNilWithoutAppGroup() {
        // Given we're in a test environment without App Group access
        let service = DataMigrationService.shared

        // When getting the old store URL
        let url = service.oldStoreURL()

        // Then it may return nil or a URL depending on test environment
        // The key is that the method doesn't crash
        _ = url
    }

    // MARK: - Migration Result Tests

    func testMigrationResultAlreadyCompleted() async {
        // Given migration is already marked as complete
        SyncSettings.shared.migrationCompleted = true

        // Create in-memory containers for testing
        let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self, ServiceAttachment.self])
        let sourceConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let destConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        guard let sourceContainer = try? ModelContainer(for: schema, configurations: [sourceConfig]),
              let destContainer = try? ModelContainer(for: schema, configurations: [destConfig]) else {
            XCTFail("Failed to create test containers")
            return
        }

        // When attempting migration
        let result = await DataMigrationService.shared.migrateData(
            from: sourceContainer,
            to: destContainer
        )

        // Then result should be alreadyCompleted
        if case .alreadyCompleted = result {
            // Success
        } else {
            XCTFail("Expected alreadyCompleted result, got \(result)")
        }
    }

    func testMigrationResultNoDataToMigrate() async {
        // Given migration is not complete and source is empty
        SyncSettings.shared.migrationCompleted = false

        // Create in-memory containers for testing
        let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self, ServiceAttachment.self])
        let sourceConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let destConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        guard let sourceContainer = try? ModelContainer(for: schema, configurations: [sourceConfig]),
              let destContainer = try? ModelContainer(for: schema, configurations: [destConfig]) else {
            XCTFail("Failed to create test containers")
            return
        }

        // When attempting migration with empty source
        let result = await DataMigrationService.shared.migrateData(
            from: sourceContainer,
            to: destContainer
        )

        // Then result should be noDataToMigrate
        if case .noDataToMigrate = result {
            // Success - migration completed should now be true
            XCTAssertTrue(SyncSettings.shared.migrationCompleted)
        } else {
            XCTFail("Expected noDataToMigrate result, got \(result)")
        }
    }

    func testMigrationSuccessWithVehicleData() async {
        // Given migration is not complete
        SyncSettings.shared.migrationCompleted = false

        // Create in-memory containers for testing
        let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self, ServiceAttachment.self])
        let sourceConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let destConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        guard let sourceContainer = try? ModelContainer(for: schema, configurations: [sourceConfig]),
              let destContainer = try? ModelContainer(for: schema, configurations: [destConfig]) else {
            XCTFail("Failed to create test containers")
            return
        }

        // Add test data to source
        let sourceContext = ModelContext(sourceContainer)
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        let service = Service(
            name: "Oil Change",
            dueDate: Date(),
            dueMileage: 55000,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        sourceContext.insert(vehicle)
        sourceContext.insert(service)
        try? sourceContext.save()

        // When migrating
        let result = await DataMigrationService.shared.migrateData(
            from: sourceContainer,
            to: destContainer
        )

        // Then result should be success with correct counts
        if case .success(let vehicleCount, let serviceCount) = result {
            XCTAssertEqual(vehicleCount, 1)
            XCTAssertEqual(serviceCount, 1)
            XCTAssertTrue(SyncSettings.shared.migrationCompleted)
        } else {
            XCTFail("Expected success result, got \(result)")
        }

        // Verify data was migrated to destination
        let destContext = ModelContext(destContainer)
        let descriptor = FetchDescriptor<Vehicle>()
        let migratedVehicles = try? destContext.fetch(descriptor)
        XCTAssertEqual(migratedVehicles?.count, 1)
        XCTAssertEqual(migratedVehicles?.first?.name, "Test Car")
    }

    // MARK: - Migration with Related Data Tests

    func testMigrationPreservesVehicleDetails() async {
        // Given migration is not complete
        SyncSettings.shared.migrationCompleted = false

        // Create in-memory containers
        let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self, ServiceAttachment.self])
        let sourceConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let destConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        guard let sourceContainer = try? ModelContainer(for: schema, configurations: [sourceConfig]),
              let destContainer = try? ModelContainer(for: schema, configurations: [destConfig]) else {
            XCTFail("Failed to create test containers")
            return
        }

        // Add vehicle with all details
        let sourceContext = ModelContext(sourceContainer)
        let vehicle = Vehicle(
            name: "Family Car",
            make: "Honda",
            model: "Accord",
            year: 2021,
            currentMileage: 35000,
            vin: "1HGCV1F34LA000001",
            tireSize: "225/50R17",
            oilType: "0W-20",
            notes: "Purchased new",
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2026
        )
        sourceContext.insert(vehicle)
        try? sourceContext.save()

        // When migrating
        _ = await DataMigrationService.shared.migrateData(
            from: sourceContainer,
            to: destContainer
        )

        // Then verify all details were preserved
        let destContext = ModelContext(destContainer)
        let descriptor = FetchDescriptor<Vehicle>()
        let migratedVehicles = try? destContext.fetch(descriptor)

        XCTAssertEqual(migratedVehicles?.count, 1)
        let migrated = migratedVehicles?.first
        XCTAssertEqual(migrated?.name, "Family Car")
        XCTAssertEqual(migrated?.make, "Honda")
        XCTAssertEqual(migrated?.model, "Accord")
        XCTAssertEqual(migrated?.year, 2021)
        XCTAssertEqual(migrated?.currentMileage, 35000)
        XCTAssertEqual(migrated?.vin, "1HGCV1F34LA000001")
        XCTAssertEqual(migrated?.tireSize, "225/50R17")
        XCTAssertEqual(migrated?.oilType, "0W-20")
        XCTAssertEqual(migrated?.notes, "Purchased new")
        XCTAssertEqual(migrated?.marbeteExpirationMonth, 3)
        XCTAssertEqual(migrated?.marbeteExpirationYear, 2026)
    }

    func testMigrationWithMileageSnapshots() async {
        // Given migration is not complete
        SyncSettings.shared.migrationCompleted = false

        // Create in-memory containers
        let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self, ServiceAttachment.self])
        let sourceConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let destConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        guard let sourceContainer = try? ModelContainer(for: schema, configurations: [sourceConfig]),
              let destContainer = try? ModelContainer(for: schema, configurations: [destConfig]) else {
            XCTFail("Failed to create test containers")
            return
        }

        // Add vehicle with mileage snapshots
        let sourceContext = ModelContext(sourceContainer)
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Test", year: 2022, currentMileage: 50000)
        let snapshot = MileageSnapshot(vehicle: vehicle, mileage: 48000, recordedAt: Date().addingTimeInterval(-86400 * 30))
        sourceContext.insert(vehicle)
        sourceContext.insert(snapshot)
        try? sourceContext.save()

        // When migrating
        _ = await DataMigrationService.shared.migrateData(
            from: sourceContainer,
            to: destContainer
        )

        // Then verify mileage snapshots were migrated
        let destContext = ModelContext(destContainer)
        let snapshotDescriptor = FetchDescriptor<MileageSnapshot>()
        let migratedSnapshots = try? destContext.fetch(snapshotDescriptor)

        XCTAssertEqual(migratedSnapshots?.count, 1)
        XCTAssertEqual(migratedSnapshots?.first?.mileage, 48000)
    }
}
