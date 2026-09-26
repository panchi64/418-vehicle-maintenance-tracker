//
//  ListOverdueIntent.swift
//  checkpoint
//
//  "What's overdue on my car in Checkpoint?" Every overdue service, spoken,
//  over the overdue list with its Done buttons.
//

import AppIntents
import SwiftData

struct ListOverdueIntent: AppIntent {
    static let title: LocalizedStringResource = "List Overdue Services"
    static let description = IntentDescription("Hear which services are overdue on your vehicle")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("List overdue services on \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ServiceEntity]> & ProvidesDialog & ShowsSnippetIntent {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let overdue = DueServices.overdue(on: vehicle)
        return .result(
            value: overdue.map(\.service),
            dialog: IntentDialog(stringLiteral: Self.answer(overdue, vehicle: vehicle)),
            snippetIntent: DueServicesSnippetIntent(vehicle: VehicleEntity(model: vehicle), scope: .overdue)
        )
    }

    @MainActor
    static func answer(_ overdue: [DueServiceRow], vehicle: Vehicle) -> String {
        switch overdue.count {
        case 0:
            return L10n.siriOverdueNone(vehicle: vehicle.displayName)
        case 1:
            return L10n.siriOverdueOne(service: overdue[0].name, vehicle: vehicle.displayName)
        default:
            return L10n.siriOverdueMany(
                count: overdue.count,
                vehicle: vehicle.displayName,
                list: SpokenValue.list(overdue.map(\.name))
            )
        }
    }
}
