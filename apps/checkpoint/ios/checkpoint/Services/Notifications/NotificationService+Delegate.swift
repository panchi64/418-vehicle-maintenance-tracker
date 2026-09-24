//
//  NotificationService+Delegate.swift
//  checkpoint
//
//  UNUserNotificationCenterDelegate implementation for handling notification responses
//

import Foundation
import UserNotifications
import os

private let notificationDelegateLogger = Logger(category: "Notifications.Delegate")

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

    // MARK: - Snooze

    /// Register a Remind Tomorrow request here, in the delegate, rather than
    /// posting for the UI to handle. The action runs without opening the app,
    /// so there may be no scene to receive a post — which is how both snooze
    /// buttons came to do nothing.
    private func addSnooze(_ request: UNNotificationRequest?) async {
        guard let request else { return }
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            notificationDelegateLogger.error("Failed to snooze notification: \(error.localizedDescription)")
        }
        scheduleBudgetEnforcement()
    }

    // MARK: - Response Handlers

    private func handleMileageReminderResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let vehicleID = Self.vehicleID(in: userInfo) else { return }

        switch response.actionIdentifier {
        case Self.updateMileageActionID, UNNotificationDefaultActionIdentifier:
            pendingRoute = .updateMileage(vehicleID: vehicleID)

        case Self.remindLaterActionID:
            await addSnooze(MileageReminderScheduler.snoozeRequest(for: response.notification.request))

        default:
            break
        }
    }

    private func handleYearlyRoundupResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let vehicleID = Self.vehicleID(in: userInfo) else { return }

        // The roundup reached the user; record it so it isn't scheduled again.
        markYearlyRoundupShownIfNeeded(userInfo)

        switch response.actionIdentifier {
        case Self.viewCostsActionID, UNNotificationDefaultActionIdentifier:
            pendingRoute = .costs(vehicleID: vehicleID)

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
        guard let vehicleID = Self.vehicleID(in: userInfo) else { return }

        switch response.actionIdentifier {
        case Self.marbeteSnoozeActionID:
            await addSnooze(MarbeteNotificationScheduler.snoozeRequest(for: response.notification.request))

        case UNNotificationDefaultActionIdentifier:
            pendingRoute = .editVehicle(vehicleID: vehicleID)

        default:
            break
        }
    }

    /// A service reminder covers every service that came due at the same lead
    /// time on the same day, so the payload is a *set*. `serviceIDs` is always
    /// present and always complete; `serviceID` is carried only when the set
    /// has one member, so a handler that acts on a single service can tell the
    /// difference instead of picking an arbitrary member of a bundle.
    private func handleServiceDueResponse(
        _ response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) async {
        let serviceIDs = NotificationRoute.serviceIDs(from: ServiceNotificationScheduler.referencedServiceIDs(in: userInfo))
        guard !serviceIDs.isEmpty, let vehicleID = Self.vehicleID(in: userInfo) else { return }

        switch response.actionIdentifier {
        case Self.markDoneActionID:
            pendingRoute = .markDone(vehicleID: vehicleID, serviceIDs: serviceIDs)

        case Self.snoozeActionID:
            await addSnooze(ServiceNotificationScheduler.snoozeRequest(for: response.notification.request))

        case UNNotificationDefaultActionIdentifier:
            pendingRoute = .services(vehicleID: vehicleID, serviceIDs: serviceIDs)

        default:
            break
        }
    }

    private static func vehicleID(in userInfo: [AnyHashable: Any]) -> UUID? {
        (userInfo["vehicleID"] as? String).flatMap(UUID.init(uuidString:))
    }
}
