//
//  NotificationNames.swift
//  checkpoint
//
//  Notification.Name extensions for notification-related events
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    // Service notifications
    static let serviceMarkedDoneFromNotification = Notification.Name("serviceMarkedDoneFromNotification")
    static let serviceSnoozedFromNotification = Notification.Name("serviceSnoozedFromNotification")
    static let navigateToServiceFromNotification = Notification.Name("navigateToServiceFromNotification")

    // Mileage reminder notifications
    static let navigateToMileageUpdateFromNotification = Notification.Name("navigateToMileageUpdateFromNotification")
    static let mileageReminderSnoozedFromNotification = Notification.Name("mileageReminderSnoozedFromNotification")

    // Yearly roundup notifications
    static let navigateToCostsFromNotification = Notification.Name("navigateToCostsFromNotification")

    // Marbete reminder notifications
    static let marbeteReminderSnoozedFromNotification = Notification.Name("marbeteReminderSnoozedFromNotification")
    static let navigateToEditVehicleFromNotification = Notification.Name("navigateToEditVehicleFromNotification")
}
