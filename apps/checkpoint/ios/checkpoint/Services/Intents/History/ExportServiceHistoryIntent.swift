//
//  ExportServiceHistoryIntent.swift
//  checkpoint
//
//  "Export my service history in Checkpoint." The PDF the Services tab
//  exports (`ServiceHistoryPDFService`, same default options), returned as a
//  file so a shortcut can pass it on — "email my service history to my
//  mechanic", save it to Files, attach it to a sale listing.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

struct ExportServiceHistoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Export Service History"
    static let description = IntentDescription("Create a PDF of a vehicle's service history, to share or save")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Export the service history of \(\.$vehicle)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> & ProvidesDialog {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let export = try await Self.export(vehicle)
        return .result(
            value: export.file,
            dialog: IntentDialog(stringLiteral: L10n.siriHistoryExported(count: export.entries, vehicle: vehicle.displayName))
        )
    }

    /// The PDF as a file, and how many entries it lists.
    @MainActor
    static func export(_ vehicle: Vehicle) async throws -> (file: IntentFile, entries: Int) {
        // Newest first, the order the Services tab's query hands the sheet.
        let logs = (vehicle.serviceLogs ?? []).sorted { $0.performedDate > $1.performedDate }
        guard !logs.isEmpty else { throw IntentError.nothingToExport }
        guard let url = await ServiceHistoryPDFService.shared.generatePDF(for: vehicle, serviceLogs: logs) else {
            throw IntentError.exportFailed
        }
        return (IntentFile(fileURL: url, filename: url.lastPathComponent, type: .pdf), logs.count)
    }
}
