//
//  UnsupportedCalendarEntities.swift
//  checkpoint
//
//  A shop visit has no attendees, but `.calendar.event` and `createEvent` /
//  `updateEvent` take `[AttendeeEntity]`, and the metadata processor needs
//  the type (with its status and type enums) to exist and to have a string
//  query. This is that type; its query finds nothing, every event's
//  attendees are empty, and attendees passed to an intent are ignored.
//

import AppIntents

@available(iOS 27, *)
@AppEnum(schema: .calendar.attendeeStatus)
nonisolated enum AttendeeParticipantStatus: String {
    case accepted
    case declined
    case tentative

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .accepted: "Accepted",
        .declined: "Declined",
        .tentative: "Tentative"
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .calendar.attendeeType)
nonisolated enum AttendeeKind: String {
    case person

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .person: "Person"
    ]
}

@available(iOS 27, *)
@AppEntity(schema: .calendar.attendee)
struct NoAttendeeEntity {
    static let defaultQuery = NoAttendeeQuery()

    let id: UUID

    var person: IntentPerson
    var status: AttendeeParticipantStatus?
    var isAttendanceOptional: Bool
    var type: AttendeeKind?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Person")
    }
}

@available(iOS 27, *)
struct NoAttendeeQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoAttendeeEntity] { [] }
    func entities(matching string: String) async throws -> [NoAttendeeEntity] { [] }
}
