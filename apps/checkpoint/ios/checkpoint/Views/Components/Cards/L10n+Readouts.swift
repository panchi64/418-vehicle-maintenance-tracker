//
//  L10n+Readouts.swift
//  checkpoint
//
//  VoiceOver strings (and a few visible ones) for readout cards, rows, tabs,
//  and charts.
//
//  Kept apart from L10n.swift so parallel accessibility work doesn't collide
//  in one file. Keys are prefixed `readout.`. Every label describes the datum
//  ("Oil change, due soon, 1,200 miles left"), not the layout.
//

import Foundation

extension L10n {
    private static func readout(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Spoken values

    /// A distance with its unit spelled out, for VoiceOver: "1,200 miles".
    /// The visual forms ("1,200_MI", "1,200 mi") are read aloud as
    /// "underscore M I" or guessed at, so labels use this instead.
    static func spokenDistance(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let dimension: UnitLength = unit == .kilometers ? .kilometers : .miles
        return Measurement(value: Double(unit.fromMiles(miles)), unit: dimension)
            .formatted(.measurement(
                width: .wide,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            ))
    }

    /// A calendar date in full, for VoiceOver: "June 6, 2026", never "6/6".
    static func spokenDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }

    // MARK: - Status

    /// Spoken status word. `.neutral` has no visible label; it reads as
    /// "Scheduled" so the element never opens with an empty pause.
    static func readoutStatus(_ status: ServiceStatus) -> String {
        switch status {
        case .overdue: readout("readout.statusOverdue")
        case .dueSoon: readout("readout.statusDueSoon")
        case .good: readout("readout.statusGood")
        case .neutral: readout("readout.statusScheduled")
        }
    }

    /// A value followed by the status it carries: "300 mi left, Due soon".
    static func readoutValueWithStatus(_ value: String, _ status: String) -> String {
        String(format: readout("readout.valueWithStatus"), value, status)
    }

    static var readoutMileageUpdateDue: String { readout("readout.mileageUpdateDue") }

    // MARK: - Next Up

    /// Mileage-tracked service. Args: status, distance phrase ("1,200 miles
    /// left"), due-at distance.
    static func readoutNextUpMileage(_ status: String, _ distance: String, _ dueAt: String) -> String {
        String(format: readout("readout.nextUpMileage"), status, distance, dueAt)
    }
    /// As above, plus the projected due period ("mid June").
    static func readoutNextUpMileageEstimate(_ status: String, _ distance: String, _ dueAt: String, _ period: String) -> String {
        String(format: readout("readout.nextUpMileageEstimate"), status, distance, dueAt, period)
    }
    /// Date-only service. Args: status, full due date.
    static func readoutNextUpDate(_ status: String, _ date: String) -> String {
        String(format: readout("readout.nextUpDate"), status, date)
    }
    /// Marbete renewal. Args: status, full expiration date.
    static func readoutMarbeteExpires(_ status: String, _ date: String) -> String {
        String(format: readout("readout.marbeteExpires"), status, date)
    }
    static func readoutDistanceLeft(_ distance: String) -> String {
        String(format: readout("readout.distanceLeft"), distance)
    }
    static func readoutDistanceOverdue(_ distance: String) -> String {
        String(format: readout("readout.distanceOverdue"), distance)
    }

    // MARK: - Rows

    /// A history or expense row: name, then date.
    static func readoutEvent(_ name: String, _ date: String) -> String {
        String(format: readout("readout.event"), name, date)
    }
    /// As `readoutEvent`, flagged as a statistical outlier.
    static func readoutEventOutlier(_ name: String, _ date: String) -> String {
        String(format: readout("readout.eventOutlier"), name, date)
    }
    static var readoutExpanded: String { readout("readout.expanded") }
    static var readoutCollapsed: String { readout("readout.collapsed") }

    // MARK: - Cards

    static func readoutCategoryShare(_ category: String, _ amount: String, _ percent: Int) -> String {
        String(format: readout("readout.categoryShare"), category, amount, percent)
    }
    static var readoutShareCostSummary: String { readout("readout.shareCostSummary") }
    static func readoutOdometer(_ distance: String) -> String {
        String(format: readout("readout.odometer"), distance)
    }
    static func readoutOdometerEstimated(_ distance: String) -> String {
        String(format: readout("readout.odometerEstimated"), distance)
    }
    static var readoutDismissVisitSuggestion: String { readout("readout.dismissVisitSuggestion") }
    static var readoutDismissHint: String { readout("readout.dismissHint") }
    static var readoutClose: String { readout("readout.close") }

    /// Visible recall count on the Home alert: "1 recall" / "3 recalls".
    static func readoutRecallCount(_ count: Int) -> String {
        count == 1
            ? readout("readout.recallCountOne")
            : String(format: readout("readout.recallCountOther"), count)
    }
    static var readoutUpdateRecallStatus: String { readout("readout.updateRecallStatus") }

    // Vehicle specs panel
    static var readoutVehicleNotes: String { readout("readout.vehicleNotes") }
    static var readoutReadFullNotesHint: String { readout("readout.readFullNotesHint") }
    static var readoutEditVehicleSpecs: String { readout("readout.editVehicleSpecs") }
    static var readoutAddVehicleSpecs: String { readout("readout.addVehicleSpecs") }
    static var readoutCopyHint: String { readout("readout.copyHint") }
    static var readoutDocumentsNone: String { readout("readout.documentsNone") }
    static func readoutDocumentsSaved(_ count: Int) -> String {
        String(format: readout("readout.documentsSaved"), count)
    }

    /// Advisory message with its spoken severity: "Warning: …".
    static func readoutAdvisory(_ severity: String, _ message: String) -> String {
        String(format: readout("readout.advisory"), severity, message)
    }

    // MARK: - Charts

    static var readoutChartAxisMonth: String { readout("readout.chartAxisMonth") }
    static var readoutChartAxisAmount: String { readout("readout.chartAxisAmount") }
    static var readoutChartSeriesSpending: String { readout("readout.chartSeriesSpending") }
}
