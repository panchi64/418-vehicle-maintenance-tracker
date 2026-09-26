//
//  GetVehicleDetailsIntent.swift
//  checkpoint
//
//  "What's my plate in Checkpoint?", "What oil does the Civic take?", "When
//  does my marbete expire?" The reference facts people look up at a parts
//  counter or a checkpoint, answered in a sentence. Siri AI can read the
//  same facts off `VehicleEntity`'s properties; this is the classic-Siri and
//  Shortcuts path, and it returns the value so a shortcut can copy it.
//
//  Asked with no detail, it answers with everything on file.
//

import AppIntents
import SwiftData

/// The facts Get Vehicle Details can answer. Raw values are persisted by
/// saved shortcuts — never rename one.
nonisolated enum VehicleDetail: String, AppEnum, CaseIterable {
    case licensePlate
    case vin
    case oilType
    case tireSize
    case marbete

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Vehicle Detail" }

    static var caseDisplayRepresentations: [VehicleDetail: DisplayRepresentation] {
        [
            .licensePlate: DisplayRepresentation(title: "License Plate", image: .init(systemName: "rectangle.and.text.magnifyingglass")),
            .vin: DisplayRepresentation(title: "VIN", image: .init(systemName: "barcode")),
            .oilType: DisplayRepresentation(title: "Oil Type", image: .init(systemName: "drop.fill")),
            .tireSize: DisplayRepresentation(title: "Tire Size", image: .init(systemName: "circle.circle")),
            .marbete: DisplayRepresentation(title: "Marbete Expiration", image: .init(systemName: "calendar.badge.exclamationmark")),
        ]
    }
}

struct GetVehicleDetailsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Vehicle Details"
    static let description = IntentDescription("Get a vehicle's license plate, VIN, oil type, tire size or marbete expiration")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Detail", description: "Leave empty for everything on file.")
    var detail: VehicleDetail?

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$detail) of \(\.$vehicle)")
    }

    init() {}

    init(vehicle: VehicleEntity? = nil, detail: VehicleDetail?) {
        self.vehicle = vehicle
        self.detail = detail
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let answer = Self.answer(detail, for: vehicle)
        return .result(value: answer.value, dialog: IntentDialog(stringLiteral: answer.sentence))
    }

    /// The value (empty when not on file) and the sentence that says it.
    @MainActor
    static func answer(_ detail: VehicleDetail?, for vehicle: Vehicle) -> (value: String, sentence: String) {
        let name = vehicle.displayName
        guard let detail else {
            let facts = VehicleDetail.allCases.compactMap { detail in
                value(of: detail, for: vehicle).map { L10n.siriDetailFact(detail, value: $0) }
            }
            let summary = facts.isEmpty
                ? L10n.siriDetailNothing(vehicle: name)
                : L10n.siriDetailSummary(vehicle: name, facts: facts.joined(separator: " "))
            return (facts.joined(separator: " "), summary)
        }
        guard let value = value(of: detail, for: vehicle) else {
            return ("", L10n.siriDetailMissing(detail, vehicle: name))
        }
        if detail == .marbete, vehicle.marbeteStatus == .overdue {
            return (value, L10n.siriMarbeteExpired(vehicle: name, month: value))
        }
        return (value, L10n.siriDetail(detail, vehicle: name, value: value))
    }

    /// The fact as stored, or nil when it isn't. The marbete reads as its
    /// month ("March 2027").
    @MainActor
    static func value(of detail: VehicleDetail, for vehicle: Vehicle) -> String? {
        let raw: String?
        switch detail {
        case .licensePlate: raw = vehicle.licensePlate
        case .vin: raw = vehicle.vin
        case .oilType: raw = vehicle.oilType
        case .tireSize: raw = vehicle.tireSize
        case .marbete: raw = vehicle.marbeteExpiration.map(Vehicle.marbeteExpirationLabel)
        }
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        return raw
    }
}
