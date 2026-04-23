//
//  NotificationService+Scheduling.swift
//  checkpoint
//
//  Backwards compatibility methods that delegate to the scheduler structs
//

import Foundation
import UserNotifications

// MARK: - Service Notification Scheduling (Backwards Compatibility)

@MainActor
extension NotificationService {

    // MARK: - Build Requests

    func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        notificationDate: Date,
        daysBeforeDue: Int = 0
    ) -> UNNotificationRequest {
        ServiceNotificationScheduler.buildNotificationRequest(
            for: service, vehicle: vehicle, notificationID: notificationID,
            notificationDate: notificationDate, daysBeforeDue: daysBeforeDue
        )
    }

    func buildNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        dueDate: Date
    ) -> UNNotificationRequest {
        ServiceNotificationScheduler.buildNotificationRequest(
            for: service, vehicle: vehicle, notificationID: notificationID, dueDate: dueDate
        )
    }

    func buildSnoozeNotificationRequest(
        for service: Service,
        vehicle: Vehicle,
        notificationID: String,
        snoozeDate: Date
    ) -> UNNotificationRequest {
        ServiceNotificationScheduler.buildSnoozeNotificationRequest(
            for: service, vehicle: vehicle, notificationID: notificationID, snoozeDate: snoozeDate
        )
    }

    // MARK: - Schedule/Cancel/Snooze

    @discardableResult
    func scheduleNotification(for service: Service, vehicle: Vehicle) -> String? {
        ServiceNotificationScheduler.scheduleNotification(for: service, vehicle: vehicle)
    }

    func scheduleNotifications(for vehicle: Vehicle) {
        ServiceNotificationScheduler.scheduleNotifications(for: vehicle)
    }

    @discardableResult
    func scheduleNotificationWithPace(for service: Service, vehicle: Vehicle, dailyPace: Double? = nil) -> String? {
        ServiceNotificationScheduler.scheduleNotificationWithPace(for: service, vehicle: vehicle, dailyPace: dailyPace)
    }

    func rescheduleNotifications(for vehicle: Vehicle) {
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
    }

    func cancelNotification(id: String) {
        ServiceNotificationScheduler.cancelNotification(id: id)
    }

    func cancelAllNotifications(baseID: String) {
        ServiceNotificationScheduler.cancelAllNotifications(baseID: baseID)
    }

    func cancelNotification(for service: Service) {
        ServiceNotificationScheduler.cancelNotification(for: service)
    }

    func cancelNotifications(for vehicle: Vehicle) {
        ServiceNotificationScheduler.cancelNotifications(for: vehicle)
    }

    func snoozeNotification(for service: Service, vehicle: Vehicle) {
        ServiceNotificationScheduler.snoozeNotification(for: service, vehicle: vehicle)
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await ServiceNotificationScheduler.getPendingNotifications()
    }

    func hasPendingNotification(for service: Service) async -> Bool {
        await ServiceNotificationScheduler.hasPendingNotification(for: service)
    }
}

// MARK: - Mileage Reminder Scheduling (Backwards Compatibility)

@MainActor
extension NotificationService {
    static func mileageReminderID(for vehicleID: UUID) -> String {
        MileageReminderScheduler.mileageReminderID(for: vehicleID)
    }

    func buildMileageReminderRequest(vehicleName: String, vehicleID: UUID, reminderDate: Date) -> UNNotificationRequest {
        MileageReminderScheduler.buildMileageReminderRequest(vehicleName: vehicleName, vehicleID: vehicleID, reminderDate: reminderDate)
    }

    func scheduleMileageReminder(for vehicle: Vehicle, lastUpdateDate: Date = .now) {
        MileageReminderScheduler.scheduleMileageReminder(for: vehicle, lastUpdateDate: lastUpdateDate)
    }

    func cancelMileageReminder(for vehicle: Vehicle) {
        MileageReminderScheduler.cancelMileageReminder(for: vehicle)
    }

    func snoozeMileageReminder(for vehicle: Vehicle) {
        MileageReminderScheduler.snoozeMileageReminder(for: vehicle)
    }
}

// MARK: - Yearly Roundup Scheduling (Backwards Compatibility)

@MainActor
extension NotificationService {
    static func yearlyRoundupID(for vehicleID: UUID, year: Int) -> String {
        YearlyRoundupScheduler.yearlyRoundupID(for: vehicleID, year: year)
    }

    func hasShownYearlyRoundup(for year: Int, vehicleID: UUID) -> Bool {
        YearlyRoundupScheduler.hasShownYearlyRoundup(for: year, vehicleID: vehicleID)
    }

    func markYearlyRoundupShown(for year: Int, vehicleID: UUID) {
        YearlyRoundupScheduler.markYearlyRoundupShown(for: year, vehicleID: vehicleID)
    }

    func buildYearlyRoundupRequest(vehicleName: String, vehicleID: UUID, year: Int, totalCost: Decimal, notificationDate: Date) -> UNNotificationRequest {
        YearlyRoundupScheduler.buildYearlyRoundupRequest(vehicleName: vehicleName, vehicleID: vehicleID, year: year, totalCost: totalCost, notificationDate: notificationDate)
    }

    func scheduleYearlyRoundup(for vehicle: Vehicle, previousYearCost: Decimal, previousYear: Int) {
        YearlyRoundupScheduler.scheduleYearlyRoundup(for: vehicle, previousYearCost: previousYearCost, previousYear: previousYear)
    }

    func cancelYearlyRoundup(for vehicle: Vehicle, year: Int) {
        YearlyRoundupScheduler.cancelYearlyRoundup(for: vehicle, year: year)
    }
}

// MARK: - Marbete Notification Scheduling (Backwards Compatibility)

@MainActor
extension NotificationService {
    static func marbeteReminderID(for vehicleID: UUID, daysBeforeDue: Int) -> String {
        MarbeteNotificationScheduler.marbeteReminderID(for: vehicleID, daysBeforeDue: daysBeforeDue)
    }

    static func marbeteBaseID(for vehicleID: UUID) -> String {
        MarbeteNotificationScheduler.marbeteBaseID(for: vehicleID)
    }

    func buildMarbeteNotificationRequest(vehicleName: String, vehicleID: UUID, notificationDate: Date, daysBeforeDue: Int) -> UNNotificationRequest {
        MarbeteNotificationScheduler.buildMarbeteNotificationRequest(vehicleName: vehicleName, vehicleID: vehicleID, notificationDate: notificationDate, daysBeforeDue: daysBeforeDue)
    }

    @discardableResult
    func scheduleMarbeteNotifications(for vehicle: Vehicle) -> String? {
        MarbeteNotificationScheduler.scheduleMarbeteNotifications(for: vehicle)
    }

    func cancelMarbeteNotifications(for vehicle: Vehicle) {
        MarbeteNotificationScheduler.cancelMarbeteNotifications(for: vehicle)
    }

    func snoozeMarbeteReminder(for vehicle: Vehicle) {
        MarbeteNotificationScheduler.snoozeMarbeteReminder(for: vehicle)
    }
}
