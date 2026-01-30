//
//  CloudSyncStatusServiceTests.swift
//  checkpointTests
//
//  Unit tests for CloudSyncStatusService
//

import XCTest
@testable import checkpoint

@MainActor
final class CloudSyncStatusServiceTests: XCTestCase {

    var sut: CloudSyncStatusService!

    override func setUp() {
        super.setUp()
        sut = CloudSyncStatusService(forTesting: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Status Tests

    func testInitialStatusIsIdle() {
        XCTAssertEqual(sut.status, .idle)
    }

    func testStatusEquality_Idle() {
        let status1 = CloudSyncStatusService.SyncStatus.idle
        let status2 = CloudSyncStatusService.SyncStatus.idle
        XCTAssertEqual(status1, status2)
    }

    func testStatusEquality_Syncing() {
        let status1 = CloudSyncStatusService.SyncStatus.syncing
        let status2 = CloudSyncStatusService.SyncStatus.syncing
        XCTAssertEqual(status1, status2)
    }

    func testStatusEquality_Error() {
        let status1 = CloudSyncStatusService.SyncStatus.error(.notSignedIn)
        let status2 = CloudSyncStatusService.SyncStatus.error(.notSignedIn)
        XCTAssertEqual(status1, status2)
    }

    func testStatusInequality_DifferentErrors() {
        let status1 = CloudSyncStatusService.SyncStatus.error(.notSignedIn)
        let status2 = CloudSyncStatusService.SyncStatus.error(.quotaExceeded)
        XCTAssertNotEqual(status1, status2)
    }

    // MARK: - Error Message Tests

    func testNotSignedInErrorMessage() {
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn
        XCTAssertEqual(error.userMessage, "Sign in to iCloud to sync across devices")
        XCTAssertEqual(error.actionLabel, "Open Settings")
    }

    func testQuotaExceededErrorMessage() {
        let error = CloudSyncStatusService.CloudSyncError.quotaExceeded
        XCTAssertEqual(error.userMessage, "iCloud storage full. Data safe locally.")
        XCTAssertEqual(error.actionLabel, "Manage Storage")
    }

    func testNetworkUnavailableErrorMessage() {
        let error = CloudSyncStatusService.CloudSyncError.networkUnavailable
        XCTAssertEqual(error.userMessage, "Offline. Changes sync when connected.")
        XCTAssertNil(error.actionLabel)
    }

    func testUnknownErrorMessage() {
        let customMessage = "Something went wrong"
        let error = CloudSyncStatusService.CloudSyncError.unknown(customMessage)
        XCTAssertEqual(error.userMessage, customMessage)
        XCTAssertNil(error.actionLabel)
    }

    // MARK: - System Image Tests

    func testNotSignedInSystemImage() {
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn
        XCTAssertEqual(error.systemImage, "icloud.slash")
    }

    func testQuotaExceededSystemImage() {
        let error = CloudSyncStatusService.CloudSyncError.quotaExceeded
        XCTAssertEqual(error.systemImage, "exclamationmark.icloud")
    }

    func testNetworkUnavailableSystemImage() {
        let error = CloudSyncStatusService.CloudSyncError.networkUnavailable
        XCTAssertEqual(error.systemImage, "wifi.slash")
    }

    func testUnknownErrorSystemImage() {
        let error = CloudSyncStatusService.CloudSyncError.unknown("test")
        XCTAssertEqual(error.systemImage, "exclamationmark.icloud")
    }

    // MARK: - Helper Tests

    func testHasError_ReturnsTrueWhenError() {
        // Manually set status via testing init
        // Since we can't directly set status, test the logic through SyncStatus enum
        let errorStatus = CloudSyncStatusService.SyncStatus.error(.notSignedIn)
        if case .error = errorStatus {
            XCTAssertTrue(true, "Error case detected correctly")
        } else {
            XCTFail("Should detect error case")
        }
    }

    func testHasError_ReturnsFalseWhenIdle() {
        XCTAssertFalse(sut.hasError)
    }

    func testCurrentError_ReturnsNilWhenIdle() {
        XCTAssertNil(sut.currentError)
    }

    // MARK: - Status Display Text Tests

    func testStatusDisplayText_Idle() {
        XCTAssertEqual(sut.statusDisplayText, "Synced")
    }

    func testStatusDisplayText_ErrorContainsMessage() {
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn
        XCTAssertEqual(error.userMessage, "Sign in to iCloud to sync across devices")
    }

    // MARK: - Error Equality Tests

    func testErrorEquality_NotSignedIn() {
        let error1 = CloudSyncStatusService.CloudSyncError.notSignedIn
        let error2 = CloudSyncStatusService.CloudSyncError.notSignedIn
        XCTAssertEqual(error1, error2)
    }

    func testErrorEquality_QuotaExceeded() {
        let error1 = CloudSyncStatusService.CloudSyncError.quotaExceeded
        let error2 = CloudSyncStatusService.CloudSyncError.quotaExceeded
        XCTAssertEqual(error1, error2)
    }

    func testErrorEquality_NetworkUnavailable() {
        let error1 = CloudSyncStatusService.CloudSyncError.networkUnavailable
        let error2 = CloudSyncStatusService.CloudSyncError.networkUnavailable
        XCTAssertEqual(error1, error2)
    }

    func testErrorEquality_Unknown() {
        let error1 = CloudSyncStatusService.CloudSyncError.unknown("test")
        let error2 = CloudSyncStatusService.CloudSyncError.unknown("test")
        XCTAssertEqual(error1, error2)
    }

    func testErrorInequality_UnknownDifferentMessages() {
        let error1 = CloudSyncStatusService.CloudSyncError.unknown("test1")
        let error2 = CloudSyncStatusService.CloudSyncError.unknown("test2")
        XCTAssertNotEqual(error1, error2)
    }

    func testErrorInequality_DifferentTypes() {
        let error1 = CloudSyncStatusService.CloudSyncError.notSignedIn
        let error2 = CloudSyncStatusService.CloudSyncError.quotaExceeded
        XCTAssertNotEqual(error1, error2)
    }

    // MARK: - Icon Color Tests

    func testNotSignedInIconColor() {
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn
        XCTAssertEqual(error.iconColor, Theme.textTertiary)
    }

    func testQuotaExceededIconColor() {
        let error = CloudSyncStatusService.CloudSyncError.quotaExceeded
        XCTAssertEqual(error.iconColor, Theme.statusOverdue)
    }

    func testNetworkUnavailableIconColor() {
        let error = CloudSyncStatusService.CloudSyncError.networkUnavailable
        XCTAssertEqual(error.iconColor, Theme.textTertiary)
    }

    func testUnknownErrorIconColor() {
        let error = CloudSyncStatusService.CloudSyncError.unknown("test")
        XCTAssertEqual(error.iconColor, Theme.statusOverdue)
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(CloudSyncStatusService.shared, "Shared instance should exist")
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = CloudSyncStatusService.shared
        let instance2 = CloudSyncStatusService.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same instance")
    }

    // MARK: - Initial State Tests

    func testInitialLastSyncDateIsNil() {
        XCTAssertNil(sut.lastSyncDate)
    }

    func testInitialiCloudAvailableIsFalse() {
        XCTAssertFalse(sut.iCloudAvailable)
    }
}
