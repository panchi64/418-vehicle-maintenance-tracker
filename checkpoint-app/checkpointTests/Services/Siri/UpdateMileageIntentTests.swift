//
//  UpdateMileageIntentTests.swift
//  checkpointTests
//
//  Tests for UpdateMileageIntent and PendingMileageUpdate
//

import XCTest
@testable import checkpoint

@MainActor
final class UpdateMileageIntentTests: XCTestCase {

    override func tearDown() {
        // Clean up pending update
        PendingMileageUpdate.shared.clear()
        super.tearDown()
    }

    // MARK: - PendingMileageUpdate Tests

    func test_pendingMileageUpdate_isInitiallyEmpty() {
        // Given a fresh state
        PendingMileageUpdate.shared.clear()

        // Then
        XCTAssertNil(PendingMileageUpdate.shared.vehicleID)
        XCTAssertNil(PendingMileageUpdate.shared.mileage)
        XCTAssertFalse(PendingMileageUpdate.shared.hasPendingUpdate)
    }

    func test_pendingMileageUpdate_storesValues() {
        // Given
        let vehicleID = "test-vehicle-123"
        let mileage = 52000

        // When
        PendingMileageUpdate.shared.vehicleID = vehicleID
        PendingMileageUpdate.shared.mileage = mileage

        // Then
        XCTAssertEqual(PendingMileageUpdate.shared.vehicleID, vehicleID)
        XCTAssertEqual(PendingMileageUpdate.shared.mileage, mileage)
        XCTAssertTrue(PendingMileageUpdate.shared.hasPendingUpdate)
    }

    func test_pendingMileageUpdate_hasPendingUpdate_requiresBothValues() {
        // Given only vehicle ID
        PendingMileageUpdate.shared.vehicleID = "test"
        PendingMileageUpdate.shared.mileage = nil

        // Then
        XCTAssertFalse(PendingMileageUpdate.shared.hasPendingUpdate)

        // Given only mileage
        PendingMileageUpdate.shared.vehicleID = nil
        PendingMileageUpdate.shared.mileage = 50000

        // Then
        XCTAssertFalse(PendingMileageUpdate.shared.hasPendingUpdate)
    }

    func test_pendingMileageUpdate_clear_removesValues() {
        // Given stored values
        PendingMileageUpdate.shared.vehicleID = "test"
        PendingMileageUpdate.shared.mileage = 50000

        // When
        PendingMileageUpdate.shared.clear()

        // Then
        XCTAssertNil(PendingMileageUpdate.shared.vehicleID)
        XCTAssertNil(PendingMileageUpdate.shared.mileage)
        XCTAssertFalse(PendingMileageUpdate.shared.hasPendingUpdate)
    }

    // MARK: - Intent Creation Tests

    func test_updateMileageIntent_hasCorrectTitle() {
        let title = UpdateMileageIntent.title
        XCTAssertNotNil(title)
    }

    func test_updateMileageIntent_opensAppWhenRun() {
        XCTAssertTrue(UpdateMileageIntent.openAppWhenRun)
    }
}
