//
//  RecallSeverity.swift
//  checkpoint
//
//  Severity bucketing derived from NHTSA `parkIt` / `parkOutside` flags.
//  Drives ordering and section grouping in the recall sheet.
//

import Foundation

enum RecallSeverity: Int, Comparable, CaseIterable {
    case open = 0
    case parkOutside = 1
    case parkIt = 2

    static func < (lhs: RecallSeverity, rhs: RecallSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Sort key: higher severity buckets render first in the sheet.
    var sortPriority: Int { -rawValue }

    /// Localized label used by section headers and the compact card. Always sentence-case;
    /// callers uppercase as needed for brutalist display.
    var label: String {
        switch self {
        case .parkIt: L10n.recallSeverityDoNotDrive
        case .parkOutside: L10n.recallSeverityParkOutside
        case .open: L10n.recallSeverityOpen
        }
    }
}

extension RecallInfo {
    var severity: RecallSeverity {
        if parkIt { return .parkIt }
        if parkOutside { return .parkOutside }
        return .open
    }
}

extension Array where Element == RecallInfo {
    /// Groups recalls by severity (highest first), each group sorted newest-first.
    /// Empty buckets are omitted so callers can detect single-bucket cases.
    func groupedBySeverity() -> [(severity: RecallSeverity, recalls: [RecallInfo])] {
        let buckets = Dictionary(grouping: self, by: \.severity)
        return RecallSeverity.allCases
            .sorted { $0.sortPriority < $1.sortPriority }
            .compactMap { severity in
                guard let group = buckets[severity], !group.isEmpty else { return nil }
                return (severity, group.sortedNewestFirst())
            }
    }

    /// Worst severity present in the set, or `.open` when empty.
    var worstSeverity: RecallSeverity {
        map(\.severity).max() ?? .open
    }
}

extension Array where Element == RecallAcknowledgment {
    /// Filters to a single vehicle's acks and returns them keyed by campaign number.
    /// Conflicts (shouldn't happen — schema is unique on the pair) keep the first.
    func dictionary(forVehicle vehicleID: UUID) -> [String: RecallAcknowledgment] {
        Dictionary(
            filter { $0.vehicleID == vehicleID }.map { ($0.campaignNumber, $0) },
            uniquingKeysWith: { lhs, _ in lhs }
        )
    }
}
