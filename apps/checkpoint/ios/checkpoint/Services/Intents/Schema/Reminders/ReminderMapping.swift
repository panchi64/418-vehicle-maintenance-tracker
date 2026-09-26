//
//  ReminderMapping.swift
//  checkpoint
//
//  How a tracked service reads as a reminder in the iOS 27 Reminders schema,
//  and how a reminder's fields come back as a service edit. Pure conversions,
//  kept apart from the schema types so they run (and are tested) on iOS 26.
//
//    dueDate        ⇄ Service.dueDate, as year/month/day components
//    recurrence     ⇄ Service.intervalMonths (monthly, or yearly for whole years)
//    isCompleted    ⇐ no longer counting down (`!hasDueTracking`)
//    completionDate ⇐ Service.lastPerformed, once completed
//    note           ⇄ Service.notes, followed by the due and interval mileage,
//                     which have no schema field of their own
//

import Foundation

@MainActor
enum ReminderMapping {

    // MARK: - Due date

    static func dueDateComponents(_ date: Date?, calendar: Calendar = .current) -> DateComponents? {
        date.map { calendar.dateComponents([.year, .month, .day], from: $0) }
    }

    /// The day `components` names. Without a year it is the next such day.
    static func dueDate(from components: DateComponents, now: Date = .now, calendar: Calendar = .current) -> Date? {
        if components.year != nil {
            return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
        }
        return calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTime
        )
    }

    // MARK: - Recurrence

    /// A month cadence as a recurrence rule: yearly when it is whole years,
    /// so Reminders says "every year", monthly otherwise.
    static func recurrence(intervalMonths: Int?, calendar: Calendar = .current) -> Calendar.RecurrenceRule? {
        guard let months = intervalMonths, months > 0 else { return nil }
        if months.isMultiple(of: 12) {
            return Calendar.RecurrenceRule(calendar: calendar, frequency: .yearly, interval: months / 12)
        }
        return Calendar.RecurrenceRule(calendar: calendar, frequency: .monthly, interval: months)
    }

    /// The month cadence a rule describes, or nil for one Checkpoint can't
    /// keep: a service interval is whole months, so daily and weekly
    /// cadences have no faithful equivalent.
    static func intervalMonths(from rule: Calendar.RecurrenceRule) -> Int? {
        let interval = max(rule.interval, 1)
        switch rule.frequency {
        case .monthly: return interval
        case .yearly: return interval * 12
        default: return nil
        }
    }

    // MARK: - Completion

    /// A service is done once it stops counting down: completing a
    /// non-recurring service clears its due, and a recurring one hands its
    /// due to the successor it schedules.
    static func isCompleted(_ service: Service) -> Bool {
        !service.hasDueTracking
    }

    static func completionDate(_ service: Service) -> Date? {
        isCompleted(service) ? service.lastPerformed : nil
    }

    // MARK: - Note

    /// The mileage lines a reminder's note ends with: "Due at 50,000 mi",
    /// "Every 5,000 mi". nil when the service has neither.
    static func mileageSummary(dueMileage: Int?, intervalMiles: Int?) -> String? {
        let lines = [
            dueMileage.map { L10n.siriReminderNoteDue(SpokenValue.mileage($0)) },
            intervalMiles.flatMap { $0 > 0 ? L10n.siriReminderNoteEvery(SpokenValue.mileage($0)) : nil }
        ].compactMap { $0 }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    /// The service's notes, then its mileage summary.
    static func note(notes: String?, mileageSummary: String?) -> String? {
        let parts = [notes?.trimmingCharacters(in: .whitespacesAndNewlines), mileageSummary]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }

    /// The notes a reminder note stands for: the mileage summary this app
    /// appended is dropped, so writing a note back never stores it twice.
    static func notes(fromReminderNote note: String, mileageSummary: String?) -> String? {
        var text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let mileageSummary, text.hasSuffix(mileageSummary) {
            text = String(text.dropLast(mileageSummary.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text.isEmpty ? nil : text
    }

    // MARK: - Edits

    /// What an update said, in Checkpoint's terms. Only the fields a service
    /// has; flags, tags, URLs and location triggers are not kept.
    struct Update {
        var title: String?
        var note: String?
        var dueDate: DateComponents?
        var recurrence: Calendar.RecurrenceRule?
    }

    /// `service` with `update` applied. A recurrence turns Repeat on, as
    /// typing an interval in the form does; one Checkpoint can't keep
    /// (daily, weekly) leaves the cadence as it was.
    static func edit(of service: Service, applying update: Update, now: Date = .now) -> ServiceEdit {
        var edit = service.unchangedEdit
        if let title = update.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            edit.name = title
        }
        if let note = update.note {
            let summary = mileageSummary(dueMileage: service.dueMileage, intervalMiles: service.intervalMiles)
            edit.notes = notes(fromReminderNote: note, mileageSummary: summary)
        }
        if let components = update.dueDate, let date = dueDate(from: components, now: now) {
            edit.explicitDueDate = date
        }
        if let rule = update.recurrence, let months = intervalMonths(from: rule) {
            edit.intervalMonths = months
            edit.isRecurring = true
        }
        return edit
    }
}
