//
//  NotificationHelpersTests.swift
//  checkpointTests
//
//  Unit tests for NotificationHelpers trigger + pending-budget logic
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class NotificationHelpersTests: XCTestCase {

    // MARK: - Pending budget trim (finding 2)

    /// Build a request that fires at a fixed future date, so ordering by fire
    /// date is deterministic.
    private func request(id: String, daysFromNow: Int) -> UNNotificationRequest {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        return UNNotificationRequest(
            identifier: id,
            content: UNMutableNotificationContent(),
            trigger: NotificationHelpers.calendarTrigger(for: date)
        )
    }

    func testTrimKeepsSoonestDropsFurthest() {
        // Days 1...10 out; budget 6 keeps the six soonest, drops days 7-10.
        let requests = (1...10).map { request(id: "req-\($0)", daysFromNow: $0) }
        let removed = NotificationHelpers.identifiersOverBudget(in: requests.shuffled(), budget: 6)
        XCTAssertEqual(Set(removed), ["req-7", "req-8", "req-9", "req-10"])
    }

    func testTrimReturnsEmptyWhenUnderBudget() {
        let requests = (1...3).map { request(id: "req-\($0)", daysFromNow: $0) }
        XCTAssertTrue(NotificationHelpers.identifiersOverBudget(in: requests, budget: 60).isEmpty)
    }

    func testTrimSortsUndeterminableFireDatesLast() {
        // A request whose next fire date can't be computed must be dropped
        // before a dated one when over budget.
        let dated = request(id: "dated", daysFromNow: 5)
        let undated = UNNotificationRequest(
            identifier: "undated",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        let removed = NotificationHelpers.identifiersOverBudget(in: [undated, dated], budget: 1)
        XCTAssertEqual(removed, ["undated"])
    }

    // MARK: - Reminder trigger consistency (finding 6)

    private func fixedNow() -> Date {
        // 2030-06-15 14:00 — a fixed reference after the 9 AM snap.
        Calendar.current.date(from: DateComponents(year: 2030, month: 6, day: 15, hour: 14, minute: 0))!
    }

    func testReminderTriggerFutureDayUsesCalendarTrigger() {
        let now = fixedNow()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let trigger = NotificationHelpers.reminderTrigger(for: tomorrow, now: now)
        XCTAssertTrue(trigger is UNCalendarNotificationTrigger)
    }

    func testReminderTriggerSameDayAfter9AMFiresSoon() {
        // "Due today" set at 2 PM: 9 AM snap is already past but it's still
        // today, so it must fire soon rather than be dropped.
        let now = fixedNow()
        let trigger = NotificationHelpers.reminderTrigger(for: now, now: now)
        guard let interval = trigger as? UNTimeIntervalNotificationTrigger else {
            return XCTFail("Expected a fire-soon time-interval trigger, got \(String(describing: trigger))")
        }
        XCTAssertEqual(interval.timeInterval, NotificationHelpers.fireSoonInterval)
        XCTAssertFalse(interval.repeats)
    }

    func testReminderTriggerPastDayReturnsNil() {
        let now = fixedNow()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        XCTAssertNil(NotificationHelpers.reminderTrigger(for: yesterday, now: now))
    }

    func testReminderTriggerSameDayBefore9AMUsesCalendarTrigger() {
        // Before 9 AM the snapped time is still in the future today.
        let earlyNow = Calendar.current.date(from: DateComponents(year: 2030, month: 6, day: 15, hour: 7, minute: 0))!
        let trigger = NotificationHelpers.reminderTrigger(for: earlyNow, now: earlyNow)
        XCTAssertTrue(trigger is UNCalendarNotificationTrigger)
    }
}
