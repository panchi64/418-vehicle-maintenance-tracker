//
//  ReminderMappingTests.swift
//  checkpointTests
//
//  The service ⇄ reminder field mapping behind the iOS 27 Reminders schema:
//  due date, recurrence, completion and the note that carries mileage. Pure
//  conversions, so they run on every OS the tests do.
//

import XCTest
import SwiftData
@testable import checkpoint

final class ReminderMappingTests: IntentTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - Due date

    func test_dueDate_roundTripsAsDayComponents() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2027, month: 2, day: 14, hour: 15)))
        let components = try XCTUnwrap(ReminderMapping.dueDateComponents(date, calendar: calendar))

        XCTAssertEqual(components.year, 2027)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 14)
        XCTAssertNil(components.hour, "A service is due on a day, not at a time")
        XCTAssertEqual(
            ReminderMapping.dueDate(from: components, calendar: calendar),
            calendar.startOfDay(for: date)
        )
    }

    func test_dueDate_withoutAYear_isTheNextSuchDay() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 25)))
        let due = ReminderMapping.dueDate(from: DateComponents(month: 3, day: 1), now: now, calendar: calendar)
        XCTAssertEqual(due, calendar.date(from: DateComponents(year: 2027, month: 3, day: 1)))
    }

    func test_dueDate_nilStaysNil() {
        XCTAssertNil(ReminderMapping.dueDateComponents(nil))
    }

    // MARK: - Recurrence

    func test_recurrence_monthsBecomeAMonthlyRule() throws {
        let rule = try XCTUnwrap(ReminderMapping.recurrence(intervalMonths: 6, calendar: calendar))
        XCTAssertEqual(rule.frequency, .monthly)
        XCTAssertEqual(rule.interval, 6)
        XCTAssertEqual(ReminderMapping.intervalMonths(from: rule), 6)
    }

    func test_recurrence_wholeYearsBecomeAYearlyRule() throws {
        let rule = try XCTUnwrap(ReminderMapping.recurrence(intervalMonths: 24, calendar: calendar))
        XCTAssertEqual(rule.frequency, .yearly)
        XCTAssertEqual(rule.interval, 2)
        XCTAssertEqual(ReminderMapping.intervalMonths(from: rule), 24)
    }

    func test_recurrence_noOrZeroInterval_isNone() {
        XCTAssertNil(ReminderMapping.recurrence(intervalMonths: nil))
        XCTAssertNil(ReminderMapping.recurrence(intervalMonths: 0))
    }

    func test_recurrence_subMonthlyCadence_hasNoServiceEquivalent() {
        let weekly = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly, interval: 2)
        let daily = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily)
        XCTAssertNil(ReminderMapping.intervalMonths(from: weekly))
        XCTAssertNil(ReminderMapping.intervalMonths(from: daily))
    }

    // MARK: - Completion

    func test_completion_isWhenTheServiceStopsCountingDown() {
        let due = addService("Oil Change", dueInDays: 10)
        XCTAssertFalse(ReminderMapping.isCompleted(due))
        XCTAssertNil(ReminderMapping.completionDate(due))

        let done = addService("Wipers", dueInDays: nil, dueMileage: nil)
        XCTAssertTrue(ReminderMapping.isCompleted(done))
        XCTAssertEqual(ReminderMapping.completionDate(done), done.lastPerformed)
    }

    // MARK: - Note

    func test_note_isNotesThenMileage_inTheUsersFormat() throws {
        let summary = try XCTUnwrap(ReminderMapping.mileageSummary(dueMileage: 50_000, intervalMiles: 5_000))
        XCTAssertEqual(summary, [
            L10n.siriReminderNoteDue(Formatters.mileage(50_000)),
            L10n.siriReminderNoteEvery(Formatters.mileage(5_000))
        ].joined(separator: "\n"))
        XCTAssertTrue(summary.contains("50,000"), "Grouped like the rest of the app, not \"50000\"")

        XCTAssertEqual(
            ReminderMapping.note(notes: "Synthetic only", mileageSummary: summary),
            "Synthetic only\n\n" + summary
        )
        XCTAssertEqual(ReminderMapping.note(notes: nil, mileageSummary: summary), summary)
        XCTAssertNil(ReminderMapping.note(notes: "  ", mileageSummary: nil))
        XCTAssertNil(ReminderMapping.mileageSummary(dueMileage: nil, intervalMiles: 0))
    }

    func test_note_writtenBack_dropsTheMileageItAppended() {
        let summary = ReminderMapping.mileageSummary(dueMileage: 50_000, intervalMiles: nil)
        let note = ReminderMapping.note(notes: "Synthetic only", mileageSummary: summary) ?? ""
        XCTAssertEqual(ReminderMapping.notes(fromReminderNote: note, mileageSummary: summary), "Synthetic only")
        XCTAssertNil(ReminderMapping.notes(fromReminderNote: summary ?? "", mileageSummary: summary))
        XCTAssertEqual(ReminderMapping.notes(fromReminderNote: "New note", mileageSummary: summary), "New note")
    }

    // MARK: - Edits

    func test_edit_appliesTitleDueDateAndRecurrence() throws {
        let service = addService("Oil Change", dueInDays: 10, intervalMonths: 6, isRecurring: true)
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2027, month: 1, day: 5)))

        let edit = ReminderMapping.edit(of: service, applying: ReminderMapping.Update(
            title: "Synthetic Oil Change",
            dueDate: ReminderMapping.dueDateComponents(target, calendar: calendar),
            recurrence: Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly)
        ))

        XCTAssertEqual(edit.name, "Synthetic Oil Change")
        XCTAssertEqual(edit.explicitDueDate, calendar.startOfDay(for: target))
        XCTAssertEqual(edit.intervalMonths, 12)
        XCTAssertTrue(edit.isRecurring)
    }

    func test_edit_recurrenceTurnsRepeatOn_andAnUnkeepableOneChangesNothing() {
        let service = addService("Detailing", dueInDays: 10, intervalMonths: nil, intervalMiles: nil, isRecurring: false)

        let monthly = ReminderMapping.edit(of: service, applying: ReminderMapping.Update(
            recurrence: Calendar.RecurrenceRule(calendar: calendar, frequency: .monthly, interval: 3)
        ))
        XCTAssertEqual(monthly.intervalMonths, 3)
        XCTAssertTrue(monthly.isRecurring)

        let weekly = ReminderMapping.edit(of: service, applying: ReminderMapping.Update(
            recurrence: Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly)
        ))
        XCTAssertEqual(weekly, service.unchangedEdit)
    }

    func test_edit_noteKeepsNotesOnly() {
        let service = addService("Oil Change", dueMileage: 50_000)
        service.notes = "Old"
        let summary = ReminderMapping.mileageSummary(dueMileage: service.dueMileage, intervalMiles: service.intervalMiles)
        let note = ReminderMapping.note(notes: "Use 0W-20", mileageSummary: summary)

        let edit = ReminderMapping.edit(of: service, applying: ReminderMapping.Update(note: note))
        XCTAssertEqual(edit.notes, "Use 0W-20")
    }
}
