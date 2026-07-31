//
//  ServiceCompletionService.swift
//  checkpoint
//
//  Shared chain-spawn logic for completing a scheduled service.
//  One occurrence completes (becomes a closed record); if the service was
//  marked recurring, the next occurrence is spawned with dates derived from
//  the actual completion date/mileage. Used by all completion entry points
//  (in-app Mark Done, widget, watch) so behavior stays consistent.
//

import Foundation
import SwiftData

struct ServiceCompletionService {

    /// Close `service` and, if it was recurring, spawn the next occurrence.
    /// Caller is responsible for inserting the `ServiceLog` so origin-specific
    /// wiring (`ServiceVisit`, attachments) stays at the call site.
    ///
    /// - Returns: the spawned successor `Service`, or `nil` if no successor was created.
    @MainActor
    @discardableResult
    static func completeService(
        _ service: Service,
        performedDate: Date,
        mileage: Int,
        in context: ModelContext
    ) -> Service? {
        let wasRecurring = service.isRecurring
        let hasPolicy = service.hasIntervalPolicy
        let name = service.name
        let intervalMonths = service.intervalMonths
        let intervalMiles = service.intervalMiles
        let notes = service.notes
        let vehicle = service.vehicle

        service.lastPerformed = performedDate
        service.lastMileage = mileage
        service.dueDate = nil
        service.dueMileage = nil
        service.intervalMonths = nil
        service.intervalMiles = nil

        guard wasRecurring, hasPolicy, let vehicle else {
            // Still rebuild: clearing the due date above means the completed
            // service must drop out of its bundles. The old code cancelled the
            // service's own requests up front instead, which left this path
            // — a non-recurring completion — with nothing to remove them from
            // the pending set until the next launch sweep.
            if let vehicle = service.vehicle {
                ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
            }
            return nil
        }

        let next = Service(
            name: name,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            notes: notes,
            isRecurring: true
        )
        next.vehicle = vehicle
        next.deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
        context.insert(next)

        // Reschedule the vehicle, not just `next`: reminders are bundled per
        // day, so the completed service has to leave its bundle in the same
        // pass that the follow-up occurrence joins one.
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)

        return next
    }
}
