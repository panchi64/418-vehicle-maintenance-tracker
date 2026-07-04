//
//  EditServiceViewRescheduleTests.swift
//  checkpointTests
//
//  Tests for the notification-ID bookkeeping EditServiceView's save flow
//  relies on when it cancels then reschedules a service's notifications
//  (fixes the audit finding that edits left stale pending notifications).
//  The test host has no notification authorization, so these only exercise
//  pure ID derivation — never live UNUserNotificationCenter state.
//

import XCTest
@testable import checkpoint

final class EditServiceViewRescheduleTests: XCTestCase {

    func testBaseNotificationID_IsDeterministicForSameService() {
        let service = Service(name: "Oil Change", dueDate: .now)

        let first = ServiceNotificationScheduler.baseNotificationID(for: service)
        let second = ServiceNotificationScheduler.baseNotificationID(for: service)

        XCTAssertEqual(first, second)
    }

    func testBaseNotificationID_SurvivesFieldEdits() {
        // Editing name/due date/interval must not change the notification ID —
        // otherwise a reschedule after an edit would orphan the old pending set.
        let service = Service(name: "Oil Change", dueDate: .now, intervalMonths: 6)
        let idBeforeEdit = ServiceNotificationScheduler.baseNotificationID(for: service)

        service.name = "Synthetic Oil Change"
        service.dueDate = Calendar.current.date(byAdding: .month, value: 3, to: .now)
        service.intervalMonths = 12

        let idAfterEdit = ServiceNotificationScheduler.baseNotificationID(for: service)

        XCTAssertEqual(idBeforeEdit, idAfterEdit, "Notification ID is derived from service.id, not its editable fields")
    }

    func testBaseNotificationID_DiffersAcrossServices() {
        let serviceA = Service(name: "Oil Change", dueDate: .now)
        let serviceB = Service(name: "Tire Rotation", dueDate: .now)

        XCTAssertNotEqual(
            ServiceNotificationScheduler.baseNotificationID(for: serviceA),
            ServiceNotificationScheduler.baseNotificationID(for: serviceB)
        )
    }

    func testBaseNotificationID_MatchesDerivationFromServiceID() {
        let service = Service(name: "Oil Change", dueDate: .now)

        XCTAssertEqual(
            ServiceNotificationScheduler.baseNotificationID(for: service),
            ServiceNotificationScheduler.baseNotificationID(forServiceID: service.id)
        )
    }

    func testSnoozeNotificationID_DerivesFromBaseID() {
        let baseID = ServiceNotificationScheduler.baseNotificationID(forServiceID: UUID())
        let snoozeID = ServiceNotificationScheduler.snoozeNotificationID(baseID: baseID)

        XCTAssertTrue(snoozeID.hasPrefix(baseID))
        XCTAssertNotEqual(snoozeID, baseID)
    }
}
