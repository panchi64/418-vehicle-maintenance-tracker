//
//  CheckNextDueIntent.swift
//  checkpoint
//
//  "What's due on my car in Checkpoint?" The most urgent service, spoken,
//  over the due list with its Done buttons (`DueServicesSnippetIntent`).
//

import AppIntents
import SwiftData

struct CheckNextDueIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Next Due Service"
    static let description = IntentDescription("Check what maintenance is due next on your vehicle")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check next due service on \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        return .result(
            dialog: IntentDialog(stringLiteral: Self.answer(DueServices.upcoming(on: vehicle).first, vehicle: vehicle)),
            snippetIntent: DueServicesSnippetIntent(vehicle: VehicleEntity(model: vehicle), scope: .upcoming)
        )
    }

    /// "Oil Change on Daily Driver is due soon. Due mid May." The due phrase
    /// reads as an abstracted period for date-based services, or distance
    /// remaining for mileage-tracked ones.
    @MainActor
    static func answer(_ next: DueServiceRow?, vehicle: Vehicle) -> String {
        guard let next else { return L10n.siriNothingScheduled(vehicle: vehicle.displayName) }
        return L10n.siriNextDue(next.status, service: next.name, vehicle: vehicle.displayName, due: next.due)
    }
}
