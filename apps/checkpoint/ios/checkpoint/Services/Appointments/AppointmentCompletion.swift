//
//  AppointmentCompletion.swift
//  checkpoint
//
//  What "Log Visit" on an appointment opens, and with what. The appointment
//  already knows the shop, the day and the services, so the service form
//  starts from them instead of from blank — the user adds the odometer and
//  the total, and saves. Saving writes through the form's own path
//  (`ServiceVisitWriter` / `LoggedServiceWriter`); the appointment only
//  closes afterwards (`AppointmentService.markCompleted`).
//

import Foundation

struct AppointmentCompletion {
    /// Which form opens.
    enum Form {
        /// Linked services: one visit completing all of them
        /// (`ClusterDoneForm`), with one total.
        case visit([Service])
        /// No linked services: the service form's log door, to pick what
        /// was done.
        case log
    }

    let form: Form
    let performedDate: Date
    let shopName: String?

    /// The prefill for completing `appointment`. The date is the
    /// appointment's day, or today when it is completed ahead of time (a
    /// log can't be dated in the future). Services the vehicle no longer
    /// tracks drop out.
    @MainActor
    init(appointment: Appointment, now: Date = .now) {
        let tracked = Set((appointment.vehicle?.services ?? []).map(\.id))
        let services = appointment.sortedServices.filter { tracked.contains($0.id) }
        form = services.isEmpty ? .log : .visit(services)
        performedDate = min(appointment.startDate, now)
        shopName = appointment.trimmedShopName
    }

    /// The prefill a visit form reads.
    var visitPrefill: VisitPrefill {
        VisitPrefill(performedDate: performedDate, shopName: shopName)
    }
}

/// Values a completion form starts from instead of its defaults.
struct VisitPrefill: Equatable {
    var performedDate: Date
    var shopName: String?
}
