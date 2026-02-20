//
//  ServiceNotificationScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling service due notifications
//

import Foundation
import UserNotifications
import os

private let serviceNotificationLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Notifications.Service")

/// Scheduler for service due notifications
struct ServiceNotificationScheduler {

    /// Hour at which all service notifications fire (9 AM local time)
    private static let notificationHour = 9

    // MARK: - Build Notification Requests

    /// Build a notification request for a service
    static func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        notificationDate: Date,
        daysBeforeDue: Int = 0
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

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = notificationHour
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
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

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: snoozeDate)
        dateComponents.hour = notificationHour
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
    }

    // MARK: - Schedule Notifications

    /// Schedule notifications for a service at default intervals (30, 7, 1 day before + due date)
    @discardableResult
    static func scheduleNotification(for service: Service, vehicle: Vehicle) -> String? {
        guard let dueDate = service.dueDate, dueDate > .now else { return nil }
        return scheduleNotificationsForDueDate(dueDate, service: service, vehicle: vehicle)
    }

    /// Schedule notifications for all services of a vehicle
    static func scheduleNotifications(for vehicle: Vehicle) {
        for service in vehicle.services ?? [] {
            if let notificationID = scheduleNotification(for: service, vehicle: vehicle) {
                service.notificationID = notificationID
            }
        }
    }

    /// Schedule notification using effective due date (considers pace prediction)
    @discardableResult
    static func scheduleNotificationWithPace(
        for service: Service, vehicle: Vehicle, dailyPace: Double? = nil
    ) -> String? {
        let effectiveDate = service.effectiveDueDate(currentMileage: vehicle.currentMileage, dailyPace: dailyPace)
        guard let dueDate = effectiveDate, dueDate > .now else { return nil }
        return scheduleNotificationsForDueDate(dueDate, service: service, vehicle: vehicle)
    }

    /// Reschedule all notifications for a vehicle using current pace data
    static func rescheduleNotifications(for vehicle: Vehicle) {
        let pace = vehicle.dailyMilesPace
        for service in vehicle.services ?? [] {
            cancelNotification(for: service)
            if let notificationID = scheduleNotificationWithPace(for: service, vehicle: vehicle, dailyPace: pace) {
                service.notificationID = notificationID
            }
        }
    }

    /// Reschedule all notifications for a vehicle with cluster awareness
    /// - Clustered services get a single bundled notification
    /// - Non-clustered services get individual notifications
    @MainActor
    static func rescheduleNotificationsWithClustering(for vehicle: Vehicle) {
        let services = vehicle.services ?? []

        // Cancel all existing notifications first
        cancelNotifications(for: vehicle)
        ClusterNotificationScheduler.cancelClusterNotifications(for: vehicle)

        // Detect clusters
        let clusters = ServiceClusteringService.detectClusters(for: vehicle, services: services)
        let clusteredServiceIDs = Set(clusters.flatMap { $0.services.map { $0.id } })

        // Schedule cluster notifications
        for cluster in clusters {
            ClusterNotificationScheduler.scheduleClusterNotification(for: cluster, vehicle: vehicle)
        }

        // Schedule individual notifications only for non-clustered services
        let standaloneServices = services.filter { !clusteredServiceIDs.contains($0.id) }
        let pace = vehicle.dailyMilesPace

        for service in standaloneServices {
            if let notificationID = scheduleNotificationWithPace(for: service, vehicle: vehicle, dailyPace: pace) {
                service.notificationID = notificationID
            }
        }
    }

    /// Internal helper to schedule notifications for a due date
    private static func scheduleNotificationsForDueDate(
        _ dueDate: Date, service: Service, vehicle: Vehicle
    ) -> String {
        if let existingID = service.notificationID {
            cancelAllNotifications(baseID: existingID)
        }

        let baseNotificationID = "service-\(UUID().uuidString)"
        let notificationCenter = UNUserNotificationCenter.current()

        for daysBeforeDue in NotificationService.defaultReminderIntervals {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeDue, to: dueDate),
                  notificationDate > .now else { continue }

            let notificationID = baseNotificationID + NotificationService.intervalSuffix(for: daysBeforeDue)
            let request = buildNotificationRequest(
                for: service, vehicle: vehicle, notificationID: notificationID,
                notificationDate: notificationDate, daysBeforeDue: daysBeforeDue
            )
            notificationCenter.add(request) { error in
                if let error = error { serviceNotificationLogger.error("Failed to schedule notification (\(daysBeforeDue)d before): \(error.localizedDescription)") }
            }
        }
        return baseNotificationID
    }

    // MARK: - Cancel Notifications

    /// Cancel a specific notification by its exact ID
    static func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all notifications for a base ID (including all interval variants)
    static func cancelAllNotifications(baseID: String) {
        let allIDs = NotificationService.defaultReminderIntervals.map { baseID + NotificationService.intervalSuffix(for: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIDs)
    }

    /// Cancel all notifications for a service
    static func cancelNotification(for service: Service) {
        if let notificationID = service.notificationID {
            cancelAllNotifications(baseID: notificationID)
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
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        let notificationID = "service-snooze-\(UUID().uuidString)"
        let request = buildSnoozeNotificationRequest(for: service, vehicle: vehicle,
                                                     notificationID: notificationID, snoozeDate: tomorrow)
        UNUserNotificationCenter.current().add(request)
        service.notificationID = notificationID
    }

    // MARK: - Pending Notifications

    /// Get all pending notifications
    static func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Check if a service has a pending notification
    static func hasPendingNotification(for service: Service) async -> Bool {
        guard let notificationID = service.notificationID else { return false }
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier == notificationID }
    }
}
