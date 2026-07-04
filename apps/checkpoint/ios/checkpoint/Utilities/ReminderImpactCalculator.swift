//
//  ReminderImpactCalculator.swift
//  checkpoint
//
//  Pure projection of a service's next due date/mileage, used to preview
//  reminder scheduling changes before an edit is saved (R6). Mirrors
//  Service.deriveDueFromIntervals exactly: a positive interval projects a
//  deadline from the anchor; a nil/zero interval clears it. Explicit values
//  always win over derived ones.
//

import Foundation

nonisolated enum ReminderImpactCalculator {
    struct Schedule: Equatable {
        var dueDate: Date?
        var dueMileage: Int?
    }

    struct ReminderImpact: Equatable {
        let before: Schedule
        let after: Schedule
    }

    static func projected(
        intervalMonths: Int?,
        intervalMiles: Int?,
        anchorDate: Date,
        anchorMileage: Int,
        explicitDueDate: Date?,
        explicitDueMileage: Int?
    ) -> Schedule {
        let dueDate: Date?
        if let explicitDueDate {
            dueDate = explicitDueDate
        } else if let months = intervalMonths, months > 0 {
            dueDate = Calendar.current.date(byAdding: .month, value: months, to: anchorDate)
        } else {
            dueDate = nil
        }

        let dueMileage: Int?
        if let explicitDueMileage {
            dueMileage = explicitDueMileage
        } else if let miles = intervalMiles, miles > 0 {
            dueMileage = anchorMileage + miles
        } else {
            dueMileage = nil
        }

        return Schedule(dueDate: dueDate, dueMileage: dueMileage)
    }

    /// nil when the proposed schedule matches the current one exactly.
    static func impact(current: Schedule, proposed: Schedule) -> ReminderImpact? {
        guard current != proposed else { return nil }
        return ReminderImpact(before: current, after: proposed)
    }
}
