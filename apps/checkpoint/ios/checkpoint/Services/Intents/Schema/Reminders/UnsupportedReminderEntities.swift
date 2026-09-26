//
//  UnsupportedReminderEntities.swift
//  checkpoint
//
//  Checkpoint has no location-based reminders and no list sections, but the
//  App Intents metadata processor still requires their types:
//
//    - `.reminders.reminder` fails export with "Missing required property
//      'locationTrigger'", and `createReminder` with "Missing required
//      parameter 'section'".
//    - Every entity a schema intent takes as a parameter must have an
//      `EntityStringQuery` (or be indexed, unique or transient).
//
//  These are those types, with queries that find nothing: every reminder's
//  trigger is nil, and a trigger or section passed to an intent is ignored.
//  The `.reminders.section` entity is declared only as the parameter's type;
//  `createSection` is not adopted.
//

import AppIntents
import GeoToolbox

@available(iOS 27, *)
@AppEnum(schema: .reminders.locationTriggerEvent)
nonisolated enum ReminderLocationEvent: String {
    case arrive
    case depart

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .arrive: "Arrive",
        .depart: "Depart"
    ]
}

@available(iOS 27, *)
@AppEntity(schema: .reminders.locationTrigger)
struct NoLocationTriggerEntity {
    static let defaultQuery = NoLocationTriggerQuery()

    let id: UUID

    var place: PlaceDescriptor
    var event: ReminderLocationEvent

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(event.rawValue)")
    }
}

@available(iOS 27, *)
struct NoLocationTriggerQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoLocationTriggerEntity] { [] }
    func entities(matching string: String) async throws -> [NoLocationTriggerEntity] { [] }
}

@available(iOS 27, *)
@AppEntity(schema: .reminders.section)
struct NoSectionEntity {
    static let defaultQuery = NoSectionQuery()

    let id: UUID

    var name: String
    var list: VehicleListEntity

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 27, *)
struct NoSectionQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoSectionEntity] { [] }
    func entities(matching string: String) async throws -> [NoSectionEntity] { [] }
}
