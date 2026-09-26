//
//  CostPeriod.swift
//  checkpoint
//
//  The window a cost figure covers: `30D / YTD / 12M / All`. The Costs tab's
//  one control, and the period Siri and Shortcuts ask spending questions in.
//
//  90D was dropped for 12M, the period that actually smooths annual insurance
//  and marbete spikes out of an average.
//

import Foundation

/// Raw values are **storage** — they are sent with `costsPeriodChanged` and
/// must stay stable across relabels. `shortName` / `fullName` are what reach
/// the screen.
///
/// `nonisolated` so App Intents can use it as an `AppEnum`; only the labels,
/// which read the main-actor `L10n`, are main-actor bound.
nonisolated enum CostPeriod: String, CaseIterable, Identifiable, Sendable {
    case last30Days = "Month"
    case yearToDate = "YTD"
    case last12Months = "Year"
    case allTime = "All"

    var id: String { rawValue }

    /// The segment label.
    @MainActor
    var shortName: String {
        switch self {
        case .last30Days: return L10n.costsPeriodShort30D
        case .yearToDate: return L10n.costsPeriodShortYTD
        case .last12Months: return L10n.costsPeriodShort12M
        case .allTime: return L10n.costsPeriodShortAll
        }
    }

    /// The hero's section title, and the segment's spoken label.
    @MainActor
    var fullName: String {
        switch self {
        case .last30Days: return L10n.costsPeriod30D
        case .yearToDate: return L10n.costsPeriodYTD
        case .last12Months: return L10n.costsPeriod12M
        case .allTime: return L10n.costsPeriodAll
        }
    }

    /// Clock-injected, so a derivation that takes a fixed `now` — and the
    /// tests around it — window the same events it reports on. nil = no
    /// lower bound.
    func startDate(now: Date, calendar: Calendar) -> Date? {
        switch self {
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .yearToDate:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .last12Months:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .allTime:
            return nil
        }
    }

    /// Whether `date` falls inside the period: on or after its start, and not
    /// in the future.
    func contains(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        guard date <= now else { return false }
        return startDate(now: now, calendar: calendar).map { date >= $0 } ?? true
    }
}
