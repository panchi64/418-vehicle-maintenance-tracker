//
//  SyncSettingsTests.swift
//  checkpointTests
//
//  Tests for SyncSettings user preferences
//

import XCTest
@testable import checkpoint

@MainActor
final class SyncSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "iCloudSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "iCloudMigrationCompleted")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
    }

    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "iCloudSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "iCloudMigrationCompleted")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        super.tearDown()
    }

    // MARK: - Default Values Tests

    func testDefaultsRegistration() {
        // When defaults are registered
        SyncSettings.registerDefaults()

        // Then iCloud sync should be enabled by default
        let defaults = UserDefaults.standard
        XCTAssertTrue(defaults.bool(forKey: "iCloudSyncEnabled"))
        XCTAssertFalse(defaults.bool(forKey: "iCloudMigrationCompleted"))
    }

    // MARK: - iCloud Sync Enabled Tests

    func testICloudSyncEnabledDefaultValue() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When accessing iCloudSyncEnabled
        // Then it should be true by default (for new users)
        XCTAssertTrue(SyncSettings.shared.iCloudSyncEnabled)
    }

    func testICloudSyncEnabledCanBeDisabled() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When disabling iCloud sync
        SyncSettings.shared.iCloudSyncEnabled = false

        // Then it should be disabled
        XCTAssertFalse(SyncSettings.shared.iCloudSyncEnabled)
    }

    func testICloudSyncEnabledPersists() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When setting iCloud sync to false
        SyncSettings.shared.iCloudSyncEnabled = false

        // Then reading from UserDefaults directly should also be false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "iCloudSyncEnabled"))
    }

    // MARK: - Migration Completed Tests

    func testMigrationCompletedDefaultValue() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When accessing migrationCompleted
        // Then it should be false by default
        XCTAssertFalse(SyncSettings.shared.migrationCompleted)
    }

    func testMigrationCompletedCanBeSet() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When marking migration as completed
        SyncSettings.shared.migrationCompleted = true

        // Then it should be true
        XCTAssertTrue(SyncSettings.shared.migrationCompleted)
    }

    func testMigrationCompletedPersists() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When marking migration as completed
        SyncSettings.shared.migrationCompleted = true

        // Then reading from UserDefaults directly should also be true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "iCloudMigrationCompleted"))
    }

    // MARK: - Last Sync Date Tests

    func testLastSyncDateDefaultValue() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When accessing lastSyncDate without setting it
        // Then it should be nil
        XCTAssertNil(SyncSettings.shared.lastSyncDate)
    }

    func testLastSyncDateCanBeSet() {
        // Given defaults are registered and a date
        SyncSettings.registerDefaults()
        let testDate = Date()

        // When setting the last sync date
        SyncSettings.shared.lastSyncDate = testDate

        // Then it should be set
        XCTAssertNotNil(SyncSettings.shared.lastSyncDate)
        // Compare with tolerance for floating point date conversion
        XCTAssertEqual(
            SyncSettings.shared.lastSyncDate!.timeIntervalSince1970,
            testDate.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testLastSyncDateCanBeCleared() {
        // Given a set last sync date
        SyncSettings.registerDefaults()
        SyncSettings.shared.lastSyncDate = Date()
        XCTAssertNotNil(SyncSettings.shared.lastSyncDate)

        // When clearing the date
        SyncSettings.shared.lastSyncDate = nil

        // Then it should be nil
        XCTAssertNil(SyncSettings.shared.lastSyncDate)
    }

    // MARK: - Integration Tests

    func testMultipleSettingsCanBeModified() {
        // Given defaults are registered
        SyncSettings.registerDefaults()

        // When modifying multiple settings
        SyncSettings.shared.iCloudSyncEnabled = false
        SyncSettings.shared.migrationCompleted = true
        SyncSettings.shared.lastSyncDate = Date()

        // Then all settings should reflect the changes
        XCTAssertFalse(SyncSettings.shared.iCloudSyncEnabled)
        XCTAssertTrue(SyncSettings.shared.migrationCompleted)
        XCTAssertNotNil(SyncSettings.shared.lastSyncDate)
    }
}
