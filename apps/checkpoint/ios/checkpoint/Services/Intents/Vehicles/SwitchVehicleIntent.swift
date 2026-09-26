//
//  SwitchVehicleIntent.swift
//  checkpoint
//
//  "Switch to the Civic in Checkpoint." Opens the app on a vehicle's Home,
//  making it the vehicle every intent without one acts on. The iOS 26 path;
//  iOS 27's `.system.open` over vehicles (`OpenVehicleIntent`) is
//  assistant-only, so Shortcuts lists this one once on either version.
//
//  A plain foreground intent rather than an `OpenIntent`: the metadata
//  processor allows one `OpenIntent` per target type ("OpenIntent targets
//  should be unique"), and `OpenVehicleIntent` is that one for vehicles.
//

import AppIntents
import SwiftData

struct SwitchVehicleIntent: AppIntent {
    static let title: LocalizedStringResource = "Switch Vehicle"
    static let description = IntentDescription("Open Checkpoint on a vehicle, making it the one Checkpoint shows")
    static let supportedModes: IntentModes = .foreground

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Switch to \(\.$vehicle)")
    }

    init() {}

    init(vehicle: VehicleEntity) {
        self.vehicle = vehicle
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.vehicle(vehicle.id, in: container.mainContext))
        return .result()
    }
}
