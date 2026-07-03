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
        ServiceNotificationScheduler.cancelNotification(for: service)

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

        ServiceNotificationScheduler.scheduleNotification(for: next, vehicle: vehicle)

        return next
    }
}
