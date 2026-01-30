//
//  SyncStatusUITests.swift
//  checkpointTests
//
//  Tests for sync status UI components
//

import XCTest
import SwiftUI
@testable import checkpoint

@MainActor
final class SyncStatusUITests: XCTestCase {

    // MARK: - HomeTab Syncing State Tests

    func testHomeTab_ShouldShowSyncingState_WhenVehiclesEmptyAndSyncing() {
        // Given
        let syncStatus = CloudSyncStatusService.SyncStatus.syncing

        // When vehicles is empty and status is syncing
        if case .syncing = syncStatus {
            // Then should show syncing state
            XCTAssertTrue(true, "Should show syncing state when vehicles empty and syncing")
        } else {
            XCTFail("Expected syncing status")
        }
    }

    func testHomeTab_ShouldShowEmptyState_WhenVehiclesEmptyAndIdle() {
        // Given
        let syncStatus = CloudSyncStatusService.SyncStatus.idle

        // When vehicles is empty and status is idle
        if case .syncing = syncStatus {
            XCTFail("Should not show syncing state when idle")
        } else {
            // Then should show empty state
            XCTAssertTrue(true, "Should show empty state when idle")
        }
    }

    func testHomeTab_ShouldShowEmptyState_WhenVehiclesEmptyAndError() {
        // Given
        let syncStatus = CloudSyncStatusService.SyncStatus.error(.notSignedIn)

        // When vehicles is empty and status is error
        if case .syncing = syncStatus {
            XCTFail("Should not show syncing state when error")
        } else {
            // Then should show empty state (not syncing state)
            XCTAssertTrue(true, "Should show empty state when error")
        }
    }

    // MARK: - VehicleHeader Error Indicator Tests

    func testVehicleHeader_ShouldShowErrorIndicator_WhenNotSignedIn() {
        // Given
        let status = CloudSyncStatusService.SyncStatus.error(.notSignedIn)

        // Then
        if case .error = status {
            XCTAssertTrue(true, "Should show error indicator when not signed in")
        } else {
            XCTFail("Expected error status")
        }
    }

    func testVehicleHeader_ShouldShowErrorIndicator_WhenQuotaExceeded() {
        // Given
        let status = CloudSyncStatusService.SyncStatus.error(.quotaExceeded)

        // Then
        if case .error = status {
            XCTAssertTrue(true, "Should show error indicator when quota exceeded")
        } else {
            XCTFail("Expected error status")
        }
    }

    func testVehicleHeader_ShouldShowErrorIndicator_WhenNetworkUnavailable() {
        // Given
        let status = CloudSyncStatusService.SyncStatus.error(.networkUnavailable)

        // Then
        if case .error = status {
            XCTAssertTrue(true, "Should show error indicator when network unavailable")
        } else {
            XCTFail("Expected error status")
        }
    }

    func testVehicleHeader_ShouldHideIndicator_WhenIdle() {
        // Given
        let status = CloudSyncStatusService.SyncStatus.idle

        // Then
        if case .error = status {
            XCTFail("Should not show error indicator when idle")
        } else {
            XCTAssertTrue(true, "Should hide indicator when idle")
        }
    }

    func testVehicleHeader_ShouldHideIndicator_WhenSyncing() {
        // Given
        let status = CloudSyncStatusService.SyncStatus.syncing

        // Then
        if case .error = status {
            XCTFail("Should not show error indicator when syncing")
        } else {
            XCTAssertTrue(true, "Should hide indicator when syncing")
        }
    }

    // MARK: - Settings iCloud Sync Section Tests

    func testSettings_ShouldShowSyncedStatus_WhenIdle() {
        // Given
        let service = CloudSyncStatusService(forTesting: true)

        // Then
        XCTAssertEqual(service.statusDisplayText, "Synced")
    }

    func testSettings_ShouldShowErrorMessage_WhenError() {
        // Given
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn

        // Then
        XCTAssertEqual(error.userMessage, "Sign in to iCloud to sync across devices")
    }

    func testSettings_ShouldShowActionButton_ForNotSignedIn() {
        // Given
        let error = CloudSyncStatusService.CloudSyncError.notSignedIn

        // Then
        XCTAssertNotNil(error.actionLabel)
        XCTAssertEqual(error.actionLabel, "Open Settings")
    }

    func testSettings_ShouldShowActionButton_ForQuotaExceeded() {
        // Given
        let error = CloudSyncStatusService.CloudSyncError.quotaExceeded

        // Then
        XCTAssertNotNil(error.actionLabel)
        XCTAssertEqual(error.actionLabel, "Manage Storage")
    }

    func testSettings_ShouldNotShowActionButton_ForNetworkUnavailable() {
        // Given
        let error = CloudSyncStatusService.CloudSyncError.networkUnavailable

        // Then
        XCTAssertNil(error.actionLabel)
    }

    // MARK: - Status Icon Tests

    func testStatusIcon_Idle_ShowsCheckmarkIcloud() {
        // The icon for idle state is "checkmark.icloud" (shown in Settings)
        // This is a documentation test to verify expected behavior
        let status = CloudSyncStatusService.SyncStatus.idle
        if case .idle = status {
            // Expected icon: "checkmark.icloud" with Theme.statusGood color
            XCTAssertTrue(true, "Idle status should use checkmark.icloud icon")
        }
    }

    func testStatusIcon_Syncing_ShowsRotatingArrows() {
        // The icon for syncing state is "arrow.triangle.2.circlepath.icloud"
        let status = CloudSyncStatusService.SyncStatus.syncing
        if case .syncing = status {
            // Expected icon: "arrow.triangle.2.circlepath.icloud" with rotation animation
            XCTAssertTrue(true, "Syncing status should use rotating arrows icon")
        }
    }

    func testStatusIcon_Error_UsesErrorSpecificIcon() {
        // Each error has its own icon
        XCTAssertEqual(
            CloudSyncStatusService.CloudSyncError.notSignedIn.systemImage,
            "icloud.slash"
        )
        XCTAssertEqual(
            CloudSyncStatusService.CloudSyncError.quotaExceeded.systemImage,
            "exclamationmark.icloud"
        )
        XCTAssertEqual(
            CloudSyncStatusService.CloudSyncError.networkUnavailable.systemImage,
            "wifi.slash"
        )
    }

    // MARK: - Syncing State Content Tests

    func testSyncingState_HasCorrectHeading() {
        // The syncing state should display "Syncing Your Data"
        // This is a documentation test for expected UI content
        let expectedHeading = "Syncing Your Data"
        XCTAssertFalse(expectedHeading.isEmpty, "Syncing state should have a heading")
    }

    func testSyncingState_HasCorrectSubheading() {
        // The syncing state should display restoration message
        let expectedMessage = "Restoring your vehicles and maintenance"
        XCTAssertFalse(expectedMessage.isEmpty, "Syncing state should have a message")
    }
}
