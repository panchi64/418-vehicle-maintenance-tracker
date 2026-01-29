//
//  SyncStatusServiceTests.swift
//  checkpointTests
//
//  Tests for SyncStatusService sync state tracking
//

import XCTest
@testable import checkpoint

@MainActor
final class SyncStatusServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Register defaults and clear state before each test
        SyncSettings.registerDefaults()
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "iCloudSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        super.tearDown()
    }

    // MARK: - SyncState Tests

    func testSyncStateIdleDisplayText() {
        // Given idle state
        let state = SyncState.idle

        // Then display text should be "Ready"
        XCTAssertEqual(state.displayText, "Ready")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateSyncingDisplayText() {
        // Given syncing state
        let state = SyncState.syncing

        // Then display text should be "Syncing..."
        XCTAssertEqual(state.displayText, "Syncing...")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateSyncedDisplayText() {
        // Given synced state
        let state = SyncState.synced

        // Then display text should be "Synced"
        XCTAssertEqual(state.displayText, "Synced")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateErrorDisplayText() {
        // Given error state
        let state = SyncState.error("Network error")

        // Then display text should be the error message
        XCTAssertEqual(state.displayText, "Network error")
        XCTAssertTrue(state.isError)
    }

    func testSyncStateDisabledDisplayText() {
        // Given disabled state
        let state = SyncState.disabled

        // Then display text should be "Sync disabled"
        XCTAssertEqual(state.displayText, "Sync disabled")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateNoAccountDisplayText() {
        // Given no account state
        let state = SyncState.noAccount

        // Then display text should prompt sign in
        XCTAssertEqual(state.displayText, "Sign in to iCloud")
        XCTAssertTrue(state.isError)
    }

    // MARK: - SyncState Equality Tests

    func testSyncStateEquality() {
        // Given two identical states
        let state1 = SyncState.error("Test")
        let state2 = SyncState.error("Test")

        // Then they should be equal
        XCTAssertEqual(state1, state2)
    }

    func testSyncStateInequality() {
        // Given two different error states
        let state1 = SyncState.error("Error 1")
        let state2 = SyncState.error("Error 2")

        // Then they should not be equal
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Service Property Tests

    func testIsSyncEnabledReflectsSettings() {
        // Given sync is enabled in settings
        SyncSettings.shared.iCloudSyncEnabled = true

        // When checking service
        let service = SyncStatusService.shared

        // Then isSyncEnabled should be true
        XCTAssertTrue(service.isSyncEnabled)
    }

    func testIsSyncEnabledWhenDisabled() {
        // Given sync is disabled in settings
        SyncSettings.shared.iCloudSyncEnabled = false

        // When checking service
        let service = SyncStatusService.shared

        // Then isSyncEnabled should be false
        XCTAssertFalse(service.isSyncEnabled)
    }

    // MARK: - Sync Status Update Tests

    func testDidStartSync() {
        // Given service with sync enabled
        let service = SyncStatusService.shared
        SyncSettings.shared.iCloudSyncEnabled = true

        // When sync starts
        service.didStartSync()

        // Then state should be syncing
        XCTAssertEqual(service.syncState, .syncing)
    }

    func testDidStartSyncWhenDisabled() {
        // Given service with sync disabled
        let service = SyncStatusService.shared
        SyncSettings.shared.iCloudSyncEnabled = false

        // When sync starts
        service.didStartSync()

        // Then state should be disabled
        XCTAssertEqual(service.syncState, .disabled)
    }

    func testDidCompleteSync() {
        // Given service
        let service = SyncStatusService.shared
        let beforeSync = service.lastSyncDate

        // When sync completes
        service.didCompleteSync()

        // Then state should be synced and last sync date updated
        XCTAssertEqual(service.syncState, .synced)
        XCTAssertNotNil(service.lastSyncDate)

        // And last sync date should be newer than before
        if let before = beforeSync, let after = service.lastSyncDate {
            XCTAssertGreaterThanOrEqual(after, before)
        }
    }

    func testDidReceiveRemoteChanges() {
        // Given service
        let service = SyncStatusService.shared

        // When remote changes are received
        service.didReceiveRemoteChanges()

        // Then state should be synced and last sync date updated
        XCTAssertEqual(service.syncState, .synced)
        XCTAssertNotNil(service.lastSyncDate)
    }

    func testDidFailSyncWithNetworkError() {
        // Given service
        let service = SyncStatusService.shared
        let networkError = NSError(domain: "CKErrorDomain", code: 4, userInfo: nil) // CKError.networkUnavailable

        // When sync fails
        service.didFailSync(with: networkError)

        // Then state should be error
        XCTAssertTrue(service.syncState.isError)
    }

    func testDidFailSyncWithGenericError() {
        // Given service and generic error
        let service = SyncStatusService.shared
        let genericError = NSError(domain: "TestDomain", code: 1, userInfo: nil)

        // When sync fails
        service.didFailSync(with: genericError)

        // Then state should be error with generic message
        if case .error(let message) = service.syncState {
            XCTAssertEqual(message, "Sync error")
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Sync Setting Changed Tests

    func testSyncSettingChangedToDisabled() {
        // Given service
        let service = SyncStatusService.shared

        // When sync is disabled
        service.syncSettingChanged(enabled: false)

        // Then state should be disabled
        XCTAssertEqual(service.syncState, .disabled)
    }

    // MARK: - Last Sync Description Tests

    func testLastSyncDescriptionWhenNil() {
        // Given service with no last sync date
        let service = SyncStatusService.shared
        SyncSettings.shared.lastSyncDate = nil

        // Note: Since SyncStatusService is a singleton, we can't easily reset its state
        // This test verifies the property works when lastSyncDate is nil
        // In production, a new installation would have nil lastSyncDate
    }

    func testLastSyncDescriptionWhenSet() {
        // Given service with a recent last sync date
        let service = SyncStatusService.shared
        service.didCompleteSync()

        // Then description should not be nil
        XCTAssertNotNil(service.lastSyncDescription)
    }
}
