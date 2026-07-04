//
//  ServiceFormDraftStoreTests.swift
//  checkpointTests
//
//  Tests for the Add Service draft persistence (R9): round-trip, expiry,
//  and manual clearing.
//

import XCTest
@testable import checkpoint

final class ServiceFormDraftStoreTests: XCTestCase {

    private func makeDraft(savedAt: Date = .now) -> ServiceFormDraft {
        ServiceFormDraft(
            mode: "record",
            serviceName: "Oil Change",
            presetName: "oil_change",
            performedDate: .now,
            costText: "48",
            costCategoryRaw: "maintenance",
            mileageText: "32500",
            recordNotes: "Synthetic 0W-20",
            remindNotes: "",
            dueDate: nil,
            hasCustomDate: false,
            dueMileage: nil,
            intervalMonths: 6,
            intervalMiles: 5000,
            isRecurring: true,
            savedAt: savedAt
        )
    }

    override func tearDown() {
        ServiceFormDraftStore.clear(for: UUID())
        super.tearDown()
    }

    func testRoundTrip_SavesAndLoadsIdenticalDraft() {
        let vehicleID = UUID()
        let draft = makeDraft()
        ServiceFormDraftStore.save(draft, for: vehicleID)

        XCTAssertEqual(ServiceFormDraftStore.load(for: vehicleID), draft)

        ServiceFormDraftStore.clear(for: vehicleID)
    }

    func testLoad_ReturnsNilWhenNoDraftStored() {
        XCTAssertNil(ServiceFormDraftStore.load(for: UUID()))
    }

    func testLoad_ReturnsNilAndClearsExpiredDraft() {
        let vehicleID = UUID()
        let eightDaysAgo = Date.now.addingTimeInterval(-8 * 24 * 60 * 60)
        ServiceFormDraftStore.save(makeDraft(savedAt: eightDaysAgo), for: vehicleID)

        XCTAssertNil(ServiceFormDraftStore.load(for: vehicleID))
        // Expiry clears as a side effect — a second load should still be nil.
        XCTAssertNil(ServiceFormDraftStore.load(for: vehicleID))
    }

    func testLoad_ReturnsDraftJustUnderExpiryThreshold() {
        let vehicleID = UUID()
        let almostSevenDaysAgo = Date.now.addingTimeInterval(-(7 * 24 * 60 * 60 - 60))
        let draft = makeDraft(savedAt: almostSevenDaysAgo)
        ServiceFormDraftStore.save(draft, for: vehicleID)

        XCTAssertEqual(ServiceFormDraftStore.load(for: vehicleID), draft)

        ServiceFormDraftStore.clear(for: vehicleID)
    }

    func testClear_RemovesStoredDraft() {
        let vehicleID = UUID()
        ServiceFormDraftStore.save(makeDraft(), for: vehicleID)
        ServiceFormDraftStore.clear(for: vehicleID)

        XCTAssertNil(ServiceFormDraftStore.load(for: vehicleID))
    }

    func testDrafts_AreIsolatedPerVehicle() {
        let vehicleA = UUID()
        let vehicleB = UUID()
        ServiceFormDraftStore.save(makeDraft(), for: vehicleA)

        XCTAssertNotNil(ServiceFormDraftStore.load(for: vehicleA))
        XCTAssertNil(ServiceFormDraftStore.load(for: vehicleB))

        ServiceFormDraftStore.clear(for: vehicleA)
    }
}
