//
//  UpdateMileageIntent.swift
//  checkpoint
//
//  "Update mileage in Checkpoint to 45,200." Records the reading without
//  opening the app. A spoken reading is a statement about the odometer now,
//  so it records like the mileage sheet (`MileageUpdateAction`); Siri asks
//  first only when the number looks misheard (`MileageReadingCheck`).
//

import AppIntents
import SwiftData

struct UpdateMileageIntent: AppIntent {
    static let title: LocalizedStringResource = "Update Vehicle Mileage"
    static let description = IntentDescription("Record the current odometer reading on your vehicle")

    @Dependency var container: ModelContainer

    @Parameter(
        title: "Vehicle",
        description: "The vehicle to update. Leave empty for the vehicle Checkpoint is showing."
    )
    var vehicle: VehicleEntity?

    /// In the user's distance unit, as read off the odometer.
    @Parameter(
        title: "Mileage",
        description: "The odometer reading, in your distance unit",
        requestValueDialog: "What does the odometer read?"
    )
    var mileage: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Update mileage on \(\.$vehicle) to \(\.$mileage)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleEntity> & ProvidesDialog {
        guard mileage > 0 else { throw $mileage.needsValueError() }
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let reading = DistanceSettings.shared.unit.toMiles(mileage)

        if let question = Self.confirmation(for: MileageReadingCheck.evaluate(reading: reading, for: vehicle), reading: reading, vehicle: vehicle) {
            try await requestConfirmation(actionName: .set, dialog: IntentDialog(stringLiteral: question))
        }

        MileageUpdateAction.record(reading, for: vehicle, in: context)
        try IntentStore.commit(vehicle, in: context)

        return .result(
            value: VehicleEntity(model: vehicle),
            dialog: IntentDialog(stringLiteral: L10n.siriMileageUpdated(
                vehicle: vehicle.displayName,
                mileage: SpokenValue.mileage(reading)
            ))
        )
    }

    /// What Siri asks before saving `reading`, or nil when it saves without
    /// asking.
    @MainActor
    static func confirmation(for check: MileageReadingCheck, reading: Int, vehicle: Vehicle) -> String? {
        switch check {
        case .plausible:
            return nil
        case .lowerThanCurrent(let current):
            return L10n.siriMileageConfirmLower(
                vehicle: vehicle.displayName,
                current: SpokenValue.mileage(current),
                reading: SpokenValue.mileage(reading)
            )
        case .unusualJump(let current, let increase, _):
            return L10n.siriMileageConfirmJump(
                increase: SpokenValue.mileage(increase),
                vehicle: vehicle.displayName,
                current: SpokenValue.mileage(current),
                reading: SpokenValue.mileage(reading)
            )
        }
    }
}
