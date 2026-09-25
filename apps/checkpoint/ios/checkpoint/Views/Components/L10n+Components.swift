//
//  L10n+Components.swift
//  checkpoint
//
//  Visible strings for shared components: attachments, the marbete picker,
//  reminder-impact rows, the notes editor, vehicle pickers, and the service
//  history export (sheet and PDF). Keys are prefixed `attach.`, `marbete.`,
//  `impact.`, `notes.`, `picker.`, and `export.`.
//
//  The `export.` accessors are `nonisolated`: the PDF renders off the main
//  actor.
//

import Foundation

extension L10n {
    nonisolated private static func component(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Attachments

    static var attachSourcePhoto: String { component("attach.source.photo") }
    static var attachSourcePDF: String { component("attach.source.pdf") }
    static var attachSourceReceipt: String { component("attach.source.receipt") }
    static var attachScanFailed: String { component("attach.scanFailed") }
    static var attachOpenDetailHint: String { component("attach.openDetailHint") }

    // MARK: - Marbete picker

    static var marbeteExpirationMonth: String { component("marbete.expirationMonth") }
    static var marbeteExpirationYear: String { component("marbete.expirationYear") }
    static var marbeteNotSet: String { component("marbete.notSet") }
    static var marbeteExpired: String { component("marbete.status.expired") }
    static var marbeteExpiresSoon: String { component("marbete.status.expiresSoon") }
    static var marbeteValid: String { component("marbete.status.valid") }
    /// VoiceOver: "Marbete status: Expires soon".
    static func marbeteStatusLabel(_ status: String) -> String {
        String(format: component("marbete.statusLabel"), status)
    }
    /// "November 2026" — month name, then year.
    static func marbeteMonthYear(_ month: String, _ year: Int) -> String {
        String(format: component("marbete.monthYear"), month, year)
    }

    // MARK: - Reminder impact

    /// "Mar 12 → Jun 12": the reminder before, then after, the edit.
    static func impactChange(_ before: String, _ after: String) -> String {
        String(format: component("impact.change"), before, after)
    }
    static func impactMonths(_ months: Int) -> String {
        months == 1
            ? component("impact.months.one")
            : String(format: component("impact.months.other"), months)
    }

    // MARK: - Notes editor

    static var notesFormatBold: String { component("notes.format.bold") }
    static var notesFormatBullets: String { component("notes.format.bullets") }
    static var notesFormatNumbered: String { component("notes.format.numbered") }

    // MARK: - Pickers

    static var pickerLinkVehicles: String { component("picker.linkVehicles") }
    static var pickerSelectVehicle: String { component("picker.selectVehicle") }

    // MARK: - Export sheet

    static var exportTitle: String { component("export.title") }
    static var exportIncludeTotal: String { component("export.includeTotal") }
    static var exportIncludeTotalDetail: String { component("export.includeTotalDetail") }
    static var exportGenerate: String { component("export.generate") }
    static var exportFailed: String { component("export.failed") }

    // MARK: - Export PDF (rendered off the main actor)

    nonisolated static func exportServiceCount(_ count: Int) -> String {
        count == 1
            ? component("export.serviceCount.one")
            : String(format: component("export.serviceCount.other"), count)
    }
    nonisolated static func exportPlate(_ plate: String) -> String {
        String(format: component("export.pdf.plate"), plate)
    }
    nonisolated static func exportVIN(_ vin: String) -> String {
        String(format: component("export.pdf.vin"), vin)
    }
    nonisolated static var exportPDFServiceFallback: String { component("export.pdf.serviceFallback") }
    nonisolated static var exportPDFHistoryHeader: String { component("export.pdf.historyHeader") }
    nonisolated static var exportPDFReportSubtitle: String { component("export.pdf.reportSubtitle") }
    nonisolated static var exportPDFEmpty: String { component("export.pdf.empty") }
    nonisolated static var exportPDFTotalSpent: String { component("export.pdf.totalSpent") }
    nonisolated static func exportPDFFooter(_ date: String) -> String {
        String(format: component("export.pdf.footer"), date)
    }
    nonisolated static func exportPDFPage(_ number: Int) -> String {
        String(format: component("export.pdf.page"), number)
    }
}
