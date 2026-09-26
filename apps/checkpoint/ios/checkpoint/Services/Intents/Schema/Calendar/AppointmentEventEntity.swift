//
//  AppointmentEventEntity.swift
//  checkpoint
//
//  The iOS 27 Calendar schema over shop appointments: a vehicle is a
//  calendar, a booked visit is an event on it. Apple Intelligence can then
//  answer "when's the Civic at the shop?" and act on "move it to Friday".
//  Service due dates stay reminders (Reminders schema), not events.
//
//  Separate `@available(iOS 27, *)` types over the same models as the iOS 26
//  `AppointmentEntity` / `VehicleEntity`, with the same UUIDs (a schema macro
//  can't be applied to a type that exists on iOS 26). Fields map through
//  `CalendarMapping`. Organizers and attendees are always empty — a shop
//  visit has none — and alarms are the appointment's two reminders.
//

import AppIntents
import GeoToolbox
import SwiftData

@available(iOS 27, *)
@AppEntity(schema: .calendar.calendar)
struct VehicleCalendarEntity: ModelSnapshotEntity {
    static let defaultQuery = VehicleCalendarEntityQuery()

    let id: UUID

    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: "car.fill"))
    }

    var searchableText: [String] { [title] }

    @MainActor
    init(model vehicle: Vehicle) {
        self.init(id: vehicle.id, title: vehicle.displayName)
    }

    init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Vehicle] {
        try VehicleEntity.models(ids: ids, in: context)
    }
}

@available(iOS 27, *)
struct VehicleCalendarEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleCalendarEntity] {
        try await EntityFetch.entities(VehicleCalendarEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleCalendarEntity] {
        try await EntityFetch.entities(VehicleCalendarEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleCalendarEntity] {
        try await EntityFetch.entities(VehicleCalendarEntity.self, in: container)
    }
}

@available(iOS 27, *)
@AppEnum(schema: .calendar.eventStatus)
nonisolated enum AppointmentEventStatus: String {
    case confirmed
    case tentative
    case cancelled

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .confirmed: "Confirmed",
        .tentative: "Tentative",
        .cancelled: "Cancelled"
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .calendar.eventSpan)
nonisolated enum AppointmentEventSpan: String {
    case this
    case future
    case all

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .this: "This",
        .future: "Future",
        .all: "All"
    ]
}

/// Where the visit is: a resolved place, or an address as typed.
@available(iOS 27, *)
@UnionValue
enum AppointmentLocation {
    case place(GeoToolbox.PlaceDescriptor)
    case address(String)
}

/// When the visit reminds: the absolute fire times of its reminders.
@available(iOS 27, *)
@UnionValue
enum AppointmentAlarm {
    case duration(Duration)
    case date(Date)
}

@available(iOS 27, *)
@AppEntity(schema: .calendar.event)
struct AppointmentEventEntity: ModelSnapshotEntity {
    static let defaultQuery = AppointmentEventEntityQuery()

    let id: UUID

    var calendar: VehicleCalendarEntity
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var recurrence: Calendar.RecurrenceRule?
    var note: AttributedString?
    var travelTime: Duration?
    var location: AppointmentLocation?
    var virtualLocation: URL?
    var status: AppointmentEventStatus?
    var alarms: [AppointmentAlarm]
    var organizers: [IntentPerson]
    /// Always empty. Required by the schema (see NoAttendeeEntity).
    var attendees: [NoAttendeeEntity]

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(startDate.formatted(date: .abbreviated, time: .shortened)) · \(calendar.title)",
            image: .init(systemName: "calendar.badge.clock")
        )
    }

    var searchableText: [String] { [title] }

    /// `appointment` must belong to a vehicle; `models(ids:in:)` only
    /// returns ones that do.
    @MainActor
    init(model appointment: Appointment) {
        id = appointment.id
        title = appointment.trimmedShopName ?? L10n.appointmentShopFallback
        startDate = appointment.startDate
        endDate = appointment.effectiveEndDate
        isAllDay = false
        recurrence = nil
        note = CalendarMapping.note(
            note: appointment.note,
            serviceNames: appointment.sortedServices.map(\.name)
        ).map { AttributedString($0) }
        travelTime = nil
        location = AppointmentDirections.placeDescriptor(for: appointment).map { .place($0) }
        virtualLocation = nil
        status = CalendarMapping.status(appointment.status)
        alarms = CalendarMapping.alarmDates(for: appointment).map { .date($0) }
        organizers = []
        attendees = []
        // Never the fallback: `models(ids:in:)` filters orphans out.
        calendar = appointment.vehicle.map(VehicleCalendarEntity.init(model:))
            ?? VehicleCalendarEntity(id: appointment.id, title: "")
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Appointment] {
        try AppointmentEntity.models(ids: ids, in: context).filter { $0.vehicle != nil }
    }
}

@available(iOS 27, *)
struct AppointmentEventEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [AppointmentEventEntity] {
        try await EntityFetch.entities(AppointmentEventEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [AppointmentEventEntity] {
        try await EntityFetch.entities(AppointmentEventEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [AppointmentEventEntity] {
        try await EntityFetch.entities(AppointmentEventEntity.self, in: container)
            .filter { $0.status != .cancelled }
    }
}
