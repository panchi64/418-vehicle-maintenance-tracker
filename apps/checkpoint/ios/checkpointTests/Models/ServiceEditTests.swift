//
//  ServiceEditTests.swift
//  checkpointTests
//
//  Edit Service and Siri's Edit Service share one rule for what an edit does
//  to the schedule (`Service.proposedSchedule(for:)` / `apply(_:)`).
//

import XCTest
@testable import checkpoint

@MainActor
final class ServiceEditTests: XCTestCase {

    private func service(dueDate: Date? = nil, dueMileage: Int? = nil) -> Service {
        Service(
            name: "Oil Change",
            dueDate: dueDate,
            dueMileage: dueMileage,
            lastPerformed: Date(timeIntervalSince1970: 1_700_000_000),
            lastMileage: 40_000,
            intervalMonths: 6,
            intervalMiles: 5_000,
            isRecurring: true
        )
    }

    func test_unchangedEdit_changesNothing() {
        let oil = service(dueDate: Date(timeIntervalSince1970: 1_710_000_000), dueMileage: 45_000)
        let before = (oil.dueDate, oil.dueMileage, oil.intervalMonths, oil.intervalMiles, oil.isRecurring)
        oil.apply(oil.unchangedEdit)
        XCTAssertEqual(oil.dueDate, before.0)
        XCTAssertEqual(oil.dueMileage, before.1)
        XCTAssertEqual(oil.intervalMonths, before.2)
        XCTAssertEqual(oil.intervalMiles, before.3)
        XCTAssertEqual(oil.isRecurring, before.4)
    }

    func test_changedInterval_withNoExplicitDue_reprojectsFromLastCompletion() {
        let oil = service()
        var edit = oil.unchangedEdit
        edit.intervalMiles = 7_500

        XCTAssertEqual(oil.proposedSchedule(for: edit).dueMileage, 47_500)
        XCTAssertNil(oil.proposedSchedule(for: edit).dueDate, "The unchanged month interval doesn't re-derive")
    }

    func test_repeatOff_dropsTheCadence() {
        let oil = service(dueMileage: 45_000)
        var edit = oil.unchangedEdit
        edit.isRecurring = false
        oil.apply(edit)

        XCTAssertNil(oil.intervalMonths)
        XCTAssertNil(oil.intervalMiles)
        XCTAssertFalse(oil.isRecurring)
        XCTAssertEqual(oil.dueMileage, 45_000, "The explicit target stays")
    }
}
