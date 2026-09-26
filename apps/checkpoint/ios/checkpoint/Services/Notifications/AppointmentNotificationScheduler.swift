//
//  AppointmentNotificationScheduler.swift
//  checkpoint
//
//  Reminders for a booked shop visit: the day before and an hour before
//  (`Appointment.reminderDates`). Voice per docs/NOTIFICATION_TONE.md — a
//  functional status title, the vehicle speaking in the body.
//
//  IDs are deterministic per appointment and lead ("appointment-<id>-1d"), so
//  rescheduling replaces rather than stacks, and every device computes the
//  same set from synced data. Tapping one opens the appointment
//  (`PendingRoute.appointment`). On iOS 27 the banner is tagged with the
//  appointment and vehicle entities.
//

import Foundation
import UserNotifications
import os

private let appointmentNotificationLogger = Logger(category: "Notifications.Appointment")

@MainActor
enum AppointmentNotificationScheduler {

    nonisolated static let requestPrefix = "appointment-"
    nonisolated static let userInfoType = "appointmentReminder"

    nonisolated static func requestID(appointmentID: UUID, lead: Appointment.ReminderLead) -> String {
        "\(requestPrefix)\(appointmentID.uuidString)-\(lead.rawValue)"
    }

    nonisolated static func requestIDs(appointmentID: UUID) -> [String] {
        Appointment.ReminderLead.allCases.map { requestID(appointmentID: appointmentID, lead: $0) }
    }

    /// The requests a scheduled appointment should have pending now. Empty
    /// for one that is cancelled, completed, orphaned or already past.
    static func requests(for appointment: Appointment, now: Date = .now) -> [UNNotificationRequest] {
        guard appointment.isScheduled, let vehicle = appointment.vehicle else { return [] }
        let time = appointment.startDate.formatted(date: .omitted, time: .shortened)
        let shop = appointment.trimmedShopName ?? L10n.appointmentShopFallback

        return Appointment.reminderDates(for: appointment.startDate, now: now)
            .sorted { $0.value < $1.value }
            .map { lead, fireDate in
                let content = UNMutableNotificationContent()
                switch lead {
                case .dayBefore:
                    content.title = L10n.notificationAppointmentTitleTomorrow
                    content.body = L10n.notificationAppointmentBodyTomorrow(vehicle.displayName, shop, time)
                case .hourBefore:
                    content.title = L10n.notificationAppointmentTitleHour
                    content.body = L10n.notificationAppointmentBodyHour(vehicle.displayName, shop, time)
                }
                content.sound = .default
                content.userInfo = [
                    "type": userInfoType,
                    "vehicleID": vehicle.id.uuidString,
                    "appointmentID": appointment.id.uuidString,
                ]
                content.tagEntities(appointmentID: appointment.id, vehicleID: vehicle.id)

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: fireDate
                )
                return UNNotificationRequest(
                    identifier: requestID(appointmentID: appointment.id, lead: lead),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
            }
    }

    /// Replace `appointment`'s pending reminders with what it needs now.
    static func schedule(for appointment: Appointment, now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: requestIDs(appointmentID: appointment.id))
        for request in requests(for: appointment, now: now) {
            center.add(request) { error in
                if let error {
                    appointmentNotificationLogger.error("Failed to schedule appointment reminder: \(error.localizedDescription)")
                }
            }
        }
        NotificationService.shared.scheduleBudgetEnforcement()
    }

    static func cancel(appointmentID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: requestIDs(appointmentID: appointmentID)
        )
    }

    /// Whether a pending request belongs to an appointment that is no
    /// longer scheduled on this device (deleted, cancelled, completed, or
    /// removed with its vehicle — possibly on another device).
    nonisolated static func isOrphaned(identifier: String, scheduledIDs: Set<UUID>) -> Bool {
        guard identifier.hasPrefix(requestPrefix) else { return false }
        let idString = identifier.dropFirst(requestPrefix.count).prefix(36)
        guard let id = UUID(uuidString: String(idString)) else { return true }
        return !scheduledIDs.contains(id)
    }

    /// Launch pass: drop orphans, then reschedule every scheduled visit so
    /// banners pick up renames and moves synced from other devices.
    static func performLaunchMaintenance(for vehicles: [Vehicle]) async {
        let scheduled = vehicles.flatMap { Appointment.scheduled($0.appointments ?? []) }
        let scheduledIDs = Set(scheduled.map(\.id))
        let center = UNUserNotificationCenter.current()
        let orphans = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { isOrphaned(identifier: $0, scheduledIDs: scheduledIDs) }
        if !orphans.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: orphans)
        }
        for appointment in scheduled {
            schedule(for: appointment)
        }
    }
}
