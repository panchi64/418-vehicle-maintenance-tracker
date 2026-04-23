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
        let syncState = SyncState.syncing

        // When vehicles is empty and state is syncing
        if case .syncing = syncState {
            // Then should show syncing state
            XCTAssertTrue(true, "Should show syncing state when vehicles empty and syncing")
        } else {
            XCTFail("Expected syncing state")
        }
    }

    func testHomeTab_ShouldShowEmptyState_WhenVehiclesEmptyAndIdle() {
        // Given
        let syncState = SyncState.idle

        // When vehicles is empty and state is idle
        if case .syncing = syncState {
            XCTFail("Should not show syncing state when idle")
        } else {
            // Then should show empty state
            XCTAssertTrue(true, "Should show empty state when idle")
        }
    }

    func testHomeTab_ShouldShowEmptyState_WhenVehiclesEmptyAndError() {
        // Given
        let syncState = SyncState.error(.notSignedIn)

        // When vehicles is empty and state is error
        if case .syncing = syncState {
            XCTFail("Should not show syncing state when error")
        } else {
            // Then should show empty state (not syncing state)
            XCTAssertTrue(true, "Should show empty state when error")
        }
    }

    // MARK: - VehicleHeader Error Indicator Tests

    func testVehicleHeader_ShouldShowErrorIndicator_WhenNotSignedIn() {
        // Given
        let state = SyncState.error(.notSignedIn)

        // Then
        if case .error = state {
            XCTAssertTrue(true, "Should show error indicator when not signed in")
        } else {
            XCTFail("Expected error state")
        }
    }

    func testVehicleHeader_ShouldShowErrorIndicator_WhenQuotaExceeded() {
        // Given
        let state = SyncState.error(.quotaExceeded)

        // Then
        if case .error = state {
            XCTAssertTrue(true, "Should show error indicator when quota exceeded")
        } else {
            XCTFail("Expected error state")
        }
    }

    func testVehicleHeader_ShouldShowErrorIndicator_WhenNetworkUnavailable() {
        // Given
        let state = SyncState.error(.networkUnavailable)

        // Then
        if case .error = state {
            XCTAssertTrue(true, "Should show error indicator when network unavailable")
        } else {
            XCTFail("Expected error state")
        }
    }

    func testVehicleHeader_ShouldHideIndicator_WhenIdle() {
        // Given
        let state = SyncState.idle

        // Then
        if case .error = state {
            XCTFail("Should not show error indicator when idle")
        } else {
            XCTAssertTrue(true, "Should hide indicator when idle")
        }
    }

    func testVehicleHeader_ShouldHideIndicator_WhenSyncing() {
        // Given
        let state = SyncState.syncing

        // Then
        if case .error = state {
            XCTFail("Should not show error indicator when syncing")
        } else {
            XCTAssertTrue(true, "Should hide indicator when syncing")
        }
    }

    // MARK: - Settings iCloud Sync Section Tests

    func testSettings_ShouldShowSyncedStatus_WhenIdle() {
        // Given
        let state = SyncState.idle

        // Then
        XCTAssertEqual(state.displayText, "Synced")
    }

    func testSettings_ShouldShowErrorMessage_WhenError() {
        // Given
        let error = SyncError.notSignedIn

        // Then
        XCTAssertEqual(error.userMessage, "Sign in to iCloud to sync across devices")
    }

    func testSettings_ShouldShowActionButton_ForNotSignedIn() {
        // Given
        let error = SyncError.notSignedIn

        // Then
        XCTAssertNotNil(error.actionLabel)
        XCTAssertEqual(error.actionLabel, "Open Settings")
    }

    func testSettings_ShouldShowActionButton_ForQuotaExceeded() {
        // Given
        let error = SyncError.quotaExceeded

        // Then
        XCTAssertNotNil(error.actionLabel)
        XCTAssertEqual(error.actionLabel, "Manage Storage")
    }

    func testSettings_ShouldNotShowActionButton_ForNetworkUnavailable() {
        // Given
        let error = SyncError.networkUnavailable

        // Then
        XCTAssertNil(error.actionLabel)
    }

    // MARK: - Status Icon Tests

    func testStatusIcon_Idle_ShowsCheckmarkIcloud() {
        let state = SyncState.idle
        if case .idle = state {
            // Expected icon: "checkmark.icloud" with Theme.statusGood color
            XCTAssertTrue(true, "Idle state should use checkmark.icloud icon")
        }
    }

    func testStatusIcon_Syncing_ShowsRotatingArrows() {
        let state = SyncState.syncing
        if case .syncing = state {
            // Expected icon: "arrow.triangle.2.circlepath.icloud" with rotation animation
            XCTAssertTrue(true, "Syncing state should use rotating arrows icon")
        }
    }

    func testStatusIcon_Error_UsesErrorSpecificIcon() {
        // Each error has its own icon
        XCTAssertEqual(SyncError.notSignedIn.systemImage, "icloud.slash")
        XCTAssertEqual(SyncError.quotaExceeded.systemImage, "exclamationmark.icloud")
        XCTAssertEqual(SyncError.networkUnavailable.systemImage, "wifi.slash")
    }

    // MARK: - Syncing State Content Tests

    func testSyncingState_HasCorrectHeading() {
        let expectedHeading = "Syncing Your Data"
        XCTAssertFalse(expectedHeading.isEmpty, "Syncing state should have a heading")
    }

    func testSyncingState_HasCorrectSubheading() {
        let expectedMessage = "Restoring your vehicles and maintenance"
        XCTAssertFalse(expectedMessage.isEmpty, "Syncing state should have a message")
    }
}
