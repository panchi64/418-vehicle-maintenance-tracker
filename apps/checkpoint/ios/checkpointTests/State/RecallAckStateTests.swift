//
//  RecallAckStateTests.swift
//  checkpointTests
//
//  Coverage for RecallAckStore mutations + RecallVisibility filtering.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class RecallAckStateTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var store: RecallAckStore!
    let vehicleID = UUID()

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: RecallAcknowledgment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        store = RecallAckStore(context: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        store = nil
        super.tearDown()
    }

    private func makeRecall(_ campaignNumber: String, parkIt: Bool = false) -> RecallInfo {
        RecallInfo(
            campaignNumber: campaignNumber,
            component: "TEST",
            summary: "",
            consequence: "",
            remedy: "",
            reportDate: "",
            parkIt: parkIt,
            parkOutside: false
        )
    }

    // MARK: - setStatus

    func test_setStatus_createsAckOnFirstCall() {
        store.setStatus(.scheduled, vehicleID: vehicleID, campaignNumber: "X1")
        let acks = store.acknowledgments(for: vehicleID)
        XCTAssertEqual(acks["X1"]?.status, .scheduled)
    }

    func test_setStatus_updatesExistingAck() {
        store.setStatus(.scheduled, vehicleID: vehicleID, campaignNumber: "X1")
        store.setStatus(.resolved, vehicleID: vehicleID, campaignNumber: "X1")
        store.setStatus(.open, vehicleID: vehicleID, campaignNumber: "X1")
        let acks = store.acknowledgments(for: vehicleID)
        XCTAssertEqual(acks.count, 1)
        XCTAssertEqual(acks["X1"]?.status, .open)
    }

    func test_setStatus_clearsActiveSnooze() {
        store.snooze([makeRecall("X1")], days: 7, vehicleID: vehicleID)
        XCTAssertNotNil(store.acknowledgments(for: vehicleID)["X1"]?.snoozedUntil)
        store.setStatus(.scheduled, vehicleID: vehicleID, campaignNumber: "X1")
        XCTAssertNil(store.acknowledgments(for: vehicleID)["X1"]?.snoozedUntil)
    }

    // MARK: - snooze

    func test_snooze_setsExpirationOnAllNonParkItRecalls() {
        let recalls = [makeRecall("X1"), makeRecall("X2")]
        let count = store.snooze(recalls, days: 7, vehicleID: vehicleID)
        XCTAssertEqual(count, 2)
        let acks = store.acknowledgments(for: vehicleID)
        XCTAssertNotNil(acks["X1"]?.snoozedUntil)
        XCTAssertNotNil(acks["X2"]?.snoozedUntil)
    }

    func test_snooze_refusesWhenAnyParkIt() {
        let recalls = [makeRecall("X1"), makeRecall("X2", parkIt: true)]
        let count = store.snooze(recalls, days: 7, vehicleID: vehicleID)
        XCTAssertEqual(count, 0)
        XCTAssertTrue(store.acknowledgments(for: vehicleID).isEmpty)
    }

    // MARK: - clearExpiredSnoozes

    func test_clearExpiredSnoozes_dropsPastExpirations() {
        store.setStatus(.open, vehicleID: vehicleID, campaignNumber: "X1")
        let acks = store.acknowledgments(for: vehicleID)
        acks["X1"]?.snoozedUntil = Date.now.addingTimeInterval(-3600)
        try? modelContext.save()

        store.clearExpiredSnoozes(for: vehicleID)
        XCTAssertNil(store.acknowledgments(for: vehicleID)["X1"]?.snoozedUntil)
    }

    func test_clearExpiredSnoozes_preservesActiveSnoozes() {
        store.snooze([makeRecall("X1")], days: 7, vehicleID: vehicleID)
        store.clearExpiredSnoozes(for: vehicleID)
        XCTAssertNotNil(store.acknowledgments(for: vehicleID)["X1"]?.snoozedUntil)
    }

    // MARK: - RecallVisibility

    func test_visibility_resolved_isHidden() {
        store.setStatus(.resolved, vehicleID: vehicleID, campaignNumber: "X1")
        let visible = RecallVisibility.visibleRecalls(
            from: [makeRecall("X1"), makeRecall("X2")],
            acknowledgments: store.acknowledgments(for: vehicleID)
        )
        XCTAssertEqual(visible.map(\.campaignNumber), ["X2"])
    }

    func test_visibility_activeSnooze_isHidden() {
        store.snooze([makeRecall("X1")], days: 7, vehicleID: vehicleID)
        let visible = RecallVisibility.visibleRecalls(
            from: [makeRecall("X1"), makeRecall("X2")],
            acknowledgments: store.acknowledgments(for: vehicleID)
        )
        XCTAssertEqual(visible.map(\.campaignNumber), ["X2"])
    }

    func test_visibility_expiredSnooze_reappears() {
        store.snooze([makeRecall("X1")], days: 7, vehicleID: vehicleID)
        let acks = store.acknowledgments(for: vehicleID)
        acks["X1"]?.snoozedUntil = Date.now.addingTimeInterval(-60)
        try? modelContext.save()

        let visible = RecallVisibility.visibleRecalls(
            from: [makeRecall("X1")],
            acknowledgments: store.acknowledgments(for: vehicleID)
        )
        XCTAssertEqual(visible.map(\.campaignNumber), ["X1"])
    }

    func test_visibility_parkIt_alwaysVisible_evenWhenResolved() {
        store.setStatus(.resolved, vehicleID: vehicleID, campaignNumber: "X1")
        let visible = RecallVisibility.visibleRecalls(
            from: [makeRecall("X1", parkIt: true)],
            acknowledgments: store.acknowledgments(for: vehicleID)
        )
        XCTAssertEqual(visible.map(\.campaignNumber), ["X1"])
    }

    func test_visibility_noAck_isVisible() {
        let visible = RecallVisibility.visibleRecalls(
            from: [makeRecall("X1")],
            acknowledgments: [:]
        )
        XCTAssertEqual(visible.map(\.campaignNumber), ["X1"])
    }
}
