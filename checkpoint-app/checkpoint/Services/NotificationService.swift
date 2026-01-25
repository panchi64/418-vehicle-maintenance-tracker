//
//  NotificationService.swift
//  checkpoint
//
//  Service for managing local notifications for vehicle maintenance reminders
//

import Foundation
import UserNotifications
import SwiftData
import Combine

/// Service for managing local notifications for vehicle maintenance reminders
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification category identifiers
    static let serviceDueCategoryID = "SERVICE_DUE"
    static let markDoneActionID = "MARK_DONE"
    static let snoozeActionID = "SNOOZE"

    // Default reminder intervals (days before due date)
    // These are the advance warning intervals users receive
    static let defaultReminderIntervals: [Int] = [30, 7, 1, 0]  // 30 days, 7 days, 1 day, due date

    // Notification ID suffixes for each interval
    private static func intervalSuffix(for days: Int) -> String {
        switch days {
        case 0: return "-due"
        case 1: return "-1d"
        case 7: return "-7d"
        case 30: return "-30d"
        default: return "-\(days)d"
        }
    }

    private override init() {
        super.init()
        setupNotificationCategories()
    }

    // MARK: - Authorization

    /// Request notification authorization from the user
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Notification Categories & Actions

    private func setupNotificationCategories() {
        // Mark as Done action
        let markDoneAction = UNNotificationAction(
            identifier: Self.markDoneActionID,
            title: "Mark as Done",
            options: [.foreground]
        )

        // Snooze action (dismiss notification, reschedule for tomorrow)
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Remind Tomorrow",
            options: []
        )

        // Service due category
        let serviceDueCategory = UNNotificationCategory(
            identifier: Self.serviceDueCategoryID,
            actions: [markDoneAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([serviceDueCategory])
    }

    // MARK: - Schedule Notifications

    /// Build a notification request for a service (exposed for testing)
    /// - Parameters:
    ///   - service: The service to build notification for
    ///   - vehicle: The vehicle the service belongs to
    ///   - notificationID: The identifier to use for the notification
    ///   - notificationDate: The date to send the notification
    ///   - daysBeforeDue: How many days before the due date (0 = due date, used for message)
    /// - Returns: The notification request
    func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        notificationDate: Date,
        daysBeforeDue: Int = 0
    ) -> UNNotificationRequest {
        // Create content with appropriate messaging based on timing
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
        content.categoryIdentifier = Self.serviceDueCategoryID
        content.userInfo = [
            "serviceID": service.id.uuidString,
            "vehicleID": vehicle.id.uuidString,
            "daysBeforeDue": daysBeforeDue
        ]

        // Create trigger for 9 AM on the notification date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
    }

    /// Build a notification request for a service (legacy method for backwards compatibility)
    /// - Parameters:
    ///   - service: The service to build notification for
    ///   - vehicle: The vehicle the service belongs to
    ///   - notificationID: The identifier to use for the notification
    ///   - dueDate: The due date for the notification
    /// - Returns: The notification request
    func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        dueDate: Date
    ) -> UNNotificationRequest {
        buildNotificationRequest(
            for: service,
            vehicle: vehicle,
            notificationID: notificationID,
            notificationDate: dueDate,
            daysBeforeDue: 0
        )
    }

    /// Build a snoozed notification request for a service (exposed for testing)
    /// - Parameters:
    ///   - service: The service to build notification for
    ///   - vehicle: The vehicle the service belongs to
    ///   - notificationID: The identifier to use for the notification
    ///   - snoozeDate: The date to schedule the snooze notification
    /// - Returns: The notification request
    func buildSnoozeNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        snoozeDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "\(service.name) Reminder"
        content.body = "\(vehicle.displayName) - \(service.name) is due for maintenance"
        content.sound = .default
        content.categoryIdentifier = Self.serviceDueCategoryID
        content.userInfo = [
            "serviceID": service.id.uuidString,
            "vehicleID": vehicle.id.uuidString
        ]

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: snoozeDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
    }

    /// Schedule notifications for a service at default intervals (30, 7, 1 day before + due date)
    /// - Parameters:
    ///   - service: The service to schedule notification for
    ///   - vehicle: The vehicle the service belongs to
    /// - Returns: The base notification identifier if scheduled successfully
    @discardableResult
    func scheduleNotification(for service: Service, vehicle: Vehicle) -> String? {
        guard let dueDate = service.dueDate else { return nil }

        // Don't schedule if due date is in the past
        guard dueDate > Date() else { return nil }

        // Cancel existing notifications if any
        if let existingID = service.notificationID {
            cancelAllNotifications(baseID: existingID)
        }

        // Create unique base identifier
        let baseNotificationID = "service-\(UUID().uuidString)"

        // Schedule notifications for each interval
        for daysBeforeDue in Self.defaultReminderIntervals {
            guard let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -daysBeforeDue,
                to: dueDate
            ) else { continue }

            // Only schedule if the notification date is in the future
            guard notificationDate > Date() else { continue }

            let notificationID = baseNotificationID + Self.intervalSuffix(for: daysBeforeDue)

            let request = buildNotificationRequest(
                for: service,
                vehicle: vehicle,
                notificationID: notificationID,
                notificationDate: notificationDate,
                daysBeforeDue: daysBeforeDue
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification (\(daysBeforeDue)d before): \(error)")
                }
            }
        }

        return baseNotificationID
    }

    /// Schedule notifications for all services of a vehicle
    func scheduleNotifications(for vehicle: Vehicle) {
        for service in vehicle.services {
            if let notificationID = scheduleNotification(for: service, vehicle: vehicle) {
                service.notificationID = notificationID
            }
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel a specific notification by its exact ID
    func cancelNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all notifications for a base ID (including all interval variants)
    func cancelAllNotifications(baseID: String) {
        // Generate all possible notification IDs for this base ID
        let allIDs = Self.defaultReminderIntervals.map { baseID + Self.intervalSuffix(for: $0) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: allIDs)
    }

    /// Cancel all notifications for a service
    func cancelNotification(for service: Service) {
        if let notificationID = service.notificationID {
            cancelAllNotifications(baseID: notificationID)
            service.notificationID = nil
        }
    }

    /// Cancel all notifications for a vehicle
    func cancelNotifications(for vehicle: Vehicle) {
        for service in vehicle.services {
            cancelNotification(for: service)
        }
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Snooze

    /// Reschedule notification for tomorrow at 9 AM
    func snoozeNotification(for service: Service, vehicle: Vehicle) {
        // Cancel current notification
        cancelNotification(for: service)

        // Create new notification for tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let notificationID = "service-snooze-\(UUID().uuidString)"

        // Build and schedule the request
        let request = buildSnoozeNotificationRequest(
            for: service,
            vehicle: vehicle,
            notificationID: notificationID,
            snoozeDate: tomorrow
        )

        notificationCenter.add(request)
        service.notificationID = notificationID
    }

    // MARK: - Pending Notifications

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Check if a service has a pending notification
    func hasPendingNotification(for service: Service) async -> Bool {
        guard let notificationID = service.notificationID else { return false }
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier == notificationID }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    /// Handle notification action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // Extract service and vehicle IDs from userInfo
        guard let serviceIDString = userInfo["serviceID"] as? String,
              let _ = userInfo["vehicleID"] as? String else {
            return
        }

        switch response.actionIdentifier {
        case Self.markDoneActionID:
            // Post notification to handle in app
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .serviceMarkedDoneFromNotification,
                    object: nil,
                    userInfo: ["serviceID": serviceIDString]
                )
            }

        case Self.snoozeActionID:
            // Post notification to handle snooze in app
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .serviceSnoozedFromNotification,
                    object: nil,
                    userInfo: ["serviceID": serviceIDString]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - navigate to service
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .navigateToServiceFromNotification,
                    object: nil,
                    userInfo: ["serviceID": serviceIDString]
                )
            }

        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let serviceMarkedDoneFromNotification = Notification.Name("serviceMarkedDoneFromNotification")
    static let serviceSnoozedFromNotification = Notification.Name("serviceSnoozedFromNotification")
    static let navigateToServiceFromNotification = Notification.Name("navigateToServiceFromNotification")
}
