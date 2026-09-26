//
//  LogServiceIntent.swift
//  checkpoint
//
//  "Log an oil change and tire rotation on the Civic in Checkpoint, 45,200
//  miles, $120 at Firestone." One or more performed services, by name or
//  picked from the vehicle's schedule, written as the [+] form or "Mark all
//  done" would write them (`ServiceLogging`). A name that matches a tracked
//  service completes it rather than creating a duplicate.
//

import AppIntents
import SwiftData

struct LogServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Service"
    static let description = IntentDescription("Record services you had done, with optional date, mileage, total cost and shop")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    /// Free text or preset names. "Oil change and tire rotation" is two.
    @Parameter(title: "Services", description: "What was done, e.g. Oil Change, Tire Rotation")
    var services: [String]?

    /// Services picked from the schedule, for Shortcuts.
    @Parameter(title: "Scheduled Services")
    var scheduledServices: [ServiceEntity]?

    @Parameter(title: "Date", description: "When it was done. Leave empty for today.")
    var date: Date?

    @Parameter(title: "Mileage", description: "The odometer at the service, in your distance unit")
    var mileage: Int?

    @Parameter(title: "Total Cost")
    var cost: IntentCurrencyAmount?

    @Parameter(title: "Shop")
    var shop: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$services) on \(\.$vehicle)") {
            \.$scheduledServices
            \.$date
            \.$mileage
            \.$cost
            \.$shop
        }
    }

    init() {}

    init(vehicle: VehicleEntity?, services: [String]) {
        self.vehicle = vehicle
        self.services = services
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ServiceLogEntity]> & ProvidesDialog {
        let context = container.mainContext
        let scheduled = try IntentStore.services(scheduledServices ?? [], in: context)
        // A picked service decides the vehicle; otherwise the phrase does.
        let vehicle = try scheduled.first?.vehicle ?? IntentStore.vehicle(for: self.vehicle, in: context)

        let names = ServiceLogging.names(
            in: scheduled.map(\.name) + (services ?? []),
            knownNames: ServiceLogging.knownNames(on: vehicle)
        )
        guard !names.isEmpty else {
            throw $services.needsValueError("Which services did you do?")
        }

        let occasion = self.occasion
        try await requestConfirmation(
            actionName: .log,
            dialog: IntentDialog(stringLiteral: L10n.siriLogConfirm(
                services: SpokenValue.list(names),
                vehicle: vehicle.displayName
            )),
            snippetIntent: ServiceRecordSnippetIntent(
                serviceNames: names,
                vehicleName: vehicle.displayName,
                occasion: occasion,
                vehicle: vehicle
            )
        )

        let logs = ServiceLogging.log(names, on: vehicle, occasion: occasion, in: context)
        try IntentStore.commit(vehicle, in: context)

        return .result(
            value: logs.map { ServiceLogEntity(model: $0) },
            dialog: IntentDialog(stringLiteral: L10n.siriLogSaved(
                services: SpokenValue.list(logs.compactMap { $0.service?.name }),
                vehicle: vehicle.displayName
            ))
        )
    }

    @MainActor
    var occasion: ServiceLogging.Occasion {
        ServiceLogging.Occasion(
            date: date,
            mileage: mileage.map { DistanceSettings.shared.unit.toMiles($0) },
            totalCost: cost?.amount,
            shop: shop
        )
    }
}
