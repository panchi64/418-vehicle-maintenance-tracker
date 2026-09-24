//
//  MileageReminderScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling mileage reminder notifications
//

import Foundation
import UserNotifications
import os

private let mileageNotificationLogger = Logger(category: "Notifications.Mileage")

/// Scheduler for mileage reminder notifications
struct MileageReminderScheduler {

    // MARK: - Notification IDs

    /// Notification ID for mileage reminders (per vehicle)
    static func mileageReminderID(for vehicleID: UUID) -> String {
        "mileage-reminder-\(vehicleID.uuidString)"
    }

    // MARK: - Build Notification Requests

    /// Build a mileage reminder notification request
    static func buildMileageReminderRequest(
        vehicleName: String,
        vehicleID: UUID,
        reminderDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Odometer Sync Requested"
        content.body = "\(vehicleName) here. It's been 14 days. How far have we gone?"
        content.sound = .default
        content.categoryIdentifier = NotificationService.mileageReminderCategoryID
        content.userInfo = [
            "vehicleID": vehicleID.uuidString,
            "type": "mileageReminder"
        ]

        let trigger = NotificationHelpers.calendarTrigger(for: reminderDate)

        return UNNotificationRequest(
            identifier: mileageReminderID(for: vehicleID),
            content: content,
            trigger: trigger
        )
    }

    // MARK: - Schedule Notifications

    /// Schedule a mileage reminder notification for a vehicle
    /// Schedules 14 days from the provided lastUpdateDate (or now if nil)
    /// - Parameters:
    ///   - vehicle: The vehicle to remind about
    ///   - lastUpdateDate: The date of the last mileage update (defaults to now)
    static func scheduleMileageReminder(for vehicle: Vehicle, lastUpdateDate: Date = .now) {
        // Cancel any existing reminder for this vehicle
        cancelMileageReminder(for: vehicle)

        // Schedule for 14 days from last update
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: NotificationService.mileageReminderIntervalDays,
            to: lastUpdateDate
        ) else { return }

        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }

        let request = buildMileageReminderRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            reminderDate: reminderDate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                mileageNotificationLogger.error("Failed to schedule mileage reminder: \(error.localizedDescription)")
            }
        }

        NotificationService.shared.scheduleBudgetEnforcement()
    }

    // MARK: - Cancel Notifications

    /// Cancel mileage reminder for a vehicle
    static func cancelMileageReminder(for vehicle: Vehicle) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [mileageReminderID(for: vehicle.id)]
        )
    }

    // MARK: - Snooze

    /// What "Remind Tomorrow" on a mileage reminder schedules: the same banner
    /// at 9 AM tomorrow, built from the delivered notification alone.
    static func snoozeRequest(for original: UNNotificationRequest, now: Date = Date()) -> UNNotificationRequest? {
        guard let vehicleIDString = original.content.userInfo["vehicleID"] as? String,
              let vehicleID = UUID(uuidString: vehicleIDString) else { return nil }
        // The vehicle's one mileage-reminder ID: a mileage update reschedules
        // under it, which retires the snooze along with the old reminder.
        return NotificationHelpers.snoozeRequest(
            identifier: mileageReminderID(for: vehicleID), content: original.content, now: now
        )
    }
}
