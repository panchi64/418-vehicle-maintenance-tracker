//
//  AddServiceIntent.swift
//  checkpoint
//
//  "Add a tire rotation to the Civic in Checkpoint, every 6 months." Puts a
//  service on the schedule — the form's "Not done yet" path. A preset brings
//  its own cadence; a spoken interval or due date wins over it. Siri asks for
//  the service when none was named, and for a due date when nothing said
//  when it comes due.
//

import AppIntents
import SwiftData

struct AddServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Service"
    static let description = IntentDescription("Put a service on your vehicle's schedule, from a preset or by name")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Service Type", description: "A service from Checkpoint's list, with its usual interval")
    var preset: ServicePresetEntity?

    @Parameter(title: "Name", description: "Any service name, when it isn't in the list")
    var name: String?

    @Parameter(title: "Every (Months)")
    var intervalMonths: Int?

    /// In the user's distance unit.
    @Parameter(title: "Every (Distance)", description: "In your distance unit")
    var intervalMiles: Int?

    @Parameter(title: "Due Date")
    var dueDate: Date?

    /// In the user's distance unit.
    @Parameter(title: "Due Mileage", description: "In your distance unit")
    var dueMileage: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$preset) to \(\.$vehicle)") {
            \.$name
            \.$intervalMonths
            \.$intervalMiles
            \.$dueDate
            \.$dueMileage
        }
    }

    init() {}

    init(vehicle: VehicleEntity?, name: String) {
        self.vehicle = vehicle
        self.name = name
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceEntity> & ProvidesDialog {
        let serviceName = (preset?.name ?? name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !serviceName.isEmpty else {
            throw $name.needsValueError("Which service do you want to add?")
        }
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let unit = DistanceSettings.shared.unit

        switch ServiceScheduling.add(
            named: serviceName,
            to: vehicle,
            request: ServiceScheduling.Request(
                intervalMonths: intervalMonths,
                intervalMiles: intervalMiles.map { unit.toMiles($0) },
                dueDate: dueDate,
                dueMileage: dueMileage.map { unit.toMiles($0) }
            ),
            in: context
        ) {
        case .needsDue:
            throw $dueDate.needsValueError("When is it due?")
        case .alreadyScheduled(let existing):
            return .result(
                value: ServiceEntity(model: existing),
                dialog: IntentDialog(stringLiteral: L10n.siriAddExists(
                    service: existing.name,
                    vehicle: vehicle.displayName,
                    due: SpokenValue.schedule(dueDate: existing.dueDate, dueMileage: existing.dueMileage) ?? ""
                ))
            )
        case .added(let service):
            try IntentStore.commit(vehicle, in: context)
            return .result(
                value: ServiceEntity(model: service),
                dialog: IntentDialog(stringLiteral: L10n.siriAddSaved(
                    service: service.name,
                    vehicle: vehicle.displayName,
                    due: SpokenValue.schedule(dueDate: service.dueDate, dueMileage: service.dueMileage) ?? ""
                ))
            )
        }
    }
}
