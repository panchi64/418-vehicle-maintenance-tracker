//
//  NotificationService.swift
//  checkpoint
//
//  Core notification service: authorization, categories, and shared singleton
//

import Foundation
import UserNotifications
import SwiftData

/// Core service for managing local notifications for vehicle maintenance reminders
@Observable
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Category Identifiers

    static let serviceDueCategoryID = "SERVICE_DUE"
    static let markDoneActionID = "MARK_DONE"
    static let snoozeActionID = "SNOOZE"

    static let mileageReminderCategoryID = "MILEAGE_REMINDER"
    static let updateMileageActionID = "UPDATE_MILEAGE"
    static let remindLaterActionID = "REMIND_LATER"

    static let yearlyRoundupCategoryID = "YEARLY_ROUNDUP"
    static let viewCostsActionID = "VIEW_COSTS"

    static let marbeteDueCategoryID = "MARBETE_DUE"
    static let marbeteSnoozeActionID = "MARBETE_SNOOZE"

    // MARK: - Reminder Intervals

    /// Marbete reminder intervals (days before expiration)
    static let marbeteReminderIntervals: [Int] = [60, 30, 7, 1]

    /// Mileage reminder interval (14 days)
    static let mileageReminderIntervalDays = 14

    /// Default reminder intervals (days before due date)
    static let defaultReminderIntervals: [Int] = [30, 7, 1, 0]

    /// Notification ID suffixes for each interval
    static func intervalSuffix(for days: Int) -> String {
        switch days {
        case 0: return "-due"
        case 1: return "-1d"
        case 7: return "-7d"
        case 30: return "-30d"
        default: return "-\(days)d"
        }
    }

    // MARK: - Initialization

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
            self.isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Notification Categories & Actions

    private func setupNotificationCategories() {
        // Service due category
        let serviceDueCategory = UNNotificationCategory(
            identifier: Self.serviceDueCategoryID,
            actions: [
                UNNotificationAction(identifier: Self.markDoneActionID, title: "Mark as Done", options: [.foreground]),
                UNNotificationAction(identifier: Self.snoozeActionID, title: "Remind Tomorrow", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        // Mileage reminder category
        let mileageReminderCategory = UNNotificationCategory(
            identifier: Self.mileageReminderCategoryID,
            actions: [
                UNNotificationAction(identifier: Self.updateMileageActionID, title: "Update Now", options: [.foreground]),
                UNNotificationAction(identifier: Self.remindLaterActionID, title: "Remind Tomorrow", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        // Yearly roundup category
        let yearlyRoundupCategory = UNNotificationCategory(
            identifier: Self.yearlyRoundupCategoryID,
            actions: [
                UNNotificationAction(identifier: Self.viewCostsActionID, title: "View Costs", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        // Marbete due category
        let marbeteDueCategory = UNNotificationCategory(
            identifier: Self.marbeteDueCategoryID,
            actions: [
                UNNotificationAction(identifier: Self.marbeteSnoozeActionID, title: "Remind Tomorrow", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            serviceDueCategory,
            mileageReminderCategory,
            yearlyRoundupCategory,
            marbeteDueCategory
        ])
    }

    // MARK: - Cancel All Notifications

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
