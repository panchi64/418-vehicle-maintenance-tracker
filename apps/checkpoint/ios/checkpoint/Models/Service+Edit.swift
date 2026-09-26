//
//  Service+Edit.swift
//  checkpoint
//
//  Editing a tracked service's name, schedule and cadence. Shared by Edit
//  Service and `EditServiceIntent`, so a spoken "change the oil change to
//  every 6 months" moves the schedule exactly as the form would.
//

import Foundation

/// A service as an edit leaves it.
struct ServiceEdit: Equatable {
    var name: String
    /// A due date the user set. Wins over any interval.
    var explicitDueDate: Date?
    /// A due mileage the user set. Wins over any interval.
    var explicitDueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var isRecurring: Bool
    var notes: String?

    /// The cadence as it takes effect: none without Repeat.
    var effectiveIntervalMonths: Int? { isRecurring ? intervalMonths : nil }
    var effectiveIntervalMiles: Int? { isRecurring ? intervalMiles : nil }
}

extension Service {

    /// The edit that changes nothing — the starting point for one.
    var unchangedEdit: ServiceEdit {
        ServiceEdit(
            name: name,
            explicitDueDate: dueDate,
            explicitDueMileage: dueMileage,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            isRecurring: isRecurring,
            notes: notes
        )
    }

    /// The schedule `edit` would leave.
    ///
    /// Explicit values always win; an interval is only allowed to re-derive a
    /// due when the edit actually changed that interval AND the service has a
    /// real completion anchor. Never fabricates an anchor from `.now` —
    /// otherwise a notes-only save would silently shift the schedule, and
    /// clearing a due date/mileage would be impossible on a recurring service
    /// (the interval would immediately re-populate it).
    func proposedSchedule(for edit: ServiceEdit) -> ReminderImpactCalculator.Schedule {
        let monthsChanged = edit.effectiveIntervalMonths != intervalMonths
        let milesChanged = edit.effectiveIntervalMiles != intervalMiles
        return ReminderImpactCalculator.projected(
            intervalMonths: (monthsChanged && lastPerformed != nil) ? edit.effectiveIntervalMonths : nil,
            intervalMiles: (milesChanged && lastMileage != nil) ? edit.effectiveIntervalMiles : nil,
            anchorDate: lastPerformed ?? .distantPast,
            anchorMileage: lastMileage ?? 0,
            explicitDueDate: edit.explicitDueDate,
            explicitDueMileage: edit.explicitDueMileage
        )
    }

    /// Apply `edit`. Model mutation only; callers rebuild reminders and
    /// refresh the icon and widget.
    func apply(_ edit: ServiceEdit) {
        let schedule = proposedSchedule(for: edit)
        name = edit.name
        dueDate = schedule.dueDate
        dueMileage = schedule.dueMileage
        intervalMonths = edit.effectiveIntervalMonths
        intervalMiles = edit.effectiveIntervalMiles
        isRecurring = edit.isRecurring && Service.hasIntervalPolicy(
            intervalMonths: edit.intervalMonths,
            intervalMiles: edit.intervalMiles
        )
        notes = edit.notes
    }
}
