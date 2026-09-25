//
//  SyncStatusTests.swift
//  checkpointTests
//
//  The iCloud sync status mappings: CloudKit errors → SyncError, account
//  status → availability, container events → activity, and all of it → what
//  Settings shows. None of this needs an iCloud account.
//

import XCTest
import CloudKit
@testable import checkpoint

@MainActor
final class SyncStatusTests: XCTestCase {

    // MARK: - Helpers

    private func inputs(
        isEnabled: Bool = true,
        isActiveThisLaunch: Bool = true,
        account: SyncAccountStatus = .available,
        state: SyncState = .idle,
        lastSyncDate: Date? = nil
    ) -> SyncStatusInputs {
        SyncStatusInputs(
            isEnabled: isEnabled,
            isActiveThisLaunch: isActiveThisLaunch,
            account: account,
            state: state,
            lastSyncDate: lastSyncDate
        )
    }

    private func event(
        _ id: UUID,
        _ kind: SyncEvent.Kind,
        ended: Date? = nil,
        succeeded: Bool = false,
        error: SyncError? = nil
    ) -> SyncEvent {
        SyncEvent(id: id, kind: kind, endDate: ended, succeeded: succeeded, error: error)
    }

    // MARK: - Display resolution

    func testResolve_syncOff_showsNoRow() {
        XCTAssertNil(SyncStatusDisplay.resolve(inputs(isEnabled: false, isActiveThisLaunch: false)))
    }

    func testResolve_toggleChangedThisSession_isPendingRestart() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(isEnabled: false, isActiveThisLaunch: true)), .pendingRestart)
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(isEnabled: true, isActiveThisLaunch: false)), .pendingRestart)
    }

    func testResolve_pendingRestartWinsOverAccount() {
        let resolved = SyncStatusDisplay.resolve(inputs(isEnabled: true, isActiveThisLaunch: false, account: .unavailable))
        XCTAssertEqual(resolved, .pendingRestart)
    }

    func testResolve_noAccount_isUnavailable() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(account: .unavailable, state: .syncing)), .unavailable)
    }

    func testResolve_notAuthenticatedError_isUnavailable() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(state: .error(.notSignedIn))), .unavailable)
    }

    func testResolve_unknownAccount_fallsThroughToActivity() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(account: .unknown, state: .syncing)), .syncing)
    }

    func testResolve_syncing() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(state: .syncing)), .syncing)
    }

    func testResolve_idle_isUpToDateWithLastSyncDate() {
        let date = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(lastSyncDate: date)), .upToDate(lastSynced: date))
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(lastSyncDate: nil)), .upToDate(lastSynced: nil))
    }

    func testResolve_error_isFailed() {
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(state: .error(.quotaExceeded))), .failed(.quotaExceeded))
        XCTAssertEqual(SyncStatusDisplay.resolve(inputs(state: .error(.unknown))), .failed(.unknown))
    }

    func testFailureReason_onlyForKnownCases() {
        XCTAssertEqual(SyncStatusDisplay.failureReason(.quotaExceeded), L10n.syncErrorQuotaExceeded)
        XCTAssertEqual(SyncStatusDisplay.failureReason(.networkUnavailable), L10n.syncErrorOffline)
        XCTAssertNil(SyncStatusDisplay.failureReason(.unknown))
    }

    // MARK: - Account status

    func testAccountStatus_mapping() {
        XCTAssertEqual(SyncAccountStatus(.available), .available)
        XCTAssertEqual(SyncAccountStatus(.noAccount), .unavailable)
        XCTAssertEqual(SyncAccountStatus(.restricted), .unavailable)
        XCTAssertEqual(SyncAccountStatus(.temporarilyUnavailable), .unavailable)
        XCTAssertEqual(SyncAccountStatus(.couldNotDetermine), .unknown)
    }

    // MARK: - Error classification

    func testSyncError_cloudKitCodes() {
        XCTAssertEqual(SyncError(CKError(.quotaExceeded)), .quotaExceeded)
        XCTAssertEqual(SyncError(CKError(.networkUnavailable)), .networkUnavailable)
        XCTAssertEqual(SyncError(CKError(.networkFailure)), .networkUnavailable)
        XCTAssertEqual(SyncError(CKError(.notAuthenticated)), .notSignedIn)
        XCTAssertEqual(SyncError(CKError(.serverRejectedRequest)), .unknown)
    }

    func testSyncError_partialFailureUsesMostActionableItemError() {
        let error = CKError(.partialFailure, userInfo: [
            CKPartialErrorsByItemIDKey: [
                CKRecord.ID(recordName: "a"): CKError(.batchRequestFailed),
                CKRecord.ID(recordName: "b"): CKError(.networkFailure),
                CKRecord.ID(recordName: "c"): CKError(.quotaExceeded)
            ]
        ])
        XCTAssertEqual(SyncError(error), .quotaExceeded)
    }

    func testSyncError_urlErrorIsNoConnection() {
        XCTAssertEqual(SyncError(URLError(.notConnectedToInternet)), .networkUnavailable)
    }

    func testSyncError_unwrapsUnderlyingError() {
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 134_400, userInfo: [
            NSUnderlyingErrorKey: CKError(.quotaExceeded) as NSError
        ])
        XCTAssertEqual(SyncError(wrapped), .quotaExceeded)
    }

    func testSyncError_unrecognizedIsUnknown() {
        let error = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "raw text"])
        XCTAssertEqual(SyncError(error), .unknown)
    }

    // MARK: - Activity

    func testActivity_startedEventIsSyncing() {
        var activity = SyncActivity()
        activity.apply(event(UUID(), .import))
        XCTAssertEqual(activity.state, .syncing)
    }

    func testActivity_staysSyncingUntilEveryEventEnds() {
        var activity = SyncActivity()
        let importID = UUID(), exportID = UUID()
        activity.apply(event(importID, .import))
        activity.apply(event(exportID, .export))
        activity.apply(event(importID, .import, ended: .now, succeeded: true))
        XCTAssertEqual(activity.state, .syncing)
        activity.apply(event(exportID, .export, ended: .now, succeeded: true))
        XCTAssertEqual(activity.state, .idle)
    }

    func testActivity_successRecordsLastSync() {
        var activity = SyncActivity()
        let id = UUID()
        let end = Date(timeIntervalSince1970: 5_000)
        activity.apply(event(id, .export))
        activity.apply(event(id, .export, ended: end, succeeded: true))
        XCTAssertEqual(activity.lastSuccess, end)
    }

    func testActivity_setupSuccessIsNotASync() {
        var activity = SyncActivity()
        activity.apply(event(UUID(), .setup, ended: .now, succeeded: true))
        XCTAssertNil(activity.lastSuccess)
    }

    func testActivity_failureShowsUntilSameKindSucceeds() {
        var activity = SyncActivity()
        activity.apply(event(UUID(), .export, ended: .now, succeeded: false, error: .quotaExceeded))
        XCTAssertEqual(activity.state, .error(.quotaExceeded))

        // An import succeeding says nothing about the failed export.
        activity.apply(event(UUID(), .import, ended: .now, succeeded: true))
        XCTAssertEqual(activity.state, .error(.quotaExceeded))

        activity.apply(event(UUID(), .export, ended: .now, succeeded: true))
        XCTAssertEqual(activity.state, .idle)
    }

    func testActivity_failureWithoutErrorIsUnknown() {
        var activity = SyncActivity()
        activity.apply(event(UUID(), .import, ended: .now, succeeded: false))
        XCTAssertEqual(activity.state, .error(.unknown))
    }

    func testActivity_offlineReadsAsNoConnection() {
        var activity = SyncActivity()
        activity.isOffline = true
        XCTAssertEqual(activity.state, .error(.networkUnavailable))
        activity.isOffline = false
        XCTAssertEqual(activity.state, .idle)
    }

    func testActivity_keepsPersistedLastSync() {
        let date = Date(timeIntervalSince1970: 9_000)
        XCTAssertEqual(SyncActivity(lastSuccess: date).lastSuccess, date)
    }

    // MARK: - Service

    func testTestingInstance_startsIdleWithoutAccount() {
        let service = SyncStatusService(forTesting: true)
        XCTAssertEqual(service.syncState, .idle)
        XCTAssertEqual(service.account, .unknown)
        XCTAssertFalse(service.hasICloudAccount)
        XCTAssertNil(service.lastSyncDate)
        XCTAssertNil(service.currentError)
    }

    func testService_applyDrivesStateAndCurrentError() {
        let service = SyncStatusService(forTesting: true)
        service.apply(SyncEvent(id: UUID(), kind: .export, endDate: .now, succeeded: false, error: .networkUnavailable))
        XCTAssertEqual(service.currentError, .networkUnavailable)
    }
}
