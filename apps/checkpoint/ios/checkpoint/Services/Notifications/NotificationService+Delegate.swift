//
//  NotificationService+Delegate.swift
//  checkpoint
//
//  UNUserNotificationCenterDelegate implementation for handling notification responses
//

import Foundation
import UserNotifications

// MARK: - UNUserNotificationCenterDelegate

@MainActor
extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Mark a foreground-presented yearly roundup as shown so the dedup
        // guard in scheduleYearlyRoundup actually holds (it is otherwise only
        // ever marked on tap).
        markYearlyRoundupShownIfNeeded(notification.request.content.userInfo)
        // No .badge: nothing sets or clears the app icon badge.
        return [.banner, .sound]
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
            await handleMileageReminderResponse(response, userInfo: userInfo)
            return
        }

        // Handle yearly roundup notifications
        if notificationType == "yearlyRoundup" {
            await handleYearlyRoundupResponse(response, userInfo: userInfo)
            return
        }

        // Handle marbete reminder notifications
        if notificationType == "marbeteReminder" {
            await handleMarbeteReminderResponse(response, userInfo: userInfo)
            return
        }

        // Handle service due notifications (default)
        await handleServiceDueResponse(response, userInfo: userInfo)
    }

    // MARK: - Response Handlers

    private func handleMileageReminderResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let vehicleIDString = userInfo["vehicleID"] as? String else { return }

        switch response.actionIdentifier {
        case Self.updateMileageActionID, UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(
                name: .navigateToMileageUpdateFromNotification,
                object: nil,
                userInfo: ["vehicleID": vehicleIDString]
            )

        case Self.remindLaterActionID:
            NotificationCenter.default.post(
                name: .mileageReminderSnoozedFromNotification,
                object: nil,
                userInfo: ["vehicleID": vehicleIDString]
            )

        default:
            break
        }
    }

    private func handleYearlyRoundupResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let vehicleIDString = userInfo["vehicleID"] as? String,
              let year = userInfo["year"] as? Int else { return }

        // The roundup reached the user; record it so it isn't scheduled again.
        markYearlyRoundupShownIfNeeded(userInfo)

        switch response.actionIdentifier {
        case Self.viewCostsActionID, UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(
                name: .navigateToCostsFromNotification,
                object: nil,
                userInfo: ["vehicleID": vehicleIDString, "year": year]
            )

        default:
            break
        }
    }

    /// Persist that a vehicle's yearly roundup for a given year has reached the
    /// user (presented in-foreground or tapped) so `scheduleYearlyRoundup`'s
    /// `hasShownYearlyRoundup` guard can actually suppress a repeat. No-op for
    /// any other notification type.
    private func markYearlyRoundupShownIfNeeded(_ userInfo: [AnyHashable: Any]) {
        guard userInfo["type"] as? String == "yearlyRoundup",
              let vehicleIDString = userInfo["vehicleID"] as? String,
              let vehicleID = UUID(uuidString: vehicleIDString),
              let year = userInfo["year"] as? Int else { return }
        markYearlyRoundupShown(for: year, vehicleID: vehicleID)
    }

    private func handleMarbeteReminderResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let vehicleIDString = userInfo["vehicleID"] as? String else { return }

        switch response.actionIdentifier {
        case Self.marbeteSnoozeActionID:
            NotificationCenter.default.post(
                name: .marbeteReminderSnoozedFromNotification,
                object: nil,
                userInfo: ["vehicleID": vehicleIDString]
            )

        case UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(
                name: .navigateToEditVehicleFromNotification,
                object: nil,
                userInfo: ["vehicleID": vehicleIDString]
            )

        default:
            break
        }
    }

    private func handleServiceDueResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let serviceIDString = userInfo["serviceID"] as? String,
              let _ = userInfo["vehicleID"] as? String else { return }

        switch response.actionIdentifier {
        case Self.markDoneActionID:
            NotificationCenter.default.post(
                name: .serviceMarkedDoneFromNotification,
                object: nil,
                userInfo: ["serviceID": serviceIDString]
            )

        case Self.snoozeActionID:
            NotificationCenter.default.post(
                name: .serviceSnoozedFromNotification,
                object: nil,
                userInfo: ["serviceID": serviceIDString]
            )

        case UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(
                name: .navigateToServiceFromNotification,
                object: nil,
                userInfo: ["serviceID": serviceIDString]
            )

        default:
            break
        }
    }
}
