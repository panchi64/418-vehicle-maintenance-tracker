//
//  WatchSessionServiceTests.swift
//  checkpointTests
//
//  Tests for the phone-side Watch mark-done duplicate-delivery guard (finding #5).
//

import XCTest
@testable import checkpoint

final class WatchMarkDoneDedupTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: WatchMarkDoneDedup.key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: WatchMarkDoneDedup.key)
        super.tearDown()
    }

    func test_unseenID_isNotDuplicate() {
        XCTAssertFalse(WatchMarkDoneDedup.isDuplicate(UUID()))
    }

    func test_recordedID_isReportedDuplicate() {
        let id = UUID()
        XCTAssertFalse(WatchMarkDoneDedup.isDuplicate(id))
        WatchMarkDoneDedup.record(id)
        XCTAssertTrue(WatchMarkDoneDedup.isDuplicate(id),
                      "A re-delivered tap must be recognized as a duplicate")
    }

    func test_distinctIDs_areIndependent() {
        let first = UUID()
        let second = UUID()
        WatchMarkDoneDedup.record(first)
        XCTAssertTrue(WatchMarkDoneDedup.isDuplicate(first))
        XCTAssertFalse(WatchMarkDoneDedup.isDuplicate(second),
                       "A different tap must not be mistaken for a duplicate")
    }

    func test_recordingSameIDTwice_doesNotDuplicateEntry() {
        let id = UUID()
        WatchMarkDoneDedup.record(id)
        WatchMarkDoneDedup.record(id)
        let stored = UserDefaults.standard.stringArray(forKey: WatchMarkDoneDedup.key) ?? []
        XCTAssertEqual(stored.filter { $0 == id.uuidString }.count, 1)
    }

    /// The ring is bounded: after many taps, the oldest ids age out but recent
    /// ones (the only ones a duplicate could still race against) stay covered.
    func test_ringEvictsOldestBeyondCapacity() {
        let ids = (0..<40).map { _ in UUID() }
        ids.forEach { WatchMarkDoneDedup.record($0) }

        XCTAssertTrue(WatchMarkDoneDedup.isDuplicate(ids.last!),
                      "Most recent tap must remain covered")
        XCTAssertFalse(WatchMarkDoneDedup.isDuplicate(ids.first!),
                       "Oldest tap should have aged out of the bounded ring")
    }
}
