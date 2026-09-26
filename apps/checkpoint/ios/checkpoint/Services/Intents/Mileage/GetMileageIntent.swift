//
//  GetMileageIntent.swift
//  checkpoint
//
//  "What's the mileage on my Civic?" The last reading and when it was taken,
//  or — when driving pace supports one — the projected mileage today with the
//  pace behind it, the same estimate the Home header shows
//  (`Vehicle.mileageEstimate`).
//

import AppIntents
import SwiftData

struct GetMileageIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Vehicle Mileage"
    static let description = IntentDescription("Hear your vehicle's current mileage, estimated from your driving pace when the last reading is old")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get the mileage on \(\.$vehicle)")
    }

    init() {}

    init(vehicle: VehicleEntity?) {
        self.vehicle = vehicle
    }

    /// Returns the effective mileage in the user's distance unit, so a
    /// Shortcut can do arithmetic with what Siri said.
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let estimate = vehicle.mileageEstimate
        return .result(
            value: DistanceSettings.shared.unit.fromMiles(estimate.effective),
            dialog: IntentDialog(stringLiteral: Self.answer(for: vehicle, estimate: estimate))
        )
    }

    @MainActor
    static func answer(for vehicle: Vehicle, estimate: MileageEstimate) -> String {
        guard let recordedAt = vehicle.mileageUpdatedAt else {
            guard vehicle.currentMileage > 0 else { return L10n.siriMileageNone(vehicle: vehicle.displayName) }
            // Entered at setup and never updated: a reading with no date.
            return L10n.siriMileageCurrent(vehicle: vehicle.displayName, mileage: SpokenValue.mileage(vehicle.currentMileage))
        }
        let recorded = SpokenValue.mileage(vehicle.currentMileage)
        let date = SpokenValue.date(recordedAt)
        guard estimate.isEstimated, let pace = estimate.pace else {
            return L10n.siriMileageRecorded(vehicle: vehicle.displayName, mileage: recorded, date: date)
        }
        return L10n.siriMileageEstimated(
            vehicle: vehicle.displayName,
            estimate: SpokenValue.mileage(estimate.effective),
            pace: SpokenValue.mileage(Int(pace.rounded())),
            recorded: recorded,
            date: date
        )
    }
}
