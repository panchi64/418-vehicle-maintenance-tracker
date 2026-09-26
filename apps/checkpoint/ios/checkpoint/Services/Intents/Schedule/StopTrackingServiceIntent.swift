//
//  StopTrackingServiceIntent.swift
//  checkpoint
//
//  "Stop tracking the cabin air filter." Takes a service off the schedule
//  without deleting its history (`Service.stopTracking`). In the app that
//  happens at once with an Undo toast; by voice there is no Undo to offer,
//  so Siri confirms first (SURFACE_DOCTRINE: every lossy action is confirmed
//  or reversible).
//

import AppIntents
import SwiftData

struct StopTrackingServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Tracking Service"
    static let description = IntentDescription("Take a service off the schedule. Its history stays.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service", requestValueDialog: "Which service should Checkpoint stop tracking?")
    var service: ServiceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Stop tracking \(\.$service)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let service = try IntentStore.service(self.service, in: context)
        let vehicle = try IntentStore.vehicle(of: service)
        guard service.hasDueTracking else {
            return .result(dialog: IntentDialog(stringLiteral: L10n.siriStopNotTracked(service: service.name)))
        }

        try await requestConfirmation(
            dialog: IntentDialog(stringLiteral: L10n.siriStopConfirm(service: service.name, vehicle: vehicle.displayName))
        )
        service.stopTracking()
        try IntentStore.commit(vehicle, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriStopSaved(service: service.name)))
    }
}
