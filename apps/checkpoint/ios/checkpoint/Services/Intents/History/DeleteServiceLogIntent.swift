//
//  DeleteServiceLogIntent.swift
//  checkpoint
//
//  "Delete the last oil change entry." Removes service history entries
//  through `ServiceLogDeleteAction` — the app's path, which rolls a
//  service's schedule back when its newest log goes. Never without a spoken
//  yes: Siri has no Undo toast to offer.
//

import AppIntents
import SwiftData

struct DeleteServiceLogIntent: DeleteIntent {
    static let title: LocalizedStringResource = "Delete Service Log"
    static let description = IntentDescription("Delete entries from a vehicle's service history. Checkpoint asks before deleting.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service Logs", requestValueDialog: "Which entry do you want to delete?")
    var entities: [ServiceLogEntity]

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$entities)")
    }

    init() {}

    init(entities: [ServiceLogEntity]) {
        self.entities = entities
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let logs = try IntentStore.logs(entities, in: context)
        guard let first = logs.first else { throw $entities.needsValueError() }
        let name = first.service?.name ?? L10n.rowServiceFallback
        let date = SpokenValue.date(first.performedDate)

        try await requestConfirmation(dialog: IntentDialog(stringLiteral: L10n.siriDeleteLogConfirm(
            count: logs.count, service: name, date: date
        )))

        try Self.delete(logs, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriDeleteLogDone(
            count: logs.count, service: name, date: date
        )))
    }

    /// The write, once confirmed.
    @MainActor
    static func delete(_ logs: [ServiceLog], in context: ModelContext) throws {
        for log in logs {
            ServiceLogDeleteAction.perform(log, offerUndo: false)
        }
        try IntentStore.save(context)
    }
}
