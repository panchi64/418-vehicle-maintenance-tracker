//
//  AppointmentService.swift
//  checkpoint
//
//  The one write path for appointments: the form, Siri, and the iOS 27
//  Calendar schema all book, move, cancel and complete through here, so a
//  change made anywhere leaves the same state — saved fields, reminders
//  rescheduled, Spotlight following.
//
//  Completing doesn't write a service record by itself. The record is the
//  visit the user confirms in the service form (`AppointmentCompletion`); this
//  only closes the appointment once that is saved.
//

import Foundation
import SwiftData

/// Every value a user can write to an appointment, as plain values.
nonisolated struct AppointmentFields: Equatable, Sendable {
    var shopName = ""
    var startDate: Date
    var endDate: Date?
    var address = ""
    var latitude: Double?
    var longitude: Double?
    var note = ""
    var serviceIDs: [UUID] = []

    /// The default for a new booking: tomorrow at 9:00.
    static func newBooking(now: Date = .now, calendar: Calendar = .current, serviceIDs: [UUID] = []) -> AppointmentFields {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        return AppointmentFields(startDate: start, serviceIDs: serviceIDs)
    }

    /// The values `appointment` holds now.
    @MainActor
    init(appointment: Appointment) {
        self.init(
            shopName: appointment.shopName,
            startDate: appointment.startDate,
            endDate: appointment.endDate,
            address: appointment.address ?? "",
            latitude: appointment.latitude,
            longitude: appointment.longitude,
            note: appointment.note ?? "",
            serviceIDs: appointment.sortedServices.map(\.id)
        )
    }

    init(
        shopName: String = "",
        startDate: Date,
        endDate: Date? = nil,
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String = "",
        serviceIDs: [UUID] = []
    ) {
        self.shopName = shopName
        self.startDate = startDate
        self.endDate = endDate
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.serviceIDs = serviceIDs
    }

    /// A booking needs a shop — it is how the appointment is named
    /// everywhere, and what Maps searches when no address is on file.
    var isValid: Bool {
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Move the visit to start at `start`, keeping its length.
    mutating func move(to start: Date) {
        if let end = endDate, end > startDate {
            endDate = start.addingTimeInterval(end.timeIntervalSince(startDate))
        }
        startDate = start
    }
}

@MainActor
enum AppointmentService {

    /// Book a visit on `vehicle`. Only services of that vehicle link.
    @discardableResult
    static func schedule(
        _ fields: AppointmentFields,
        on vehicle: Vehicle,
        in context: ModelContext
    ) -> Appointment {
        let appointment = Appointment(vehicle: vehicle, startDate: fields.startDate, shopName: "")
        context.insert(appointment)
        apply(fields, to: appointment)
        AppointmentNotificationScheduler.schedule(for: appointment)
        return appointment
    }

    /// Write `fields` over `appointment` and move its reminders.
    static func update(_ appointment: Appointment, with fields: AppointmentFields) {
        apply(fields, to: appointment)
        AppointmentNotificationScheduler.schedule(for: appointment)
    }

    /// Move a visit to a new time, keeping its length.
    static func reschedule(_ appointment: Appointment, to start: Date) {
        var fields = AppointmentFields(appointment: appointment)
        fields.move(to: start)
        update(appointment, with: fields)
    }

    /// Cancel a visit. Kept, not deleted: it syncs as cancelled, and the
    /// Calendar schema reports it with status `cancelled`.
    static func cancel(_ appointment: Appointment, now: Date = .now) {
        appointment.status = .cancelled
        appointment.closedAt = now
        AppointmentNotificationScheduler.cancel(appointmentID: appointment.id)
    }

    /// Close a visit once its service record is saved.
    static func markCompleted(_ appointment: Appointment, now: Date = .now) {
        appointment.status = .completed
        appointment.closedAt = now
        AppointmentNotificationScheduler.cancel(appointmentID: appointment.id)
    }

    /// Remove a visit for good (the form's Delete, for a cancelled one).
    static func delete(_ appointment: Appointment, in context: ModelContext) {
        AppointmentNotificationScheduler.cancel(appointmentID: appointment.id)
        context.delete(appointment)
    }

    private static func apply(_ fields: AppointmentFields, to appointment: Appointment) {
        appointment.shopName = fields.shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.startDate = fields.startDate
        appointment.endDate = fields.endDate.flatMap { $0 > fields.startDate ? $0 : nil }
        let address = fields.address.trimmingCharacters(in: .whitespacesAndNewlines)
        // Editing the address without a new place invalidates the resolved
        // coordinate: it pointed at the old address.
        let addressChanged = address != (appointment.address ?? "")
        let sameCoordinate = fields.latitude == appointment.latitude && fields.longitude == appointment.longitude
        let keepsCoordinate = fields.latitude != nil && fields.longitude != nil && !(addressChanged && sameCoordinate)
        appointment.latitude = keepsCoordinate ? fields.latitude : nil
        appointment.longitude = keepsCoordinate ? fields.longitude : nil
        appointment.address = address.isEmpty ? nil : address
        let note = fields.note.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.note = note.isEmpty ? nil : note

        let wanted = Set(fields.serviceIDs)
        appointment.services = (appointment.vehicle?.services ?? []).filter { wanted.contains($0.id) }
    }
}
