//
//  MarkServiceDoneIntent.swift
//  checkpoint
//
//  "Mark the oil change done in Checkpoint." Completes a tracked service the
//  way the app's Mark Done does — a history entry, and the next occurrence
//  when the service recurs — after Siri shows what it heard
//  (`ServiceRecordSnippetIntent`) and gets a yes.
//
//  App-side and direct. The widget's Done button is a different intent
//  (`WidgetMarkDoneIntent`): it runs in the widget process and queues.
//

import AppIntents
import SwiftData

struct MarkServiceDoneIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Service Done"
    static let description = IntentDescription("Log a scheduled service as done, with optional cost, mileage and shop")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service", requestValueDialog: "Which service did you do?")
    var service: ServiceEntity

    @Parameter(title: "Date", description: "When it was done. Leave empty for today.")
    var date: Date?

    /// In the user's distance unit. Empty means the reading on file.
    @Parameter(title: "Mileage", description: "The odometer at the service, in your distance unit")
    var mileage: Int?

    @Parameter(title: "Cost")
    var cost: IntentCurrencyAmount?

    @Parameter(title: "Shop")
    var shop: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$service) done") {
            \.$date
            \.$mileage
            \.$cost
            \.$shop
        }
    }

    init() {}

    init(service: ServiceEntity) {
        self.service = service
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceLogEntity?> & ProvidesDialog {
        let context = container.mainContext
        let service = try IntentStore.service(self.service, in: context)
        let vehicle = try IntentStore.vehicle(of: service)
        guard service.hasDueTracking else {
            return .result(value: nil, dialog: IntentDialog(stringLiteral: L10n.siriDoneNotTracked(
                service: service.name,
                vehicle: vehicle.displayName
            )))
        }

        let occasion = self.occasion
        try await requestConfirmation(
            actionName: .log,
            dialog: IntentDialog(stringLiteral: L10n.siriDoneConfirm(service: service.name, vehicle: vehicle.displayName)),
            snippetIntent: ServiceRecordSnippetIntent(
                serviceNames: [service.name],
                vehicleName: vehicle.displayName,
                occasion: occasion,
                vehicle: vehicle
            )
        )

        let logs = ServiceLogging.markDone(service, on: vehicle, occasion: occasion, in: context)
        try IntentStore.commit(vehicle, in: context)

        return .result(
            value: logs.first.map { ServiceLogEntity(model: $0) },
            dialog: IntentDialog(stringLiteral: Self.savedDialog(for: service, vehicle: vehicle))
        )
    }

    /// The spoken values, converted to what the store keeps.
    @MainActor
    var occasion: ServiceLogging.Occasion {
        ServiceLogging.Occasion(
            date: date,
            mileage: mileage.map { DistanceSettings.shared.unit.toMiles($0) },
            totalCost: cost?.amount,
            shop: shop
        )
    }

    /// "Marked Oil Change done on Daily Driver. Next due May 12, 2027." The
    /// completed service's successor carries the next reminder; a
    /// non-recurring one leaves none to mention.
    @MainActor
    static func savedDialog(for completed: Service, vehicle: Vehicle) -> String {
        // Completing cleared the service's own due, so the one by its name
        // still counting down is the successor.
        let successor = ServiceScheduling.trackedService(named: completed.name, on: vehicle)
        guard let successor, let due = SpokenValue.schedule(dueDate: successor.dueDate, dueMileage: successor.dueMileage) else {
            return L10n.siriDoneSaved(service: completed.name, vehicle: vehicle.displayName)
        }
        return L10n.siriDoneSaved(service: completed.name, vehicle: vehicle.displayName, nextDue: due)
    }
}

extension ServiceRecordSnippetIntent {
    /// The confirmation for `occasion`, with the defaults the write will use
    /// filled in, so the snippet shows exactly what gets saved.
    @MainActor
    init(serviceNames: [String], vehicleName: String, occasion: ServiceLogging.Occasion, vehicle: Vehicle, now: Date = .now) {
        let timing = ServiceLogging.timing(for: occasion.date, now: now)
        self.init(
            serviceNames: serviceNames,
            vehicleName: vehicleName,
            date: timing.performedDate(explicit: occasion.date ?? now, now: now),
            mileage: occasion.mileage ?? vehicle.currentMileage,
            cost: IntentCurrencyAmount.stored(occasion.totalCost),
            shop: occasion.shopName
        )
    }
}
