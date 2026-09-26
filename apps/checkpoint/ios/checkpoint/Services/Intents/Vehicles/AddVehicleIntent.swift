//
//  AddVehicleIntent.swift
//  checkpoint
//
//  "Add a vehicle in Checkpoint." By make and model, or by VIN — looked up
//  with NHTSA as the Add Vehicle form does (`VehicleService.fillingFromVIN`),
//  with anything said out loud winning over the lookup. Siri asks for what
//  is still missing (make, model, the odometer, which the form requires
//  too), then asks once whether to add the usual maintenance schedule —
//  the sheet the app offers after Add Vehicle — and that answer is the
//  confirmation: dismissing it saves nothing.
//
//  Free users keep up to `VehicleService.freeVehicleLimit` vehicles; past it
//  Siri says so before asking anything.
//

import AppIntents
import SwiftData

struct AddVehicleIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Vehicle"
    static let description = IntentDescription("Add a vehicle by its make and model, or by its VIN, which Checkpoint looks up. Checkpoint can add the usual maintenance schedule too.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Make")
    var make: String?

    @Parameter(title: "Model")
    var model: String?

    @Parameter(title: "Year")
    var year: Int?

    @Parameter(title: "VIN", description: "The 17-character VIN. Checkpoint fills in the make, model and year from it.")
    var vin: String?

    @Parameter(title: "Nickname")
    var name: String?

    /// In the user's distance unit.
    @Parameter(title: "Mileage", description: "The odometer reading, in your distance unit")
    var mileage: Int?

    /// Nil: ask. Set it in a shortcut to skip the question.
    @Parameter(
        title: "Add Maintenance Schedule",
        description: "Add the common services with their usual intervals. Leave empty to be asked."
    )
    var addsSchedule: Bool?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$year) \(\.$make) \(\.$model)") {
            \.$vin
            \.$name
            \.$mileage
            \.$addsSchedule
        }
    }

    init() {}

    /// The client VIN lookups go through. Tests substitute a stub.
    @MainActor static var nhtsa: any NHTSAClient = NHTSAService.shared

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleEntity> & ProvidesDialog {
        let context = container.mainContext
        try Self.checkLimit(in: context, isPro: StoreManager.shared.isPro)

        if let year, !Vehicle.isPlausibleModelYear(year) {
            throw $year.needsValueError("What year is it?")
        }
        let identified = await Self.identify(Self.spokenFields(make: make, model: model, year: year, vin: vin, name: name), using: Self.nhtsa)
        var fields = identified.fields
        if fields.make.isEmpty {
            fields.make = identified.vinFailed
                ? try await $make.requestValue("Checkpoint couldn't look up that VIN. What's the make?")
                : try await $make.requestValue("What's the make?")
        }
        if fields.model.isEmpty {
            fields.model = try await $model.requestValue("What's the model?")
        }
        var reading = mileage ?? 0
        if mileage == nil {
            reading = try await $mileage.requestValue("What does the odometer read?")
        }
        fields.currentMileage = DistanceSettings.shared.unit.toMiles(max(reading, 0))

        let label = Self.label(for: fields)
        let schedule = StarterSchedule.items(from: PresetDataService.shared.loadPresets()).map(\.name)
        var addsSchedule = self.addsSchedule ?? false
        if self.addsSchedule == nil, schedule.count >= 2 {
            let withSchedule = IntentChoiceOption(title: "Add with Schedule")
            let choice = try await requestChoice(
                between: [withSchedule, IntentChoiceOption(title: "Add Vehicle Only")],
                dialog: IntentDialog(stringLiteral: L10n.siriVehicleScheduleAsk(
                    vehicle: label,
                    first: schedule[0],
                    second: schedule[1]
                ))
            )
            addsSchedule = choice == withSchedule
        }

        let vehicle = try Self.add(fields, withSchedule: addsSchedule, in: context, isPro: StoreManager.shared.isPro)
        return .result(
            value: VehicleEntity(model: vehicle),
            dialog: IntentDialog(stringLiteral: addsSchedule
                ? L10n.siriVehicleAddedWithSchedule(vehicle.displayName)
                : L10n.siriVehicleAdded(vehicle.displayName))
        )
    }

    // MARK: - Steps (static, so tests can run them without Siri)

    /// Past the free limit, adding needs Pro.
    @MainActor
    static func checkLimit(in context: ModelContext, isPro: Bool) throws {
        let count = try context.fetchCount(FetchDescriptor<Vehicle>())
        guard !VehicleService.requiresPro(toAddTo: count, isPro: isPro) else {
            throw IntentError.vehicleLimitReached
        }
    }

    /// What was said, trimmed. An implausible year is dropped.
    static func spokenFields(make: String?, model: String?, year: Int?, vin: String?, name: String?) -> VehicleFields {
        var fields = VehicleFields()
        fields.make = make?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        fields.model = model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        fields.year = year.flatMap { Vehicle.isPlausibleModelYear($0) ? $0 : nil }
        fields.vin = vin?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "") ?? ""
        fields.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fields
    }

    /// `fields` filled from the VIN where it left gaps. A VIN that isn't
    /// valid, or that NHTSA couldn't decode, is dropped rather than stored
    /// wrong, and reported so Siri can say why it's asking.
    static func identify(_ fields: VehicleFields, using client: any NHTSAClient) async -> (fields: VehicleFields, vinFailed: Bool) {
        guard !fields.vin.isEmpty else { return (fields, false) }
        guard Vehicle.isValidVIN(fields.vin) else {
            var cleared = fields
            cleared.vin = ""
            return (cleared, true)
        }
        do {
            return (try await VehicleService.fillingFromVIN(fields, using: client), false)
        } catch {
            // Keep the VIN (it's valid, the lookup was what failed); the
            // make and model are asked instead.
            var kept = fields
            kept.vin = fields.vin.uppercased()
            return (kept, true)
        }
    }

    /// The vehicle, then — when asked for — the starter schedule, committed
    /// like Add Vehicle and the schedule sheet together.
    @MainActor
    @discardableResult
    static func add(_ fields: VehicleFields, withSchedule: Bool, in context: ModelContext, isPro: Bool, now: Date = .now) throws -> Vehicle {
        try checkLimit(in: context, isPro: isPro)
        let vehicle = VehicleService.create(fields, in: context)
        if withSchedule {
            StarterScheduleWriter.insert(StarterScheduleWriter.defaultPlans(for: vehicle, now: now), on: vehicle, in: context)
        }
        try IntentStore.commit(vehicle, in: context)
        return vehicle
    }

    /// What the vehicle will be called: the nickname, else "2020 Honda Civic".
    static func label(for fields: VehicleFields) -> String {
        if !fields.name.isEmpty { return fields.name }
        return [fields.year.map(String.init), fields.make, fields.model]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
