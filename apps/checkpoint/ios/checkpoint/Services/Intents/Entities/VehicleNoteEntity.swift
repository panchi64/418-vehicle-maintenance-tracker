//
//  VehicleNoteEntity.swift
//  checkpoint
//
//  A note about a vehicle — paint code, torque specs, what the advisor said.
//  Its text is indexed, so Spotlight and Siri find a note by what it says.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct VehicleNoteEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Vehicle Note", numericFormat: "\(placeholder: .int) vehicle notes")
    }

    static var defaultQuery: VehicleNoteEntityQuery { VehicleNoteEntityQuery() }

    let id: UUID

    @Property(title: "Title", indexingKey: \.displayName)
    var title: String

    @Property(title: "Text", indexingKey: \.textContent)
    var body: String

    @Property(title: "Pinned")
    var isPinned: Bool

    @Property(title: "Vehicle")
    var vehicleName: String

    @Property(title: "Created")
    var createdAt: Date

    @Property(title: "Modified", indexingKey: \.contentModificationDate)
    var modifiedAt: Date

    @Property(title: "Attachments")
    var attachmentCount: Int

    let vehicleID: UUID?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(vehicleName)",
            image: .init(systemName: isPinned ? "pin.fill" : "note.text")
        )
    }

    var searchableText: [String] { [title, body] }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.containerDisplayName = vehicleName
        return attributes
    }

    @MainActor
    init(model note: VehicleNote) {
        id = note.id
        vehicleID = note.vehicle?.id
        title = note.displayTitle
        body = note.body
        isPinned = note.isPinned
        vehicleName = note.vehicle?.displayName ?? ""
        createdAt = note.createdAt
        modifiedAt = note.modifiedAt
        attachmentCount = note.attachments?.count ?? 0
    }

    /// Pinned first, then most recently changed.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [VehicleNote] {
        let descriptor: FetchDescriptor<VehicleNote>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) })
        } else {
            descriptor = FetchDescriptor()
        }
        return try context.fetch(descriptor).sorted(by: VehicleNote.listOrder)
    }
}

struct VehicleNoteEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleNoteEntity] {
        try await EntityFetch.entities(VehicleNoteEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleNoteEntity] {
        try await EntityFetch.entities(VehicleNoteEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleNoteEntity] {
        try await EntityFetch.entities(VehicleNoteEntity.self, in: container)
    }
}
