//
//  UpdateMileageIntent.swift
//  checkpoint
//
//  Siri intent for updating vehicle mileage
//  Opens the app for user confirmation before saving
//  "Hey Siri, update mileage in Checkpoint"
//

import AppIntents
import SwiftUI

/// Intent to update vehicle mileage via Siri
/// Opens the app for user confirmation before saving
struct UpdateMileageIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Vehicle Mileage"
    static var description = IntentDescription("Update the current mileage on your vehicle")

    /// Vehicle is required - Siri will ask "Which vehicle?" if not provided
    @Parameter(
        title: "Vehicle",
        description: "The vehicle to update",
        requestValueDialog: "Which vehicle would you like to update?"
    )
    var vehicle: VehicleEntity

    /// Mileage is required - Siri will ask for the value
    @Parameter(
        title: "Mileage",
        description: "The current mileage reading",
        requestValueDialog: "What is the current mileage?"
    )
    var mileage: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Update mileage on \(\.$vehicle) to \(\.$mileage) miles")
    }

    /// Request opening the app to complete the update
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Store the pending update for the app to process
        PendingMileageUpdate.shared.vehicleID = vehicle.id
        PendingMileageUpdate.shared.mileage = mileage

        return .result(dialog: "Opening Checkpoint to update \(vehicle.displayName) to \(mileage) miles.")
    }
}

// MARK: - Pending Mileage Update Storage

/// Singleton to hold pending mileage update from Siri
/// The app reads this on launch to pre-fill the mileage update sheet
@MainActor
final class PendingMileageUpdate: @unchecked Sendable {
    static let shared = PendingMileageUpdate()

    var vehicleID: String?
    var mileage: Int?

    var hasPendingUpdate: Bool {
        vehicleID != nil && mileage != nil
    }

    func clear() {
        vehicleID = nil
        mileage = nil
    }

    private init() {}
}
