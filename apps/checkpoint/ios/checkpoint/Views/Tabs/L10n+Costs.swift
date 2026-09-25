//
//  L10n+Costs.swift
//  checkpoint
//
//  Strings for the Costs tab. Keys are prefixed `costs.`; the older
//  `costs.*` accessors that other code shares (empty states, the outlier tag,
//  the share subject) stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func costs(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Period

    static var costsPeriodPickerLabel: String { costs("costs.period.picker") }
    static var costsPeriod30D: String { costs("costs.period.30d") }
    static var costsPeriodYTD: String { costs("costs.period.ytd") }
    static var costsPeriod12M: String { costs("costs.period.12m") }
    static var costsPeriodAll: String { costs("costs.period.all") }
    static var costsPeriodShort30D: String { costs("costs.period.short.30d") }
    static var costsPeriodShortYTD: String { costs("costs.period.short.ytd") }
    static var costsPeriodShort12M: String { costs("costs.period.short.12m") }
    static var costsPeriodShortAll: String { costs("costs.period.short.all") }

    // MARK: - Hero

    static func costsHeroAverage(_ amount: String) -> String {
        String(format: costs("costs.hero.average"), amount)
    }
    static func costsHeroAverage12Months(_ amount: String) -> String {
        String(format: costs("costs.hero.average12Months"), amount)
    }
    /// "Year to Date: $1,234" — VoiceOver labels and the shared summary.
    static func costsLabeledValue(_ label: String, _ value: String) -> String {
        String(format: costs("costs.labeledValue"), label, value)
    }
    static var costsShareAction: String { costs("costs.share.action") }

    // MARK: - Cost per distance

    /// "$0.12 per mile driven"
    static func costsCostPerDistance(_ amount: String, unit: DistanceUnit) -> String {
        switch unit {
        case .miles: return String(format: costs("costs.costPerMile"), amount)
        case .kilometers: return String(format: costs("costs.costPerKilometer"), amount)
        }
    }
    /// "Cost per mile" — the VoiceOver label's name half.
    static func costsCostPerDistanceLabel(_ unit: DistanceUnit) -> String {
        switch unit {
        case .miles: return costs("costs.costPerMile.label")
        case .kilometers: return costs("costs.costPerKilometer.label")
        }
    }
    static func costsNoteCostPerDistance(_ unit: DistanceUnit) -> String {
        switch unit {
        case .miles: return costs("costs.note.costPerMile")
        case .kilometers: return costs("costs.note.costPerKilometer")
        }
    }

    // MARK: - Chart

    static var costsChartTrend: String { costs("costs.chart.trend") }
    static var costsChartCategory: String { costs("costs.chart.category") }
    static func costsChartTrendTitle(_ currencyCode: String) -> String {
        String(format: costs("costs.chart.trendTitle"), currencyCode)
    }
    static func costsChartCategoryTitle(_ currencyCode: String) -> String {
        String(format: costs("costs.chart.categoryTitle"), currencyCode)
    }
    static func costsChartTrendSummary(_ average: String, _ peakMonth: String, _ peakAmount: String) -> String {
        String(format: costs("costs.chart.trendSummary"), average, peakMonth, peakAmount)
    }
    static func costsChartCategorySummary(_ category: String, _ percent: Int) -> String {
        String(format: costs("costs.chart.categorySummary"), category, percent)
    }
    static func costsChartSelection(_ month: String, _ amount: String) -> String {
        String(format: costs("costs.chart.selection"), month, amount)
    }
    static func costsCategoryAmountShare(_ amount: String, _ percent: Int) -> String {
        String(format: costs("costs.category.amountShare"), amount, percent)
    }
    static var costsUncategorized: String { costs("costs.category.uncategorized") }

    // MARK: - Insufficient data

    static var costsNoteTrend: String { costs("costs.note.trend") }
    static var costsNoteTrend30Days: String { costs("costs.note.trend30Days") }
    static var costsNoteCategory: String { costs("costs.note.category") }
    static var costsNoteCompare: String { costs("costs.note.compare") }
    static var costsNoteEmptyPeriod: String { costs("costs.note.emptyPeriod") }

    // MARK: - Year comparison

    static func costsCompareTitle(_ thisYear: String, _ lastYear: String) -> String {
        String(format: costs("costs.compare.title"), thisYear, lastYear)
    }
    static func costsCompareMore(_ percent: Int) -> String {
        String(format: costs("costs.compare.more"), percent)
    }
    static func costsCompareLess(_ percent: Int) -> String {
        String(format: costs("costs.compare.less"), percent)
    }
    static var costsCompareSame: String { costs("costs.compare.same") }
    static func costsCompareDetail(_ thisYear: String, _ lastYear: String, _ lastYearName: String) -> String {
        String(format: costs("costs.compare.detail"), thisYear, lastYear, lastYearName)
    }
}
