//
//  L10n+AppointmentViews.swift
//  checkpoint
//
//  On-screen strings for shop appointments: Home's Shop Visit section and
//  the appointment sheet. `appointment.` / `home.shopVisit` keys.
//

import Foundation

extension L10n {
    private static func appointment(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Home

    static var homeShopVisit: String { appointment("home.shopVisit") }
    static var homeShopVisitEmpty: String { appointment("home.shopVisit.empty") }
    static var appointmentBook: String { appointment("appointment.book") }
    static var appointmentEditHint: String { appointment("appointment.editHint") }
    static var appointmentDirections: String { appointment("appointment.directions") }
    static var appointmentDirectionsFailed: String { appointment("appointment.directionsFailed") }
    static var appointmentLogVisit: String { appointment("appointment.logVisit") }
    /// "Oct 9, 10:00 AM · Midas" — when, shop.
    static func appointmentRowLine(_ when: String, _ shop: String) -> String {
        String(format: appointment("appointment.rowLine"), when, shop)
    }
    static var appointmentTimingTomorrow: String { appointment("appointment.timing.tomorrow") }
    static func appointmentTimingInDays(_ days: Int) -> String {
        String(format: appointment("appointment.timing.inDays"), days)
    }
    static var appointmentTimingToday: String { appointment("appointment.timing.today") }
    static var appointmentTimingNotLogged: String { appointment("appointment.timing.notLogged") }

    // MARK: - Sheet

    static var appointmentFormTitleNew: String { appointment("appointment.form.titleNew") }
    static var appointmentFormTitleEdit: String { appointment("appointment.form.titleEdit") }
    static var appointmentShop: String { appointment("appointment.shop") }
    static var appointmentShopPlaceholder: String { appointment("appointment.shop.placeholder") }
    static var appointmentShopRequired: String { appointment("appointment.shop.required") }
    static var appointmentShopSuggestionHint: String { appointment("appointment.shop.suggestionHint") }
    static var appointmentWhen: String { appointment("appointment.when") }
    /// "You already have Midas booked at 10:00 AM that day." — shop, time.
    static func appointmentSameDayCaution(_ shop: String, _ time: String) -> String {
        String(format: appointment("appointment.sameDayCaution"), shop, time)
    }
    static var appointmentReminders: String { appointment("appointment.reminders") }
    static var appointmentRemindersNone: String { appointment("appointment.reminders.none") }
    static var appointmentServices: String { appointment("appointment.services") }
    static var appointmentServicesEmpty: String { appointment("appointment.services.empty") }
    static var appointmentAddress: String { appointment("appointment.address") }
    static var appointmentAddressPlaceholder: String { appointment("appointment.address.placeholder") }
    static var appointmentNote: String { appointment("appointment.note") }
    static var appointmentNotePlaceholder: String { appointment("appointment.note.placeholder") }
    static var appointmentCancelAction: String { appointment("appointment.cancel") }
    static var appointmentKeepAction: String { appointment("appointment.keep") }
    static var appointmentCancelConfirmTitle: String { appointment("appointment.cancel.confirmTitle") }
    static var appointmentCancelConfirmMessage: String { appointment("appointment.cancel.confirmMessage") }
    static var appointmentToastBooked: String { appointment("appointment.toast.booked") }
    static var appointmentToastUpdated: String { appointment("appointment.toast.updated") }
    static var appointmentToastCancelled: String { appointment("appointment.toast.cancelled") }
}
