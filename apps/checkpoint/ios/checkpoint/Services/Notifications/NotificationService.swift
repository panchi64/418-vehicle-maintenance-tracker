//
//  NotificationService.swift
//  checkpoint
//
//  Core notification service: authorization, categories, and shared singleton
//

import Foundation
import UserNotifications
import SwiftData
import os

private let notificationLogger = Logger(category: "Notifications")

/// Core service for managing local notifications for vehicle maintenance reminders
@Observable
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Pending debounce task for a coalesced budget enforcement. Replaced
    /// (cancel-and-replace) on each `scheduleBudgetEnforcement()` so a burst of
    /// scheduling calls trims once, after the burst settles.
    @ObservationIgnored private(set) var budgetEnforcementTask: Task<Void, Never>?

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

    /// Debounce window before a coalesced mid-session budget enforcement runs.
    static let budgetEnforcementDebounce: Duration = .seconds(2)

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
            // No .badge: the app never sets content.badge or clears the icon
            // badge, so requesting it would over-ask for an unused capability.
            let options: UNAuthorizationOptions = [.alert, .sound]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            self.isAuthorized = granted
            return granted
        } catch {
            notificationLogger.error("Notification authorization error: \(error.localizedDescription)")
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

    // MARK: - Budget Enforcement

    /// Debounced trim of the pending set back under the OS's 64-request cap.
    /// Every mid-session add (a service edit, or a marbete/mileage/roundup
    /// schedule or snooze) can push the pending total past 64, at which point
    /// iOS silently keeps only the 64 soonest — potentially evicting a nearer
    /// reminder. Only the launch sweep enforced the budget before, so each
    /// scheduling entry point calls this; a burst coalesces into a single
    /// enforcement `budgetEnforcementDebounce` after the last call.
    func scheduleBudgetEnforcement() {
        budgetEnforcementTask?.cancel()
        budgetEnforcementTask = Task {
            try? await Task.sleep(for: Self.budgetEnforcementDebounce)
            guard !Task.isCancelled else { return }
            await NotificationHelpers.enforcePendingBudget()
        }
    }

    // MARK: - Cancel All Notifications

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
