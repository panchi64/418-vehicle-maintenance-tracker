//
//  Service+StopTracking.swift
//  checkpoint
//
//  Dismissing a schedule without pretending it was done.
//
//  A service the user skipped used to have one way off the list: Mark Done,
//  which fabricated a log entry — a service that never happened, with a date,
//  an odometer reading and a place in the cost history. So a returning lapsed
//  user faced permanent red rows or a false record (SURFACE_DOCTRINE.md,
//  "Known open items").
//
//  No new stored flag: a service without due tracking is already what the app
//  calls log-only — it has no status, drops out of the status groups, and
//  fires no reminders — while its history stays. Stopping tracking moves a
//  service into that state. The interval policy is kept, so editing the
//  service later can re-arm it from the same values.
//

import Foundation

extension Service {

    /// What `stopTracking()` cleared, for Undo.
    struct TrackingSnapshot: Equatable {
        let dueDate: Date?
        let dueMileage: Int?
        let isRecurring: Bool
    }

    /// Clears the schedule and returns what it was. Writes no log.
    @discardableResult
    func stopTracking() -> TrackingSnapshot {
        let snapshot = TrackingSnapshot(dueDate: dueDate, dueMileage: dueMileage, isRecurring: isRecurring)
        dueDate = nil
        dueMileage = nil
        isRecurring = false
        return snapshot
    }

    func restoreTracking(_ snapshot: TrackingSnapshot) {
        dueDate = snapshot.dueDate
        dueMileage = snapshot.dueMileage
        isRecurring = snapshot.isRecurring
    }
}
