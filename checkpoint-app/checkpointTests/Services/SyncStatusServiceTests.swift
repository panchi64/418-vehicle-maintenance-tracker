//
//  SyncStatusServiceTests.swift
//  checkpointTests
//
//  Tests for SyncStatusService sync state tracking and SyncError properties
//

import XCTest
import SwiftUI
@testable import checkpoint

@MainActor
final class SyncStatusServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SyncSettings.registerDefaults()
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "iCloudSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        super.tearDown()
    }

    // MARK: - SyncError Tests

    func testSyncErrorNotSignedIn_Properties() {
        let error = SyncError.notSignedIn
        XCTAssertEqual(error.userMessage, "Sign in to iCloud to sync across devices")
        XCTAssertEqual(error.actionLabel, "Open Settings")
        XCTAssertEqual(error.systemImage, "icloud.slash")
        XCTAssertEqual(error.iconColor, Theme.textTertiary)
        XCTAssertFalse(error.isTransient)
    }

    func testSyncErrorQuotaExceeded_Properties() {
        let error = SyncError.quotaExceeded
        XCTAssertEqual(error.userMessage, "iCloud storage full. Data safe locally.")
        XCTAssertEqual(error.actionLabel, "Manage Storage")
        XCTAssertEqual(error.systemImage, "exclamationmark.icloud")
        XCTAssertEqual(error.iconColor, Theme.statusOverdue)
        XCTAssertFalse(error.isTransient)
    }

    func testSyncErrorNetworkUnavailable_Properties() {
        let error = SyncError.networkUnavailable
        XCTAssertEqual(error.userMessage, "Offline. Changes sync when connected.")
        XCTAssertNil(error.actionLabel)
        XCTAssertEqual(error.systemImage, "wifi.slash")
        XCTAssertEqual(error.iconColor, Theme.textTertiary)
        XCTAssertTrue(error.isTransient)
    }

    func testSyncErrorUnknown_Properties() {
        let error = SyncError.unknown("Something went wrong")
        XCTAssertEqual(error.userMessage, "Something went wrong")
        XCTAssertNil(error.actionLabel)
        XCTAssertEqual(error.systemImage, "exclamationmark.icloud")
        XCTAssertEqual(error.iconColor, Theme.statusOverdue)
        XCTAssertTrue(error.isTransient)
    }

    // MARK: - SyncError Equality Tests

    func testSyncErrorEquality_SameType() {
        XCTAssertEqual(SyncError.notSignedIn, SyncError.notSignedIn)
        XCTAssertEqual(SyncError.quotaExceeded, SyncError.quotaExceeded)
        XCTAssertEqual(SyncError.networkUnavailable, SyncError.networkUnavailable)
        XCTAssertEqual(SyncError.unknown("test"), SyncError.unknown("test"))
    }

    func testSyncErrorInequality_DifferentTypes() {
        XCTAssertNotEqual(SyncError.notSignedIn, SyncError.quotaExceeded)
        XCTAssertNotEqual(SyncError.networkUnavailable, SyncError.notSignedIn)
    }

    func testSyncErrorInequality_DifferentUnknownMessages() {
        XCTAssertNotEqual(SyncError.unknown("test1"), SyncError.unknown("test2"))
    }

    // MARK: - SyncState Tests

    func testSyncStateIdleDisplayText() {
        let state = SyncState.idle
        XCTAssertEqual(state.displayText, "Synced")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateSyncingDisplayText() {
        let state = SyncState.syncing
        XCTAssertEqual(state.displayText, "Syncing...")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateSyncedDisplayText() {
        let state = SyncState.synced
        XCTAssertEqual(state.displayText, "Synced")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateErrorDisplayText() {
        let state = SyncState.error(.networkUnavailable)
        XCTAssertEqual(state.displayText, "Offline. Changes sync when connected.")
        XCTAssertTrue(state.isError)
    }

    func testSyncStateDisabledDisplayText() {
        let state = SyncState.disabled
        XCTAssertEqual(state.displayText, "Sync disabled")
        XCTAssertFalse(state.isError)
    }

    func testSyncStateNoAccountDisplayText() {
        let state = SyncState.noAccount
        XCTAssertEqual(state.displayText, "Sign in to iCloud")
        XCTAssertTrue(state.isError)
    }

    // MARK: - SyncState Equality Tests

    func testSyncStateEquality() {
        let state1 = SyncState.error(.notSignedIn)
        let state2 = SyncState.error(.notSignedIn)
        XCTAssertEqual(state1, state2)
    }

    func testSyncStateInequality() {
        let state1 = SyncState.error(.notSignedIn)
        let state2 = SyncState.error(.quotaExceeded)
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Service Property Tests

    func testIsSyncEnabledReflectsSettings() {
        SyncSettings.shared.iCloudSyncEnabled = true
        let service = SyncStatusService.shared
        XCTAssertTrue(service.isSyncEnabled)
    }

    func testIsSyncEnabledWhenDisabled() {
        SyncSettings.shared.iCloudSyncEnabled = false
        let service = SyncStatusService.shared
        XCTAssertFalse(service.isSyncEnabled)
    }

    // MARK: - Testing Instance Tests

    func testTestingInstanceInitialState() {
        let service = SyncStatusService(forTesting: true)
        XCTAssertEqual(service.syncState, .idle)
        XCTAssertNil(service.lastSyncDate)
        XCTAssertFalse(service.hasICloudAccount)
        XCTAssertFalse(service.hasError)
        XCTAssertNil(service.currentError)
    }

    // MARK: - Sync Status Update Tests

    func testDidStartSync() {
        let service = SyncStatusService.shared
        SyncSettings.shared.iCloudSyncEnabled = true
        service.didStartSync()
        XCTAssertEqual(service.syncState, .syncing)
    }

    func testDidStartSyncWhenDisabled() {
        let service = SyncStatusService.shared
        SyncSettings.shared.iCloudSyncEnabled = false
        service.didStartSync()
        XCTAssertEqual(service.syncState, .disabled)
    }

    func testDidCompleteSync() {
        let service = SyncStatusService.shared
        let beforeSync = service.lastSyncDate
        service.didCompleteSync()
        XCTAssertEqual(service.syncState, .synced)
        XCTAssertNotNil(service.lastSyncDate)
        if let before = beforeSync, let after = service.lastSyncDate {
            XCTAssertGreaterThanOrEqual(after, before)
        }
    }

    func testDidReceiveRemoteChanges() {
        let service = SyncStatusService.shared
        service.didReceiveRemoteChanges()
        XCTAssertEqual(service.syncState, .synced)
        XCTAssertNotNil(service.lastSyncDate)
    }

    func testDidFailSyncWithNetworkError() {
        let service = SyncStatusService.shared
        let networkError = NSError(domain: "CKErrorDomain", code: 4, userInfo: nil)
        service.didFailSync(with: networkError)
        XCTAssertTrue(service.syncState.isError)
    }

    func testDidFailSyncWithGenericError() {
        let service = SyncStatusService.shared
        let genericError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        service.didFailSync(with: genericError)
        if case .error(let syncError) = service.syncState {
            XCTAssertEqual(syncError, .unknown("Sync error"))
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - HasError / CurrentError Tests

    func testHasError_TrueWhenError() {
        let service = SyncStatusService.shared
        let error = NSError(domain: "CKErrorDomain", code: 4, userInfo: nil)
        service.didFailSync(with: error)
        XCTAssertTrue(service.hasError)
        XCTAssertNotNil(service.currentError)
    }

    func testHasError_FalseWhenIdle() {
        let service = SyncStatusService(forTesting: true)
        XCTAssertFalse(service.hasError)
        XCTAssertNil(service.currentError)
    }

    // MARK: - Sync Setting Changed Tests

    func testSyncSettingChangedToDisabled() {
        let service = SyncStatusService.shared
        service.syncSettingChanged(enabled: false)
        XCTAssertEqual(service.syncState, .disabled)
    }

    // MARK: - Last Sync Description Tests

    func testLastSyncDescriptionWhenNil() {
        let service = SyncStatusService(forTesting: true)
        XCTAssertNil(service.lastSyncDescription)
    }

    func testLastSyncDescriptionWhenSet() {
        let service = SyncStatusService.shared
        service.didCompleteSync()
        XCTAssertNotNil(service.lastSyncDescription)
    }

    // MARK: - SyncError IsTransient Tests

    func testTransientErrors() {
        XCTAssertTrue(SyncError.networkUnavailable.isTransient)
        XCTAssertTrue(SyncError.unknown("test").isTransient)
    }

    func testNonTransientErrors() {
        XCTAssertFalse(SyncError.notSignedIn.isTransient)
        XCTAssertFalse(SyncError.quotaExceeded.isTransient)
    }
}
