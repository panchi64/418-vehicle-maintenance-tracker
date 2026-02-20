//
//  MarbeteNotificationScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling marbete (PR vehicle registration) notifications
//

import Foundation
import UserNotifications
import os

private let marbeteNotificationLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Notifications.Marbete")

/// Scheduler for marbete (PR vehicle registration) expiration notifications
struct MarbeteNotificationScheduler {

    // MARK: - Notification IDs

    /// Notification ID for marbete reminders (per vehicle)
    static func marbeteReminderID(for vehicleID: UUID, daysBeforeDue: Int) -> String {
        "marbete-\(vehicleID.uuidString)-\(daysBeforeDue)d"
    }

    /// Base notification ID for marbete (for cancellation)
    static func marbeteBaseID(for vehicleID: UUID) -> String {
        "marbete-\(vehicleID.uuidString)"
    }

    // MARK: - Build Notification Requests

    /// Build a marbete notification request
    static func buildMarbeteNotificationRequest(
        vehicleName: String,
        vehicleID: UUID,
        notificationDate: Date,
        daysBeforeDue: Int
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

        let trigger = NotificationHelpers.calendarTrigger(for: notificationDate)

        return UNNotificationRequest(
            identifier: marbeteReminderID(for: vehicleID, daysBeforeDue: daysBeforeDue),
            content: content,
            trigger: trigger
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

            // Only schedule if the notification date is in the future
            guard notificationDate > Date() else { continue }

            let request = buildMarbeteNotificationRequest(
                vehicleName: vehicle.displayName,
                vehicleID: vehicle.id,
                notificationDate: notificationDate,
                daysBeforeDue: daysBeforeDue
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    marbeteNotificationLogger.error("Failed to schedule marbete notification (\(daysBeforeDue)d before): \(error.localizedDescription)")
                }
            }
        }

        vehicle.marbeteNotificationID = baseNotificationID
        return baseNotificationID
    }

    // MARK: - Cancel Notifications

    /// Cancel all marbete notifications for a vehicle
    static func cancelMarbeteNotifications(for vehicle: Vehicle) {
        // Generate all possible notification IDs for this vehicle
        let allIDs = NotificationService.marbeteReminderIntervals.map {
            marbeteReminderID(for: vehicle.id, daysBeforeDue: $0)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIDs)
        vehicle.marbeteNotificationID = nil
    }

    // MARK: - Snooze

    /// Snooze marbete reminder for 1 day
    static func snoozeMarbeteReminder(for vehicle: Vehicle) {
        cancelMarbeteNotifications(for: vehicle)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let request = buildMarbeteNotificationRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            notificationDate: tomorrow,
            daysBeforeDue: 0  // Snoozed notification
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                marbeteNotificationLogger.error("Failed to snooze marbete reminder: \(error.localizedDescription)")
            }
        }
    }
}
