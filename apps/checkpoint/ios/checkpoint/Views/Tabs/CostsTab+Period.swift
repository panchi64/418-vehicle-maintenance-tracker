//
//  CostsTab+Period.swift
//  checkpoint
//
//  The Costs tab's two pieces of view state: the period (the one control —
//  it scopes every number on the screen) and which picture the chart section
//  shows. See tools/sketchpad/src/screens/CostsTab.tsx for the rationale.
//

import Foundation

extension CostsTab {

    /// `30D / YTD / 12M / All`. 90D was dropped for 12M, the period that
    /// actually smooths annual insurance and marbete spikes out of an average.
    ///
    /// Raw values are **storage** — they are sent with `costsPeriodChanged`
    /// and must stay stable across relabels. `shortName` / `fullName` are what
    /// reach the screen.
    enum PeriodFilter: String, CaseIterable, Identifiable {
        case last30Days = "Month"
        case yearToDate = "YTD"
        case last12Months = "Year"
        case allTime = "All"

        var id: String { rawValue }

        /// The segment label.
        var shortName: String {
            switch self {
            case .last30Days: return L10n.costsPeriodShort30D
            case .yearToDate: return L10n.costsPeriodShortYTD
            case .last12Months: return L10n.costsPeriodShort12M
            case .allTime: return L10n.costsPeriodShortAll
            }
        }

        /// The hero's section title, and the segment's spoken label.
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
    }

    /// What the one chart section draws. Plain chips, not a second segmented
    /// control: the period changes every number, this changes one picture.
    enum ChartMode: CaseIterable, Identifiable {
        case trend
        case category

        var id: Self { self }

        var label: String {
            switch self {
            case .trend: return L10n.costsChartTrend
            case .category: return L10n.costsChartCategory
            }
        }
    }
}
