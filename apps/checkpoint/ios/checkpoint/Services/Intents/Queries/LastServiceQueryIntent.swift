//
//  LastServiceQueryIntent.swift
//  checkpoint
//
//  "When did I last change the oil in Checkpoint?" The newest history entry
//  whose service name contains what was said, on the vehicle asked about,
//  ignoring case and accents — "oil" finds "Oil Change". Notes are not
//  searched: a note mentioning oil doesn't make a log an oil change.
//

import AppIntents
import SwiftData

struct LastServiceQueryIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Last Service"
    static let description = IntentDescription("Find when a service was last done on your vehicle")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service", description: "e.g. oil change", requestValueDialog: "Which service?")
    var service: String

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("When was \(\.$service) last done on \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceLogEntity?> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let last = try Self.lastLog(matching: service, on: vehicle, in: context)
        guard let last else {
            return .result(value: nil, dialog: IntentDialog(stringLiteral: L10n.siriLastServiceNone(
                search: service,
                vehicle: vehicle.displayName
            )))
        }
        return .result(value: last, dialog: IntentDialog(stringLiteral: L10n.siriLastService(
            service: last.serviceName,
            vehicle: vehicle.displayName,
            date: SpokenValue.date(last.performedDate),
            mileage: SpokenValue.mileage(last.mileage)
        )))
    }

    /// Newest first, so the first match on the vehicle is the last time.
    @MainActor
    static func lastLog(matching text: String, on vehicle: Vehicle, in context: ModelContext) throws -> ServiceLogEntity? {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }
        let match = try ServiceLogEntity.models(ids: nil, in: context).first { log in
            log.vehicle?.id == vehicle.id && (log.service?.name.localizedStandardContains(needle) ?? false)
        }
        return match.map { ServiceLogEntity(model: $0) }
    }
}
