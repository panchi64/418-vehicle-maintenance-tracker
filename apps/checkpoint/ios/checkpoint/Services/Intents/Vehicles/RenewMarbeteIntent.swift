//
//  RenewMarbeteIntent.swift
//  checkpoint
//
//  "I renewed my marbete in Checkpoint." Home's Mark Renewed by voice: the
//  marbete renews for a year in the same month, so a renewal has one outcome
//  (`Vehicle.renewedMarbeteExpiration`) and Siri only confirms it, naming the
//  month it moves to, before writing through `MarbeteRenewal`.
//

import AppIntents
import SwiftData

struct RenewMarbeteIntent: AppIntent {
    static let title: LocalizedStringResource = "Renew Marbete"
    static let description = IntentDescription("Record that you renewed a vehicle's marbete. It moves to the same month next year.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Renew the marbete of \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let renewed = try Self.renewal(for: vehicle)
        let month = Vehicle.marbeteExpirationLabel(renewed)

        try await requestConfirmation(
            actionName: .set,
            dialog: IntentDialog(stringLiteral: L10n.siriMarbeteRenewConfirm(vehicle: vehicle.displayName, month: month))
        )

        try Self.renew(vehicle, to: renewed, in: context)
        return .result(
            value: VehicleEntity(model: vehicle),
            dialog: IntentDialog(stringLiteral: L10n.siriMarbeteRenewed(vehicle: vehicle.displayName, month: month))
        )
    }

    /// Where a renewal moves the marbete. Throws when none is on file.
    @MainActor
    static func renewal(for vehicle: Vehicle, now: Date = .now) throws -> Vehicle.MarbeteExpiration {
        guard let renewed = vehicle.renewedMarbeteExpiration(now: now) else { throw IntentError.noMarbete }
        return renewed
    }

    /// The write, once confirmed.
    @MainActor
    static func renew(_ vehicle: Vehicle, to expiration: Vehicle.MarbeteExpiration, in context: ModelContext) throws {
        MarbeteRenewal.apply(expiration, to: vehicle)
        try IntentStore.save(context)
    }
}
