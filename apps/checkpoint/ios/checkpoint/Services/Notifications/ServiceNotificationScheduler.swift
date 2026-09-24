//
//  ServiceNotificationScheduler.swift
//  checkpoint
//
//  Schedules and cancels service due notifications.
//
//  The pending set is **vehicle-scoped, not service-scoped**. Reminders that
//  land on the same morning at the same lead time are delivered as one
//  notification listing every service involved — see `ServiceReminderBundle`
//  for why. That means a single service no longer owns a request, so there is
//  no such thing as "schedule this one service": every entry point rebuilds
//  the whole vehicle's set from its current data.
//
//  Rebuilding reads the pending set back from the notification center rather
//  than deriving the identifiers to remove. A bundle's identifier encodes the
//  day it fires, and that day moves when a due date or the mileage pace moves,
//  so yesterday's identifiers are not derivable from today's data. The center
//  is the only thing that knows what is actually pending on this device.
//

import Foundation
import UserNotifications
import os

private let serviceNotificationLogger = Logger(category: "Notifications.Service")

/// Scheduler for service due notifications
struct ServiceNotificationScheduler {

    // MARK: - Notification IDs

    /// Prefix shared by every service reminder request, bundled or legacy.
    /// The launch sweep and the per-vehicle purge both key off it.
    static let requestPrefix = "service-"

    /// Deterministic base ID for a service.
    ///
    /// No longer identifies a pending request — bundles are keyed by vehicle
    /// and day. It remains the service's "has a reminder" flag value and the
    /// handle for clearing sets left by builds that scheduled per service.
    static func baseNotificationID(forServiceID serviceID: UUID) -> String {
        requestPrefix + serviceID.uuidString
    }

    static func baseNotificationID(for service: Service) -> String {
        baseNotificationID(forServiceID: service.id)
    }

    private static let snoozeSuffix = "-snooze"

    /// Identifier for a snoozed reminder: the snoozed request's own ID plus a
    /// suffix, so it stays under `requestPrefix` and the vehicle purge reaches it.
    static func snoozeNotificationID(baseID: String) -> String {
        isSnoozeID(baseID) ? baseID : baseID + snoozeSuffix
    }

    static func isSnoozeID(_ identifier: String) -> Bool {
        identifier.hasSuffix(snoozeSuffix)
    }

    /// Identifier for one bundle: one vehicle, one day, one lead time.
    ///
    /// The day is part of the identifier so re-adding an unchanged schedule
    /// replaces each request in place instead of stacking duplicates.
    static func bundleNotificationID(
        vehicleID: UUID, notificationDate: Date, daysBeforeDue: Int
    ) -> String {
        requestPrefix + "bundle-\(vehicleID.uuidString)-\(dayStamp(notificationDate))"
            + NotificationService.intervalSuffix(for: daysBeforeDue)
    }

    /// `yyyyMMdd` from calendar components rather than a `DateFormatter`: this
    /// value goes in an identifier, never on screen, so it must not vary with
    /// the user's locale or calendar formatting preferences.
    private static func dayStamp(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // MARK: - Build Notification Requests

    /// Build the request for one bundle. Pass `trigger` to override the default
    /// 9 AM calendar trigger (e.g. the fire-soon trigger for a same-day
    /// reminder set after 9 AM).
    static func buildNotificationRequest(
        for bundle: ServiceReminderBundle,
        vehicle: Vehicle,
        trigger: UNNotificationTrigger? = nil
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = ServiceReminderCopy.title(for: bundle)
        content.body = ServiceReminderCopy.body(for: bundle, vehicleName: vehicle.displayName)
        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID

        var userInfo: [String: Any] = [
            "serviceIDs": bundle.serviceIDs.map(\.uuidString),
            "vehicleID": vehicle.id.uuidString,
            "daysBeforeDue": bundle.daysBeforeDue,
            // Carried so Remind Tomorrow can reword the banner without the model.
            "serviceNames": bundle.serviceNames,
            "vehicleName": vehicle.displayName
        ]
        // Only when the bundle is one service. Naming an arbitrary member as
        // "the" service would send Mark as Done and tap-through to whichever
        // name happened to sort first.
        if bundle.count == 1, let only = bundle.serviceIDs.first {
            userInfo["serviceID"] = only.uuidString
        }
        content.userInfo = userInfo

        let resolvedTrigger = trigger ?? NotificationHelpers.calendarTrigger(for: bundle.notificationDate)
        let identifier = bundleNotificationID(
            vehicleID: vehicle.id,
            notificationDate: bundle.notificationDate,
            daysBeforeDue: bundle.daysBeforeDue
        )

        return UNNotificationRequest(identifier: identifier, content: content, trigger: resolvedTrigger)
    }

    /// What "Remind Tomorrow" on a service reminder schedules: the same set of
    /// services, delivered again at 9 AM tomorrow.
    ///
    /// The whole banner snoozes, not one member — the button sits on the
    /// banner, so the banner's set is what the user answered. Lead-time words
    /// ("due today") would be stale a day later, so the copy is reworded;
    /// requests scheduled before the payload carried names are re-delivered
    /// as they were.
    static func snoozeRequest(for original: UNNotificationRequest, now: Date = Date()) -> UNNotificationRequest? {
        let userInfo = original.content.userInfo
        let serviceIDs = referencedServiceIDs(in: userInfo)
        guard !serviceIDs.isEmpty else { return nil }

        let content = UNMutableNotificationContent()
        content.userInfo = userInfo
        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID

        let names = userInfo["serviceNames"] as? [String] ?? []
        if let vehicleName = userInfo["vehicleName"] as? String, !names.isEmpty, names.count == serviceIDs.count {
            content.title = ServiceReminderCopy.snoozeTitle(serviceNames: names)
            content.body = ServiceReminderCopy.snoozeBody(serviceNames: names, vehicleName: vehicleName)
        } else {
            content.title = original.content.title
            content.body = original.content.body
        }

        return NotificationHelpers.snoozeRequest(
            identifier: snoozeNotificationID(baseID: original.identifier), content: content, now: now
        )
    }

    // MARK: - Occurrences

    /// Every reminder the vehicle's services want, across all lead times.
    ///
    /// Occurrences whose snapped fire time has already passed are dropped here
    /// rather than at add time: a "due today" reminder set after 9 AM would
    /// otherwise produce a past, non-repeating trigger the OS never delivers.
    ///
    /// With a `window`, services due together share their group's earliest due
    /// date (see `ServiceClusteringService.reminderDueDates`), so the bundler
    /// folds them into one notification per lead time. nil schedules each
    /// service on its own due date. `reminderPlan` passes the user's
    /// clustering preference.
    static func occurrences(
        for vehicle: Vehicle,
        dailyPace: Double?,
        window: DueTogetherWindow? = nil,
        now: Date = Date()
    ) -> [ServiceReminderOccurrence] {
        var occurrences: [ServiceReminderOccurrence] = []
        let services = vehicle.services ?? []
        let groupedDueDates = window.map {
            ServiceClusteringService.reminderDueDates(
                for: services, currentMileage: vehicle.currentMileage, dailyPace: dailyPace, window: $0, now: now
            )
        }

        for service in services {
            let effectiveDate: Date?
            if let groupedDueDates {
                effectiveDate = groupedDueDates[service.id]
            } else {
                effectiveDate = service.effectiveDueDate(currentMileage: vehicle.currentMileage, dailyPace: dailyPace)
            }
            guard let dueDate = effectiveDate, dueDate > now else { continue }

            for daysBeforeDue in NotificationService.defaultReminderIntervals {
                guard let notificationDate = Calendar.current.date(
                    byAdding: .day, value: -daysBeforeDue, to: dueDate
                ) else { continue }
                guard NotificationHelpers.reminderTrigger(for: notificationDate, now: now) != nil else { continue }

                occurrences.append(ServiceReminderOccurrence(
                    serviceID: service.id,
                    serviceName: service.name,
                    daysBeforeDue: daysBeforeDue,
                    notificationDate: notificationDate
                ))
            }
        }
        return occurrences
    }

    // MARK: - Schedule Notifications

    /// A vehicle's complete reminder set, fully resolved from the model.
    ///
    /// Exists so the model read and the notification-center I/O can be
    /// separated. The center calls are async, and a deferred closure that still
    /// held the `Vehicle` would read it after the caller had moved on — after a
    /// delete, or after the context was reset out from under it, which is a
    /// SwiftData trap rather than a nil.
    struct ReminderPlan {
        let vehicleID: UUID
        let requests: [UNNotificationRequest]
        /// Services still worth a snoozed reminder (see `snoozeWorthyServiceIDs`).
        /// A pending snooze naming any of them survives the rebuild.
        let snoozeWorthyServiceIDs: Set<String>
    }

    /// Resolve a vehicle's reminders and record which services they cover.
    /// Synchronous and model-touching; everything after it is plain I/O.
    static func reminderPlan(for vehicle: Vehicle, now: Date = Date()) -> ReminderPlan {
        let bundles = ServiceReminderBundle.bundles(
            from: occurrences(for: vehicle, dailyPace: vehicle.dailyMilesPace, window: .current, now: now)
        )

        let requests = bundles.compactMap { bundle -> UNNotificationRequest? in
            guard let trigger = NotificationHelpers.reminderTrigger(for: bundle.notificationDate, now: now) else { return nil }
            return buildNotificationRequest(for: bundle, vehicle: vehicle, trigger: trigger)
        }

        recordScheduledServices(Set(bundles.flatMap(\.serviceIDs)), in: vehicle)
        return ReminderPlan(
            vehicleID: vehicle.id,
            requests: requests,
            snoozeWorthyServiceIDs: snoozeWorthyServiceIDs(for: vehicle, now: now)
        )
    }

    /// Services a snooze may still remind about: overdue, or due within the
    /// longest lead time. Completing a service moves its due date out past
    /// that, and deleting one drops it, so either retires its snooze.
    static func snoozeWorthyServiceIDs(for vehicle: Vehicle, now: Date = Date()) -> Set<String> {
        let longestLead = NotificationService.defaultReminderIntervals.max() ?? 0
        guard let horizon = Calendar.current.date(byAdding: .day, value: longestLead, to: now) else { return [] }
        let dailyPace = vehicle.dailyMilesPace
        return Set((vehicle.services ?? []).compactMap { service in
            guard let dueDate = service.effectiveDueDate(currentMileage: vehicle.currentMileage, dailyPace: dailyPace),
                  dueDate <= horizon else { return nil }
            return service.id.uuidString
        })
    }

    /// Replace a vehicle's pending requests with the plan's.
    ///
    /// Purge first, then add. Bundle identifiers encode the day they fire, so a
    /// moved due date leaves behind a request no re-add would replace. Snoozes
    /// are the exception: the user asked for them, and every edit and every
    /// launch rebuilds, so they stay while their services are still due.
    static func apply(_ plan: ReminderPlan) async {
        await removeServiceRequests(forVehicleID: plan.vehicleID, keepingSnoozesFor: plan.snoozeWorthyServiceIDs)

        let center = UNUserNotificationCenter.current()
        for request in plan.requests {
            do {
                try await center.add(request)
            } catch {
                serviceNotificationLogger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Rebuild a vehicle's pending reminders from its current data.
    ///
    /// Fire-and-forget for UI callers; the launch sweep uses the awaited
    /// `rescheduleNotificationsAwaitingAdds` so a follow-on budget trim reads
    /// the settled pending set rather than a pre-add snapshot.
    static func rescheduleNotifications(for vehicle: Vehicle) {
        let plan = reminderPlan(for: vehicle)
        Task { await apply(plan) }
        // Every add can push the pending total past the OS's 64-request cap,
        // at which point iOS silently keeps only the 64 soonest. Debounced, so
        // a burst of edits trims once.
        NotificationService.shared.scheduleBudgetEnforcement()
    }

    /// Rebuild a vehicle's pending reminders, awaiting each notification-center
    /// call so a caller can trim the pending budget against the settled set.
    static func rescheduleNotificationsAwaitingAdds(for vehicle: Vehicle) async {
        await apply(reminderPlan(for: vehicle))
    }

    /// Mark which of the vehicle's services have a reminder pending.
    ///
    /// `Service.notificationID` no longer names a request — a service shares
    /// one with everything else due that morning — but it is still the flag the
    /// rest of the app reads for "this has a reminder". Writes are guarded:
    /// this runs on every reschedule, and a same-value set would still dirty
    /// the record for CloudKit sync.
    private static func recordScheduledServices(_ scheduledIDs: Set<UUID>, in vehicle: Vehicle) {
        for service in vehicle.services ?? [] {
            let expected = scheduledIDs.contains(service.id) ? baseNotificationID(for: service) : nil
            if service.notificationID != expected {
                service.notificationID = expected
            }
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel a specific notification by its exact ID
    static func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all notifications for a base ID: interval variants, the snooze
    /// variant, and the bare ID itself.
    static func cancelAllNotifications(baseID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: serviceCancellationIDs(baseID: baseID)
        )
    }

    /// Every notification ID a *per-service* set could have pending for a base
    /// ID: the interval variants, the snooze variant, and the bare base ID.
    /// Bundled requests are not reachable this way by design — they belong to
    /// the vehicle, and `removeServiceRequests(forVehicleID:)` reaches those.
    /// Mirrors `MarbeteNotificationScheduler.marbeteCancellationIDs` so "all IDs
    /// an entity can have" lives in one function per family.
    static func serviceCancellationIDs(baseID: String) -> [String] {
        var ids = NotificationService.defaultReminderIntervals.map { baseID + NotificationService.intervalSuffix(for: $0) }
        ids.append(snoozeNotificationID(baseID: baseID))
        ids.append(baseID)
        return ids
    }

    // There is deliberately no `cancelNotification(for: service)`. Under
    // bundling a service does not own a request — a bundle covering three
    // services has to be reworded, not removed, when one drops out — so
    // "cancel this one service" cannot be expressed as a removal. Callers that
    // dropped or retired a service change the model and then call
    // `rescheduleNotifications(for:)`, which rebuilds the vehicle around what
    // is left.

    /// Cancel every service reminder for a vehicle. Safe to call immediately
    /// before deleting it — the vehicle's ID is captured up front.
    static func cancelNotifications(for vehicle: Vehicle) {
        let vehicleID = vehicle.id
        for service in vehicle.services ?? [] where service.notificationID != nil {
            service.notificationID = nil
        }
        Task { await removeServiceRequests(forVehicleID: vehicleID) }
    }

    /// Remove every pending service request belonging to a vehicle — bundled,
    /// snoozed, or left by a build that scheduled per service — except snoozes
    /// that name one of `keptServiceIDs`.
    static func removeServiceRequests(
        forVehicleID vehicleID: UUID, keepingSnoozesFor keptServiceIDs: Set<String> = []
    ) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .filter {
                $0.identifier.hasPrefix(requestPrefix)
                    && $0.content.userInfo["vehicleID"] as? String == vehicleID.uuidString
                    && !isKeptSnooze($0, keptServiceIDs: keptServiceIDs)
            }
            .map(\.identifier)

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Snooze

    /// Whether a rebuild should leave this pending request alone: it is a
    /// snooze, and at least one service it names is still worth reminding about.
    static func isKeptSnooze(_ request: UNNotificationRequest, keptServiceIDs: Set<String>) -> Bool {
        guard isSnoozeID(request.identifier) else { return false }
        return !keptServiceIDs.isDisjoint(with: referencedServiceIDs(in: request.content.userInfo))
    }

    // MARK: - Pending Notifications

    /// Get all pending notifications
    static func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Whether any pending request — bundled, snoozed, or legacy — covers this
    /// service.
    static func hasPendingNotification(for service: Service) async -> Bool {
        let serviceIDString = service.id.uuidString
        let baseID = baseNotificationID(for: service)
        return await getPendingNotifications().contains { request in
            if request.identifier.hasPrefix(baseID) { return true }
            return referencedServiceIDs(in: request.content.userInfo).contains(serviceIDString)
        }
    }

    /// The service IDs a request's payload names, whatever shape it was written
    /// in: `serviceIDs` for bundles, `serviceID` for snoozes and legacy sets.
    static func referencedServiceIDs(in userInfo: [AnyHashable: Any]) -> [String] {
        if let ids = userInfo["serviceIDs"] as? [String] { return ids }
        if let id = userInfo["serviceID"] as? String { return [id] }
        return []
    }
}
