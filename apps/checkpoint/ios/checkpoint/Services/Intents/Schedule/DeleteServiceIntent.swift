//
//  DeleteServiceIntent.swift
//  checkpoint
//
//  "Delete the wiper blades service." Removes services and, by cascade,
//  their history — through `ServiceDeleteAction`, the same path as the app.
//  Never without a spoken yes: a delete can't be undone by voice, and voice
//  deletes are limited to services and service logs (vehicles and documents
//  stay in-app).
//

import AppIntents
import SwiftData

struct DeleteServiceIntent: DeleteIntent {
    static let title: LocalizedStringResource = "Delete Service"
    static let description = IntentDescription("Delete services and their history. Checkpoint asks before deleting.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Services", requestValueDialog: "Which service do you want to delete?")
    var entities: [ServiceEntity]

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$entities)")
    }

    init() {}

    init(entities: [ServiceEntity]) {
        self.entities = entities
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let services = try IntentStore.services(entities, in: context)
        guard !services.isEmpty else { throw $entities.needsValueError() }
        let names = services.map(\.name)

        try await requestConfirmation(dialog: IntentDialog(stringLiteral: L10n.siriDeleteServiceConfirm(names)))

        try Self.delete(services, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriDeleteServiceDone(names)))
    }

    /// The write, once confirmed. Services are deleted per vehicle so each
    /// vehicle's reminders, icon and widget are rebuilt once.
    @MainActor
    static func delete(_ services: [Service], in context: ModelContext) throws {
        let byVehicle = Dictionary(grouping: services) { $0.vehicle?.id }
        for group in byVehicle.values {
            guard let vehicle = group.first?.vehicle else {
                group.forEach(context.delete)
                continue
            }
            ServiceDeleteAction.delete(group, vehicle: vehicle, in: context)
        }
        try IntentStore.save(context)
    }
}
