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

    // Mileage reminder category
    static let mileageReminderCategoryID = "MILEAGE_REMINDER"
    static let updateMileageActionID = "UPDATE_MILEAGE"
    static let remindLaterActionID = "REMIND_LATER"

    // Yearly roundup category
    static let yearlyRoundupCategoryID = "YEARLY_ROUNDUP"
    static let viewCostsActionID = "VIEW_COSTS"

    // Mileage reminder interval (14 days)
    static let mileageReminderIntervalDays = 14

    // UserDefaults keys
    private static let lastYearlyRoundupYearKey = "lastYearlyRoundupYear"

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

        // Mileage reminder actions
        let updateMileageAction = UNNotificationAction(
            identifier: Self.updateMileageActionID,
            title: "Update Now",
            options: [.foreground]
        )

        let remindLaterAction = UNNotificationAction(
            identifier: Self.remindLaterActionID,
            title: "Remind Tomorrow",
            options: []
        )

        // Mileage reminder category
        let mileageReminderCategory = UNNotificationCategory(
            identifier: Self.mileageReminderCategoryID,
            actions: [updateMileageAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Yearly roundup actions
        let viewCostsAction = UNNotificationAction(
            identifier: Self.viewCostsActionID,
            title: "View Costs",
            options: [.foreground]
        )

        // Yearly roundup category
        let yearlyRoundupCategory = UNNotificationCategory(
            identifier: Self.yearlyRoundupCategoryID,
            actions: [viewCostsAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            serviceDueCategory,
            mileageReminderCategory,
            yearlyRoundupCategory
        ])
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

    /// Schedule notification using effective due date (considers pace prediction)
    /// - Parameters:
    ///   - service: The service to schedule notification for
    ///   - vehicle: The vehicle the service belongs to
    ///   - dailyPace: Optional daily driving pace for mileage-based predictions
    /// - Returns: The base notification identifier if scheduled successfully
    @discardableResult
    func scheduleNotificationWithPace(
        for service: Service,
        vehicle: Vehicle,
        dailyPace: Double? = nil
    ) -> String? {
        // Calculate effective due date considering pace prediction
        let effectiveDate = service.effectiveDueDate(
            currentMileage: vehicle.currentMileage,
            dailyPace: dailyPace
        )

        guard let dueDate = effectiveDate, dueDate > Date() else { return nil }

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

    /// Reschedule all notifications for a vehicle using current pace data
    /// Call this after mileage updates to adjust notification timing
    func rescheduleNotifications(for vehicle: Vehicle) {
        let pace = vehicle.dailyMilesPace

        for service in vehicle.services {
            // Cancel existing notifications
            cancelNotification(for: service)

            // Reschedule with pace-aware timing
            if let notificationID = scheduleNotificationWithPace(
                for: service,
                vehicle: vehicle,
                dailyPace: pace
            ) {
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

    // MARK: - Mileage Reminder Notifications

    /// Notification ID for mileage reminders (per vehicle)
    static func mileageReminderID(for vehicleID: UUID) -> String {
        "mileage-reminder-\(vehicleID.uuidString)"
    }

    /// Build a mileage reminder notification request (exposed for testing)
    func buildMileageReminderRequest(
        vehicleName: String,
        vehicleID: UUID,
        reminderDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Time to Update Your Odometer"
        content.body = "Keep \(vehicleName) maintenance estimates accurate by updating your current mileage"
        content.sound = .default
        content.categoryIdentifier = Self.mileageReminderCategoryID
        content.userInfo = [
            "vehicleID": vehicleID.uuidString,
            "type": "mileageReminder"
        ]

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: Self.mileageReminderID(for: vehicleID),
            content: content,
            trigger: trigger
        )
    }

    /// Schedule a mileage reminder notification for a vehicle
    /// Schedules 14 days from the provided lastUpdateDate (or now if nil)
    /// - Parameters:
    ///   - vehicle: The vehicle to remind about
    ///   - lastUpdateDate: The date of the last mileage update (defaults to now)
    func scheduleMileageReminder(for vehicle: Vehicle, lastUpdateDate: Date = .now) {
        // Cancel any existing reminder for this vehicle
        cancelMileageReminder(for: vehicle)

        // Schedule for 14 days from last update
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: Self.mileageReminderIntervalDays,
            to: lastUpdateDate
        ) else { return }

        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }

        let request = buildMileageReminderRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            reminderDate: reminderDate
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule mileage reminder: \(error)")
            }
        }
    }

    /// Cancel mileage reminder for a vehicle
    func cancelMileageReminder(for vehicle: Vehicle) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.mileageReminderID(for: vehicle.id)]
        )
    }

    /// Snooze mileage reminder for 1 day
    func snoozeMileageReminder(for vehicle: Vehicle) {
        cancelMileageReminder(for: vehicle)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let request = buildMileageReminderRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            reminderDate: tomorrow
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to snooze mileage reminder: \(error)")
            }
        }
    }

    // MARK: - Yearly Cost Roundup Notifications

    /// Notification ID for yearly roundup (per vehicle per year)
    static func yearlyRoundupID(for vehicleID: UUID, year: Int) -> String {
        "yearly-roundup-\(vehicleID.uuidString)-\(year)"
    }

    /// Check if yearly roundup was already sent for a specific year
    func hasShownYearlyRoundup(for year: Int, vehicleID: UUID) -> Bool {
        let key = "\(Self.lastYearlyRoundupYearKey)-\(vehicleID.uuidString)"
        return UserDefaults.standard.integer(forKey: key) >= year
    }

    /// Mark yearly roundup as shown for a specific year
    func markYearlyRoundupShown(for year: Int, vehicleID: UUID) {
        let key = "\(Self.lastYearlyRoundupYearKey)-\(vehicleID.uuidString)"
        UserDefaults.standard.set(year, forKey: key)
    }

    /// Build a yearly cost roundup notification request (exposed for testing)
    func buildYearlyRoundupRequest(
        vehicleName: String,
        vehicleID: UUID,
        year: Int,
        totalCost: Decimal,
        notificationDate: Date
    ) -> UNNotificationRequest {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        let formattedCost = formatter.string(from: totalCost as NSDecimalNumber) ?? "$0"

        let content = UNMutableNotificationContent()
        content.title = "Your \(year) Vehicle Costs Are In!"
        content.body = "You spent \(formattedCost) on \(vehicleName) maintenance last year"
        content.sound = .default
        content.categoryIdentifier = Self.yearlyRoundupCategoryID
        content.userInfo = [
            "vehicleID": vehicleID.uuidString,
            "year": year,
            "type": "yearlyRoundup"
        ]

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 10  // 10 AM for yearly roundup
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: Self.yearlyRoundupID(for: vehicleID, year: year),
            content: content,
            trigger: trigger
        )
    }

    /// Schedule yearly cost roundup notification for January 2nd
    /// - Parameters:
    ///   - vehicle: The vehicle to show roundup for
    ///   - previousYearCost: Total cost for the previous year (if > 0)
    ///   - previousYear: The year being summarized
    func scheduleYearlyRoundup(for vehicle: Vehicle, previousYearCost: Decimal, previousYear: Int) {
        // Only send if there's actual cost data
        guard previousYearCost > 0 else { return }

        // Don't send if already sent for this year
        guard !hasShownYearlyRoundup(for: previousYear, vehicleID: vehicle.id) else { return }

        // Calculate January 2nd of the following year
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = previousYear + 1
        dateComponents.month = 1
        dateComponents.day = 2

        guard let notificationDate = calendar.date(from: dateComponents) else { return }

        // Only schedule if date is in the future
        guard notificationDate > Date() else {
            // If we're past Jan 2nd, don't schedule but consider sending immediately
            // via a different mechanism if needed
            return
        }

        let request = buildYearlyRoundupRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            year: previousYear,
            totalCost: previousYearCost,
            notificationDate: notificationDate
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule yearly roundup: \(error)")
            }
        }
    }

    /// Cancel yearly roundup notification for a vehicle
    func cancelYearlyRoundup(for vehicle: Vehicle, year: Int) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.yearlyRoundupID(for: vehicle.id, year: year)]
        )
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
        let notificationType = userInfo["type"] as? String

        // Handle mileage reminder notifications
        if notificationType == "mileageReminder" {
            guard let vehicleIDString = userInfo["vehicleID"] as? String else { return }

            switch response.actionIdentifier {
            case Self.updateMileageActionID, UNNotificationDefaultActionIdentifier:
                // Open mileage update
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .navigateToMileageUpdateFromNotification,
                        object: nil,
                        userInfo: ["vehicleID": vehicleIDString]
                    )
                }

            case Self.remindLaterActionID:
                // Snooze mileage reminder
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .mileageReminderSnoozedFromNotification,
                        object: nil,
                        userInfo: ["vehicleID": vehicleIDString]
                    )
                }

            default:
                break
            }
            return
        }

        // Handle yearly roundup notifications
        if notificationType == "yearlyRoundup" {
            guard let vehicleIDString = userInfo["vehicleID"] as? String,
                  let year = userInfo["year"] as? Int else { return }

            switch response.actionIdentifier {
            case Self.viewCostsActionID, UNNotificationDefaultActionIdentifier:
                // Navigate to costs tab
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .navigateToCostsFromNotification,
                        object: nil,
                        userInfo: ["vehicleID": vehicleIDString, "year": year]
                    )
                }

            default:
                break
            }
            return
        }

        // Handle service due notifications (original behavior)
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

    // Mileage reminder notifications
    static let navigateToMileageUpdateFromNotification = Notification.Name("navigateToMileageUpdateFromNotification")
    static let mileageReminderSnoozedFromNotification = Notification.Name("mileageReminderSnoozedFromNotification")

    // Yearly roundup notifications
    static let navigateToCostsFromNotification = Notification.Name("navigateToCostsFromNotification")
}
