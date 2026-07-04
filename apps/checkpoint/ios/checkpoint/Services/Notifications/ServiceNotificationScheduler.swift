//
//  ServiceNotificationScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling service due notifications
//

import Foundation
import UserNotifications
import os

private let serviceNotificationLogger = Logger(category: "Notifications.Service")

/// Scheduler for service due notifications
struct ServiceNotificationScheduler {

    // MARK: - Notification IDs

    /// Deterministic base ID for a service's notification set.
    ///
    /// The ID must be derivable from the service alone: `service.notificationID`
    /// syncs through CloudKit while pending requests are per-device, so a
    /// stored ID can point at a set that was scheduled on another device.
    /// With a deterministic ID, re-adding a request replaces the pending one
    /// with the same identifier and a reschedule can never orphan an old set
    /// (which would keep firing with stale content, e.g. a pre-rename
    /// vehicle name, alongside the fresh one).
    static func baseNotificationID(forServiceID serviceID: UUID) -> String {
        "service-\(serviceID.uuidString)"
    }

    static func baseNotificationID(for service: Service) -> String {
        baseNotificationID(forServiceID: service.id)
    }

    /// Identifier for a snoozed reminder, derived from the same base so
    /// `cancelAllNotifications(baseID:)` can always reach it.
    static func snoozeNotificationID(baseID: String) -> String {
        baseID + "-snooze"
    }

    // MARK: - Build Notification Requests

    /// Build a notification request for a service. Pass `trigger` to override
    /// the default 9 AM calendar trigger (e.g. a fire-soon trigger for a
    /// same-day reminder); leave it nil for the standard behavior.
    static func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        notificationDate: Date,
        daysBeforeDue: Int = 0,
        trigger: UNNotificationTrigger? = nil
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()

        switch daysBeforeDue {
        case 0:
            content.title = "\(service.name) Due Today"
            content.body = "\(vehicle.displayName) - \(service.name) is due for maintenance"
        case 1:
            content.title = "\(service.name) Due Tomorrow"
            content.body = "\(vehicle.displayName) - \(service.name) is due tomorrow"
        case 7:
            content.title = "\(service.name) Due in 1 Week"
            content.body = "\(vehicle.displayName) - \(service.name) is due in 7 days"
        case 30:
            content.title = "\(service.name) Coming Up"
            content.body = "\(vehicle.displayName) - \(service.name) is due in 30 days"
        default:
            content.title = "\(service.name) Reminder"
            content.body = "\(vehicle.displayName) - \(service.name) is due in \(daysBeforeDue) days"
        }

        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID
        content.userInfo = [
            "serviceID": service.id.uuidString,
            "vehicleID": vehicle.id.uuidString,
            "daysBeforeDue": daysBeforeDue
        ]

        let resolvedTrigger = trigger ?? NotificationHelpers.calendarTrigger(for: notificationDate)

        return UNNotificationRequest(identifier: notificationID, content: content, trigger: resolvedTrigger)
    }

    /// Build a notification request for a service (legacy method)
    static func buildNotificationRequest(
        for service: Service, vehicle: Vehicle, notificationID: String, dueDate: Date
    ) -> UNNotificationRequest {
        buildNotificationRequest(for: service, vehicle: vehicle, notificationID: notificationID,
                                 notificationDate: dueDate, daysBeforeDue: 0)
    }

    /// Build a snoozed notification request for a service
    static func buildSnoozeNotificationRequest(
        for service: Service, vehicle: Vehicle, notificationID: String, snoozeDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "\(service.name) Reminder"
        content.body = "\(vehicle.displayName) - \(service.name) is due for maintenance"
        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID
        content.userInfo = ["serviceID": service.id.uuidString, "vehicleID": vehicle.id.uuidString]

        let trigger = NotificationHelpers.calendarTrigger(for: snoozeDate)

        return UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
    }

    // MARK: - Schedule Notifications

    /// Schedule notifications for a service at default intervals (30, 7, 1 day before + due date)
    @discardableResult
    static func scheduleNotification(for service: Service, vehicle: Vehicle) -> String? {
        guard let dueDate = service.dueDate, dueDate > Date() else { return nil }
        return scheduleNotificationsForDueDate(dueDate, service: service, vehicle: vehicle)
    }

    /// Schedule notifications for all services of a vehicle
    static func scheduleNotifications(for vehicle: Vehicle) {
        for service in vehicle.services ?? [] {
            scheduleNotification(for: service, vehicle: vehicle)
        }
    }

    /// Schedule notification using effective due date (considers pace prediction)
    @discardableResult
    static func scheduleNotificationWithPace(
        for service: Service, vehicle: Vehicle, dailyPace: Double? = nil
    ) -> String? {
        guard let dueDate = schedulableDueDate(for: service, vehicle: vehicle, dailyPace: dailyPace) else { return nil }
        return scheduleNotificationsForDueDate(dueDate, service: service, vehicle: vehicle)
    }

    /// The effective due date to schedule a service against, or nil if it has
    /// none in the future (the caller should cancel instead). Shared by the
    /// sync and async reschedule paths so the future-gate lives in one place.
    private static func schedulableDueDate(
        for service: Service, vehicle: Vehicle, dailyPace: Double?
    ) -> Date? {
        let effectiveDate = service.effectiveDueDate(currentMileage: vehicle.currentMileage, dailyPace: dailyPace)
        guard let dueDate = effectiveDate, dueDate > Date() else { return nil }
        return dueDate
    }

    /// Reschedule all notifications for a vehicle using current pace data.
    /// Fire-and-forget adds for UI callers; the launch sweep uses the awaited
    /// `rescheduleNotificationsAwaitingAdds` so a follow-on budget trim reads
    /// the settled pending set rather than a pre-add snapshot.
    static func rescheduleNotifications(for vehicle: Vehicle) {
        let pace = vehicle.dailyMilesPace
        for service in vehicle.services ?? [] {
            // Scheduling replaces the pending set in place; only a service
            // with no effective due date needs an explicit cancel.
            if scheduleNotificationWithPace(for: service, vehicle: vehicle, dailyPace: pace) == nil {
                cancelNotification(for: service)
            }
        }
    }

    /// Reschedule a vehicle's services, awaiting each notification-center add
    /// so a caller can trim the pending budget against the settled set. Used
    /// by launch maintenance; UI callers use the fire-and-forget variant.
    static func rescheduleNotificationsAwaitingAdds(for vehicle: Vehicle) async {
        let pace = vehicle.dailyMilesPace
        for service in vehicle.services ?? [] {
            if let dueDate = schedulableDueDate(for: service, vehicle: vehicle, dailyPace: pace) {
                await addNotificationsAwaitingCenter(forDueDate: dueDate, service: service, vehicle: vehicle)
            } else {
                cancelNotification(for: service)
            }
        }
    }

    /// Build a service's interval requests for a due date and clear the stale
    /// variants a plain re-add wouldn't replace, recording the deterministic
    /// base ID on the service. The single source of the pending set: the sync
    /// and async add paths differ only in how they hand these to the center.
    private static func notificationRequests(
        forDueDate dueDate: Date, service: Service, vehicle: Vehicle
    ) -> [UNNotificationRequest] {
        let baseNotificationID = baseNotificationID(for: service)

        // Clear any set scheduled before IDs became deterministic
        if let existingID = service.notificationID, existingID != baseNotificationID {
            cancelAllNotifications(baseID: existingID)
        }
        // Clear variants a plain re-add wouldn't replace (skipped past-date
        // intervals, pending snooze)
        cancelAllNotifications(baseID: baseNotificationID)

        var requests: [UNNotificationRequest] = []
        for daysBeforeDue in NotificationService.defaultReminderIntervals {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeDue, to: dueDate) else { continue }
            // Gate on the actual 9 AM-snapped fire date, not the raw date: a
            // "due today" reminder set after 9 AM would otherwise pass a raw
            // `> Date()` check yet produce a past trigger the OS never delivers.
            guard let trigger = NotificationHelpers.reminderTrigger(for: notificationDate) else { continue }

            let notificationID = baseNotificationID + NotificationService.intervalSuffix(for: daysBeforeDue)
            requests.append(buildNotificationRequest(
                for: service, vehicle: vehicle, notificationID: notificationID,
                notificationDate: notificationDate, daysBeforeDue: daysBeforeDue, trigger: trigger
            ))
        }

        // Guard the write: this runs on every reschedule, and a same-value
        // set would still dirty the record for CloudKit sync
        if service.notificationID != baseNotificationID {
            service.notificationID = baseNotificationID
        }
        return requests
    }

    /// Sync (fire-and-forget) schedule for a due date. Triggers a debounced
    /// budget enforcement so a mid-session add can't leave the pending set over
    /// the OS's 64-request cap until the next cold launch.
    private static func scheduleNotificationsForDueDate(
        _ dueDate: Date, service: Service, vehicle: Vehicle
    ) -> String {
        let notificationCenter = UNUserNotificationCenter.current()
        for request in notificationRequests(forDueDate: dueDate, service: service, vehicle: vehicle) {
            notificationCenter.add(request) { error in
                if let error = error { serviceNotificationLogger.error("Failed to schedule notification: \(error.localizedDescription)") }
            }
        }
        NotificationService.shared.scheduleBudgetEnforcement()
        return baseNotificationID(for: service)
    }

    /// Async schedule for a due date that awaits each add, so a follow-on
    /// `enforcePendingBudget()` reads the settled pending set rather than a
    /// pre-add snapshot. No debounced enforcement here: the launch caller
    /// awaits the trim directly.
    private static func addNotificationsAwaitingCenter(
        forDueDate dueDate: Date, service: Service, vehicle: Vehicle
    ) async {
        let notificationCenter = UNUserNotificationCenter.current()
        for request in notificationRequests(forDueDate: dueDate, service: service, vehicle: vehicle) {
            do {
                try await notificationCenter.add(request)
            } catch {
                serviceNotificationLogger.error("Failed to schedule notification: \(error.localizedDescription)")
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

    /// Every notification ID a service's set could have pending for a base ID:
    /// the interval variants, the snooze variant, and the bare base ID (legacy
    /// single-request and snooze schemes used the base as the full identifier).
    /// Mirrors `MarbeteNotificationScheduler.marbeteCancellationIDs` so "all IDs
    /// an entity can have" lives in one function per family.
    static func serviceCancellationIDs(baseID: String) -> [String] {
        var ids = NotificationService.defaultReminderIntervals.map { baseID + NotificationService.intervalSuffix(for: $0) }
        ids.append(snoozeNotificationID(baseID: baseID))
        ids.append(baseID)
        return ids
    }

    /// Cancel all notifications for a service
    static func cancelNotification(for service: Service) {
        let baseID = baseNotificationID(for: service)
        if let storedID = service.notificationID, storedID != baseID {
            cancelAllNotifications(baseID: storedID)
        }
        cancelAllNotifications(baseID: baseID)
        if service.notificationID != nil {
            service.notificationID = nil
        }
    }

    /// Cancel all notifications for a vehicle
    static func cancelNotifications(for vehicle: Vehicle) {
        for service in vehicle.services ?? [] { cancelNotification(for: service) }
    }

    // MARK: - Snooze

    /// Reschedule notification for tomorrow at 9 AM
    static func snoozeNotification(for service: Service, vehicle: Vehicle) {
        cancelNotification(for: service)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let baseID = baseNotificationID(for: service)
        let request = buildSnoozeNotificationRequest(for: service, vehicle: vehicle,
                                                     notificationID: snoozeNotificationID(baseID: baseID),
                                                     snoozeDate: tomorrow)
        UNUserNotificationCenter.current().add(request)
        service.notificationID = baseID
        NotificationService.shared.scheduleBudgetEnforcement()
    }

    // MARK: - Pending Notifications

    /// Get all pending notifications
    static func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Check if a service has a pending notification (any interval or snooze variant)
    static func hasPendingNotification(for service: Service) async -> Bool {
        let baseID = baseNotificationID(for: service)
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier.hasPrefix(baseID) }
    }
}
