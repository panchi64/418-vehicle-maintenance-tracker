//
//  L10n+Import.swift
//  checkpoint
//
//  Strings for the CSV import flow. Keys are prefixed `import.`.
//
//  The error and warning accessors are `nonisolated` because
//  `CSVImportService` builds them off the main actor while parsing.
//

import Foundation

extension L10n {
    nonisolated private static func importString(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Chrome

    static var importNavTitle: String { importString("import.navTitle") }
    static var importConfirmTitle: String { importString("import.confirm.title") }
    static var importConfirmAction: String { importString("import.confirm.action") }
    /// "Import 4 services with 12 logs to Daily Driver?"
    static func importConfirmMessage(services: Int, logs: Int, vehicle: String) -> String {
        String(format: importString("import.confirm.message"), services, logs, vehicle)
    }
    static var importConfirmFallbackVehicle: String { importString("import.confirm.fallbackVehicle") }
    static var importSelectVehicleError: String { importString("import.error.selectVehicle") }

    // MARK: - Steps

    static var importStepSelectFile: String { importString("import.step.selectFile") }
    static var importStepConfigure: String { importString("import.step.configure") }
    static var importStepPreview: String { importString("import.step.preview") }
    static var importStepComplete: String { importString("import.step.complete") }

    // MARK: - Pick file

    static var importPickTitle: String { importString("import.pick.title") }
    static var importPickBody: String { importString("import.pick.body") }
    static var importPickFormats: String { importString("import.pick.formats") }
    static var importPickButton: String { importString("import.pick.button") }

    // MARK: - Configure

    static var importSourceFormat: String { importString("import.configure.sourceFormat") }
    static var importSourceDetected: String { importString("import.configure.detected") }
    static var importSourceCustom: String { importString("import.configure.sourceCustom") }
    static var importColumnMapping: String { importString("import.configure.columnMapping") }
    static var importColumnDate: String { importString("import.configure.column.date") }
    static var importColumnServiceName: String { importString("import.configure.column.serviceName") }
    static var importColumnOdometer: String { importString("import.configure.column.odometer") }
    static var importColumnCost: String { importString("import.configure.column.cost") }
    static var importColumnNotes: String { importString("import.configure.column.notes") }
    static var importColumnNone: String { importString("import.configure.column.none") }
    static var importDataPreview: String { importString("import.configure.dataPreview") }
    static var importPreviewButton: String { importString("import.configure.previewButton") }
    static var importNoValidRows: String { importString("import.configure.noValidRows") }

    // MARK: - Preview

    static var importSummary: String { importString("import.preview.summary") }
    static var importStatServices: String { importString("import.stat.services") }
    static var importStatLogs: String { importString("import.stat.logs") }
    static var importStatTotalCost: String { importString("import.stat.totalCost") }
    static var importStatTotal: String { importString("import.stat.total") }
    static var importServicesToCreate: String { importString("import.preview.servicesToCreate") }
    static func importLogCount(_ count: Int) -> String {
        String(format: importString("import.preview.logCount"), count)
    }
    static var importAssignVehicle: String { importString("import.preview.assignVehicle") }
    static var importCreateVehicle: String { importString("import.preview.createVehicle") }
    static var importVehicleNamePlaceholder: String { importString("import.preview.vehicleName") }
    static func importWarningsHeader(_ count: Int) -> String {
        String(format: importString("import.preview.warnings"), count)
    }
    static func importMoreWarnings(_ count: Int) -> String {
        String(format: importString("import.preview.moreWarnings"), count)
    }
    static var importComplete: String { importString("import.success.title") }

    // MARK: - Parse errors and warnings (built off the main actor)

    nonisolated static var importErrorFileReadFailed: String { importString("import.error.fileReadFailed") }
    nonisolated static var importErrorEmptyFile: String { importString("import.error.emptyFile") }
    nonisolated static var importErrorNoHeaderRow: String { importString("import.error.noHeaderRow") }
    nonisolated static var importErrorNoDataRows: String { importString("import.error.noDataRows") }
    nonisolated static var importErrorNoDateColumn: String { importString("import.error.noDateColumn") }
    nonisolated static var importErrorNoDescriptionColumn: String { importString("import.error.noDescriptionColumn") }
    nonisolated static var importErrorInvalidFormat: String { importString("import.error.invalidFormat") }

    nonisolated static func importWarningMissingName(row: Int) -> String {
        String(format: importString("import.warning.missingName"), row)
    }
    nonisolated static func importWarningBadDate(row: Int, value: String) -> String {
        String(format: importString("import.warning.badDate"), row, value)
    }
}

extension CSVImportSource {
    /// Brand names stay as-is; only the generic option is translated.
    var displayName: String {
        self == .custom ? L10n.importSourceCustom : rawValue
    }
}

extension CSVImportStep {
    var title: String {
        switch self {
        case .pickFile: return L10n.importStepSelectFile
        case .configure: return L10n.importStepConfigure
        case .preview: return L10n.importStepPreview
        case .success: return L10n.importStepComplete
        }
    }
}
