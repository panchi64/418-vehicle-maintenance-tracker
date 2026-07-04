//
//  MarbeteNotificationScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling marbete (PR vehicle registration) notifications
//

import Foundation
import UserNotifications
import os

private let marbeteNotificationLogger = Logger(category: "Notifications.Marbete")

/// Scheduler for marbete (PR vehicle registration) expiration notifications
struct MarbeteNotificationScheduler {

    // MARK: - Notification IDs

    /// `daysBeforeDue` value used for the snoozed / imminent ("due now")
    /// reminder. Kept distinct from `marbeteReminderIntervals` but included in
    /// every cancel path so a snoozed request can't survive a re-edit or
    /// vehicle deletion.
    static let snoozeDaysBeforeDue = 0

    /// Notification ID for marbete reminders (per vehicle)
    static func marbeteReminderID(for vehicleID: UUID, daysBeforeDue: Int) -> String {
        "marbete-\(vehicleID.uuidString)-\(daysBeforeDue)d"
    }

    /// Base notification ID for marbete (for cancellation)
    static func marbeteBaseID(for vehicleID: UUID) -> String {
        "marbete-\(vehicleID.uuidString)"
    }

    // MARK: - Build Notification Requests

    /// Build a marbete notification request. Pass `trigger` to override the
    /// default 9 AM calendar trigger (e.g. a fire-soon trigger for a same-day
    /// reminder); leave it nil for the standard behavior.
    static func buildMarbeteNotificationRequest(
        vehicleName: String,
        vehicleID: UUID,
        notificationDate: Date,
        daysBeforeDue: Int,
        trigger: UNNotificationTrigger? = nil
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()

        // Vary message based on urgency (tone escalates as deadline approaches)
        switch daysBeforeDue {
        case 60:
            content.title = "Marbete Status: 60 Days"
            content.body = "\(vehicleName) requesting registration renewal. No rush. Yet."
        case 30:
            content.title = "Marbete Status: 30 Days"
            content.body = "\(vehicleName) would prefer not to be impounded."
        case 7:
            content.title = "Marbete Status: 7 Days"
            content.body = "\(vehicleName) is starting to worry about that marbete."
        case 1:
            content.title = "Marbete Status: URGENT"
            content.body = "\(vehicleName) expires tomorrow. Legally speaking."
        case snoozeDaysBeforeDue:
            content.title = String(localized: "Marbete Status: FINAL NOTICE")
            content.body = String(localized: "\(vehicleName) is out of time. Renew the marbete today.")
        default:
            content.title = "Marbete Status: \(daysBeforeDue) Days"
            content.body = "\(vehicleName) - Marbete expires in \(daysBeforeDue) days."
        }

        content.sound = .default
        content.categoryIdentifier = NotificationService.marbeteDueCategoryID
        content.userInfo = [
            "vehicleID": vehicleID.uuidString,
            "type": "marbeteReminder",
            "daysBeforeDue": daysBeforeDue
        ]

        let resolvedTrigger = trigger ?? NotificationHelpers.calendarTrigger(for: notificationDate)

        return UNNotificationRequest(
            identifier: marbeteReminderID(for: vehicleID, daysBeforeDue: daysBeforeDue),
            content: content,
            trigger: resolvedTrigger
        )
    }

    // MARK: - Schedule Notifications

    /// Schedule marbete notifications for a vehicle at default intervals (60, 30, 7, 1 days before)
    /// - Parameter vehicle: The vehicle with marbete expiration set
    /// - Returns: The base notification identifier if scheduled successfully
    @discardableResult
    static func scheduleMarbeteNotifications(for vehicle: Vehicle) -> String? {
        guard let expirationDate = vehicle.marbeteExpirationDate else { return nil }

        // Don't schedule if already expired
        guard expirationDate > Date() else { return nil }

        // Cancel existing notifications
        cancelMarbeteNotifications(for: vehicle)

        let baseNotificationID = marbeteBaseID(for: vehicle.id)
        let notificationCenter = UNUserNotificationCenter.current()

        // Schedule notifications for each interval
        for daysBeforeDue in NotificationService.marbeteReminderIntervals {
            guard let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -daysBeforeDue,
                to: expirationDate
            ) else { continue }

            // Gate on the actual 9 AM-snapped fire date, not the raw date, so a
            // reminder that snaps into the past today is skipped (or fired soon)
            // rather than dropped silently by the OS.
            guard let trigger = NotificationHelpers.reminderTrigger(for: notificationDate) else { continue }

            let request = buildMarbeteNotificationRequest(
                vehicleName: vehicle.displayName,
                vehicleID: vehicle.id,
                notificationDate: notificationDate,
                daysBeforeDue: daysBeforeDue,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    marbeteNotificationLogger.error("Failed to schedule marbete notification (\(daysBeforeDue)d before): \(error.localizedDescription)")
                }
            }
        }

        NotificationService.shared.scheduleBudgetEnforcement()

        vehicle.marbeteNotificationID = baseNotificationID
        return baseNotificationID
    }

    // MARK: - Cancel Notifications

    /// Cancel all marbete notifications for a vehicle
    static func cancelMarbeteNotifications(for vehicle: Vehicle) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: marbeteCancellationIDs(for: vehicle.id)
        )
        vehicle.marbeteNotificationID = nil
    }

    /// Every marbete notification ID this vehicle could have pending: the
    /// default intervals plus the snooze/imminent (0-day) request, which a
    /// plain interval sweep would otherwise strand across re-edits and deletion.
    static func marbeteCancellationIDs(for vehicleID: UUID) -> [String] {
        NotificationService.marbeteReminderIntervals.map {
            marbeteReminderID(for: vehicleID, daysBeforeDue: $0)
        } + [marbeteReminderID(for: vehicleID, daysBeforeDue: snoozeDaysBeforeDue)]
    }

    // MARK: - Snooze

    /// Snooze marbete reminder for 1 day. Async so callers (and tests) can
    /// observe the request once it's actually registered with the center.
    static func snoozeMarbeteReminder(for vehicle: Vehicle) async {
        cancelMarbeteNotifications(for: vehicle)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let request = buildMarbeteNotificationRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            notificationDate: tomorrow,
            daysBeforeDue: snoozeDaysBeforeDue
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            marbeteNotificationLogger.error("Failed to snooze marbete reminder: \(error.localizedDescription)")
        }

        NotificationService.shared.scheduleBudgetEnforcement()
    }
}
