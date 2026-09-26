//
//  L10n+Appointments.swift
//  checkpoint
//
//  Strings for shop appointments outside the views: reminder banners
//  (docs/NOTIFICATION_TONE.md) and the names Siri and the Calendar schema
//  see. `appointment.` / `notification.appointment.` keys.
//

import Foundation

extension L10n {
    /// What an appointment is called when no shop was entered (only ever
    /// true for one synced from an unexpected writer; the form requires one).
    nonisolated static var appointmentShopFallback: String {
        NSLocalizedString("appointment.shopFallback", comment: "")
    }

    /// "Services: Oil Change and Tire Rotation" — the last line of a
    /// Calendar-schema event note.
    nonisolated static func appointmentEventServicesLine(_ services: String) -> String {
        String(format: NSLocalizedString("appointment.eventServicesLine", comment: ""), services)
    }

    // MARK: - Reminder banners

    static var notificationAppointmentTitleTomorrow: String {
        NSLocalizedString("notification.appointment.title.tomorrow", comment: "")
    }
    static var notificationAppointmentTitleHour: String {
        NSLocalizedString("notification.appointment.title.hour", comment: "")
    }
    /// Vehicle, shop, time.
    static func notificationAppointmentBodyTomorrow(_ vehicle: String, _ shop: String, _ time: String) -> String {
        String(format: NSLocalizedString("notification.appointment.body.tomorrow", comment: ""), vehicle, shop, time)
    }
    /// Vehicle, shop, time.
    static func notificationAppointmentBodyHour(_ vehicle: String, _ shop: String, _ time: String) -> String {
        String(format: NSLocalizedString("notification.appointment.body.hour", comment: ""), vehicle, shop, time)
    }
}
