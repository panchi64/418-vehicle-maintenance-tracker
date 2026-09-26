//
//  ServiceReminderEntity.swift
//  checkpoint
//
//  A tracked service, as a reminder in the iOS 27 Reminders schema, so
//  Apple Intelligence can read and act on it ("remind me to rotate the
//  tires every six months", "what's due on the Civic?"). Fields map through
//  `ReminderMapping`; the schema has no mileage, so due and interval mileage
//  ride at the end of `note`.
//
//  Wraps the same models as `ServiceEntity`, with the same UUID for the same
//  service. Schema properties Checkpoint doesn't keep — tags, URLs, flags,
//  creation date — are empty. There are no location triggers, sections or
//  groups (see docs/APP_INTENTS.md).
//

import AppIntents
import SwiftData

@available(iOS 27, *)
@AppEntity(schema: .reminders.reminder)
struct ServiceReminderEntity: ModelSnapshotEntity {
    static let defaultQuery = ServiceReminderEntityQuery()

    let id: UUID

    var title: String
    var note: AttributedString?
    var tags: Set<String>
    var urls: [URL]
    var dueDate: DateComponents?
    var recurrence: Calendar.RecurrenceRule?
    var isCompleted: Bool
    var isFlagged: Bool?
    var creationDate: Date?
    var completionDate: Date?
    var list: VehicleListEntity
    /// Always nil. Required by the schema (see UnsupportedReminderEntities).
    var locationTrigger: NoLocationTriggerEntity?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(list.name)",
            image: .init(systemName: "wrench.and.screwdriver.fill")
        )
    }

    var searchableText: [String] { [title] }

    /// `service` must belong to a vehicle; `models(ids:in:)` only returns
    /// ones that do.
    @MainActor
    init(model service: Service) {
        let summary = ReminderMapping.mileageSummary(
            dueMileage: service.dueMileage,
            intervalMiles: service.intervalMiles
        )
        id = service.id
        title = service.name
        note = ReminderMapping.note(notes: service.notes, mileageSummary: summary).map { AttributedString($0) }
        tags = []
        urls = []
        dueDate = ReminderMapping.dueDateComponents(service.dueDate)
        recurrence = ReminderMapping.recurrence(intervalMonths: service.isRecurring ? service.intervalMonths : nil)
        isCompleted = ReminderMapping.isCompleted(service)
        isFlagged = nil
        creationDate = nil
        completionDate = ReminderMapping.completionDate(service)
        locationTrigger = nil
        // Never the fallback: `models(ids:in:)` filters orphans out. It keeps
        // this init total without a force-unwrap.
        list = service.vehicle.map(VehicleListEntity.init(model:)) ?? VehicleListEntity(id: service.id, name: "")
    }

    /// Services on a vehicle. A reminder always sits on a list, and an
    /// orphan (mid-delete sync) has none.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Service] {
        try ServiceEntity.models(ids: ids, in: context).filter { $0.vehicle != nil }
    }
}

@available(iOS 27, *)
struct ServiceReminderEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [ServiceReminderEntity] {
        try await EntityFetch.entities(ServiceReminderEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [ServiceReminderEntity] {
        try await EntityFetch.entities(ServiceReminderEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [ServiceReminderEntity] {
        try await EntityFetch.entities(ServiceReminderEntity.self, in: container)
    }
}
