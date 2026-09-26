//
//  CalendarIntents.swift
//  checkpoint
//
//  The iOS 27 Calendar schema intents over `AppointmentEventEntity`. Each
//  writes through the path its iOS 26 twin uses — `ScheduleAppointmentIntent.
//  book`, `AppointmentService.update`, `CancelAppointmentIntent.cancel` — and
//  asks before the same thing: deleting an event cancels the visit, and asks
//  first. All three overlap the iOS 26 intents, so they are `isAssistantOnly`
//  and Shortcuts lists each action once.
//
//  Recurrence, all-day, attendees and spans are accepted and ignored: a shop
//  visit is one timed occurrence with nobody to invite.
//

import AppIntents
import SwiftData

// MARK: - Create

@available(iOS 27, *)
@AppIntent(schema: .calendar.createEvent)
struct CreateAppointmentEventIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var title: String
    var startDate: Date
    var endDate: Date?
    var location: AppointmentLocation?
    var calendar: VehicleCalendarEntity
    var isAllDay: Bool
    var recurrence: Calendar.RecurrenceRule?
    var attendees: [NoAttendeeEntity]
    var note: AttributedString?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AppointmentEventEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(id: calendar.id, in: context)
        let fields = CalendarMapping.fields(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            note: note.map { String($0.characters) },
            on: vehicle
        )
        let appointment = try ScheduleAppointmentIntent.book(fields, on: vehicle, in: context)
        return .result(
            value: AppointmentEventEntity(model: appointment),
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentBooked(
                vehicle: vehicle.displayName,
                shop: appointment.shopName,
                date: SpokenValue.date(appointment.startDate),
                time: SpokenValue.time(appointment.startDate)
            ))
        )
    }
}

// MARK: - Update

@available(iOS 27, *)
@AppIntent(schema: .calendar.updateEvent)
struct UpdateAppointmentEventIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var event: AppointmentEventEntity
    var title: String?
    var attendees: [NoAttendeeEntity]?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool?
    var calendar: VehicleCalendarEntity?
    var recurrence: Calendar.RecurrenceRule?
    var note: String?
    var location: AppointmentLocation?
    var span: AppointmentEventSpan?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AppointmentEventEntity> & ProvidesDialog {
        let context = container.mainContext
        let appointment = try IntentStore.scheduledAppointment(id: event.id, in: context)
        if let calendar, calendar.id != appointment.vehicle?.id { throw IntentError.appointmentCannotMove }
        Self.apply(
            title: title,
            startDate: startDate,
            endDate: endDate,
            note: note,
            location: location,
            to: appointment
        )
        try AppointmentResolution.commit(appointment, in: context)
        return .result(
            value: AppointmentEventEntity(model: appointment),
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentMoved(
                vehicle: appointment.vehicle?.displayName ?? "",
                shop: appointment.shopName,
                date: SpokenValue.date(appointment.startDate),
                time: SpokenValue.time(appointment.startDate)
            ))
        )
    }

    /// The write: only the fields Siri gave change. A new start without a
    /// new end keeps the visit's length.
    @MainActor
    static func apply(
        title: String?,
        startDate: Date?,
        endDate: Date?,
        note: String?,
        location: AppointmentLocation?,
        to appointment: Appointment
    ) {
        if let startDate, endDate == nil {
            AppointmentService.reschedule(appointment, to: startDate)
        }
        var fields = AppointmentFields(appointment: appointment)
        if let title { fields.shopName = CalendarMapping.shopName(title: title, location: location) }
        if let startDate, endDate != nil { fields.startDate = startDate }
        if let endDate { fields.endDate = endDate }
        if let note { fields.note = note }
        if let location {
            let place = CalendarMapping.place(from: location)
            fields.address = place.address
            fields.latitude = place.latitude
            fields.longitude = place.longitude
        }
        AppointmentService.update(appointment, with: fields)
    }
}

// MARK: - Delete

@available(iOS 27, *)
@AppIntent(schema: .calendar.deleteEvent)
struct DeleteAppointmentEventIntent {  // Not `DeleteIntent`: that takes `entities`; the schema has one `entity`.
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var entity: AppointmentEventEntity
    var span: AppointmentEventSpan?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let appointment = try IntentStore.scheduledAppointment(id: entity.id, in: context)
        let vehicleName = appointment.vehicle?.displayName ?? ""
        try await requestConfirmation(
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentCancelAsk(
                vehicle: vehicleName,
                shop: appointment.shopName,
                date: SpokenValue.date(appointment.startDate),
                time: SpokenValue.time(appointment.startDate)
            ))
        )
        try CancelAppointmentIntent.cancel(appointment, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriAppointmentCancelled(
            vehicle: vehicleName,
            shop: appointment.shopName
        )))
    }
}
