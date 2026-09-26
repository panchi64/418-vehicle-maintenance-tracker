//
//  VehicleListEntity.swift
//  checkpoint
//
//  A vehicle, as a list in the iOS 27 Reminders schema: its tracked services
//  are the reminders on it. A separate type from `VehicleEntity` because a
//  schema macro can't be applied to a type that exists on iOS 26; both read
//  the same models through `VehicleEntity.models(ids:in:)`, with the same
//  UUID for the same vehicle.
//

import AppIntents
import SwiftData

@available(iOS 27, *)
@AppEnum(schema: .reminders.listType)
nonisolated enum ReminderListType: String {
    case standard

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .standard: "Standard"
    ]
}

@available(iOS 27, *)
@AppEntity(schema: .reminders.list)
struct VehicleListEntity: ModelSnapshotEntity {
    static let defaultQuery = VehicleListEntityQuery()

    let id: UUID

    var name: String
    var type: ReminderListType

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "car.fill"))
    }

    var searchableText: [String] { [name] }

    @MainActor
    init(model vehicle: Vehicle) {
        self.init(id: vehicle.id, name: vehicle.displayName)
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
        type = .standard
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Vehicle] {
        try VehicleEntity.models(ids: ids, in: context)
    }
}

@available(iOS 27, *)
struct VehicleListEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleListEntity] {
        try await EntityFetch.entities(VehicleListEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleListEntity] {
        try await EntityFetch.entities(VehicleListEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleListEntity] {
        try await EntityFetch.entities(VehicleListEntity.self, in: container)
    }
}
