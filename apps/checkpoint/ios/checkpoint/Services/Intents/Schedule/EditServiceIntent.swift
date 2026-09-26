//
//  EditServiceIntent.swift
//  checkpoint
//
//  "Change the oil change in Checkpoint to every 6 months." Edits a tracked
//  service's name, due date, due mileage or cadence through the same rule as
//  Edit Service (`Service.apply(_:)`): what was said replaces what was there,
//  and anything not mentioned stays.
//

import AppIntents
import SwiftData

struct EditServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Service"
    static let description = IntentDescription("Change a scheduled service's name, due date, due mileage or interval")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service", requestValueDialog: "Which service do you want to change?")
    var service: ServiceEntity

    @Parameter(title: "New Name")
    var name: String?

    @Parameter(title: "Due Date")
    var dueDate: Date?

    /// In the user's distance unit.
    @Parameter(title: "Due Mileage", description: "In your distance unit")
    var dueMileage: Int?

    @Parameter(title: "Every (Months)")
    var intervalMonths: Int?

    /// In the user's distance unit.
    @Parameter(title: "Every (Distance)", description: "In your distance unit")
    var intervalMiles: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Edit \(\.$service)") {
            \.$name
            \.$dueDate
            \.$dueMileage
            \.$intervalMonths
            \.$intervalMiles
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceEntity> & ProvidesDialog {
        let context = container.mainContext
        let service = try IntentStore.service(self.service, in: context)
        let vehicle = try IntentStore.vehicle(of: service)

        let edit = Self.edit(of: service, applying: self)
        guard edit != service.unchangedEdit else {
            throw $dueDate.needsValueError("When should it be due?")
        }
        service.apply(edit)
        try IntentStore.commit(vehicle, in: context)

        let dialog = SpokenValue.schedule(dueDate: service.dueDate, dueMileage: service.dueMileage)
            .map { L10n.siriEditSaved(service: service.name, due: $0) }
            ?? L10n.siriEditSavedUnscheduled(service: service.name)
        return .result(value: ServiceEntity(model: service), dialog: IntentDialog(stringLiteral: dialog))
    }

    /// `service` with what `intent` said applied. A cadence that was said
    /// turns Repeat on, as typing one in the form does.
    @MainActor
    static func edit(of service: Service, applying intent: EditServiceIntent) -> ServiceEdit {
        let unit = DistanceSettings.shared.unit
        var edit = service.unchangedEdit
        if let name = intent.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            edit.name = name
        }
        if let dueDate = intent.dueDate { edit.explicitDueDate = dueDate }
        if let dueMileage = intent.dueMileage { edit.explicitDueMileage = unit.toMiles(dueMileage) }
        if intent.intervalMonths != nil || intent.intervalMiles != nil {
            if let months = intent.intervalMonths { edit.intervalMonths = months }
            if let miles = intent.intervalMiles { edit.intervalMiles = unit.toMiles(miles) }
            edit.isRecurring = true
        }
        return edit
    }
}
