//
//  ListUpcomingServicesIntent.swift
//  checkpoint
//
//  "What maintenance is coming up in Checkpoint?" The next few services,
//  spoken as one sentence, over the due list with its Done buttons. The
//  sentence and the snippet cover the same services.
//

import AppIntents
import SwiftData

struct ListUpcomingServicesIntent: AppIntent {
    static let title: LocalizedStringResource = "List Upcoming Services"
    static let description = IntentDescription("List the next few maintenance services due on your vehicle")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("List upcoming services on \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let rows = Array(DueServices.upcoming(on: vehicle).prefix(DueServicesSnippetIntent.rowLimit))
        return .result(
            dialog: IntentDialog(stringLiteral: Self.answer(rows, vehicle: vehicle)),
            snippetIntent: DueServicesSnippetIntent(vehicle: VehicleEntity(model: vehicle), scope: .upcoming)
        )
    }

    @MainActor
    static func answer(_ rows: [DueServiceRow], vehicle: Vehicle) -> String {
        guard let first = rows.first else { return L10n.siriNothingScheduled(vehicle: vehicle.displayName) }
        guard rows.count > 1 else {
            return L10n.siriSingle(first.status, vehicle: vehicle.displayName, service: first.name, due: first.due)
        }
        let items = rows.map { row in
            row.status == .overdue
                ? L10n.siriListItemOverdue(row.name)
                : L10n.siriListItem(row.name, due: DuePeriodFormatter.midSentence(row.due))
        }
        return L10n.siriListIntro(vehicle: vehicle.displayName, list: SpokenValue.list(items))
    }
}
