import Foundation

// MARK: - Pure Helpers

enum CostsInsightsCore {
    /// IDs of events whose amount is more than 2× the average across the
    /// supplied event set. Returns an empty set when fewer than 3 events are
    /// present (anomaly detection needs a meaningful baseline).
    static func detectAnomalies(events: [ExpenseEvent]) -> Set<UUID> {
        guard events.count >= 3 else { return [] }
        let total = events.map(\.amount).reduce(0, +)
        guard total > 0 else { return [] }
        let average = total / Decimal(events.count)
        let threshold = average * 2
        return Set(events.filter { $0.amount > threshold }.map(\.id))
    }
}

// MARK: - Presentation

/// Everything here reads values `CostsMetrics` already stored — arithmetic,
/// comparisons, and formatting. Nothing in this extension iterates the event
/// list, which is what keeps these safe to read repeatedly from a view body.
extension CostsMetrics {

    var isEmpty: Bool { events.isEmpty }

    var formattedTotalSpent: String { Formatters.currencyWhole(totalSpent) }

    /// "USD" — the chart titles carry their unit.
    var currencyCode: String { Formatters.currencyWhole.currencyCode ?? "USD" }

    // MARK: - Hero

    /// "$330 a month on average", or its 12-month form for 30D.
    var averageLine: String? {
        guard let monthlyAverage else { return nil }
        let amount = Formatters.currencyWhole(monthlyAverage)
        return averageIsTwelveMonth
            ? L10n.costsHeroAverage12Months(amount)
            : L10n.costsHeroAverage(amount)
    }

    /// The amount inside `averageLine`, so the view can set it in a heavier
    /// face without concatenating a sentence.
    var formattedMonthlyAverage: String? {
        monthlyAverage.map { Formatters.currencyWhole($0) }
    }

    // MARK: - Cost per distance

    /// Period spend per mile (or kilometer) driven. nil when the period has too
    /// little odometer data to measure a distance.
    func costPerDistance(in unit: DistanceUnit) -> Decimal? {
        guard let milesDriven else { return nil }
        let distance = unit.fromMiles(Double(milesDriven))
        guard distance > 0 else { return nil }
        return totalSpent / Decimal(distance)
    }

    /// "$0.12" — cents matter at this scale.
    func formattedCostPerDistance(in unit: DistanceUnit) -> String? {
        costPerDistance(in: unit).flatMap {
            Formatters.currency.string(from: $0 as NSDecimalNumber)
        }
    }

    // MARK: - Chart

    func chartTitle(_ mode: CostsTab.ChartMode) -> String {
        switch mode {
        case .trend: return L10n.costsChartTrendTitle(currencyCode)
        case .category: return L10n.costsChartCategoryTitle(currencyCode)
        }
    }

    func chartIsReady(_ mode: CostsTab.ChartMode) -> Bool {
        switch mode {
        case .trend: return trendIsReady
        case .category: return categoryIsReady
        }
    }

    /// What will make the chart appear, when it can't yet.
    func chartNote(_ mode: CostsTab.ChartMode) -> String {
        switch mode {
        case .trend:
            return period == .last30Days ? L10n.costsNoteTrend30Days : L10n.costsNoteTrend
        case .category:
            return L10n.costsNoteCategory
        }
    }

    /// The chart's point in words — always shown, so the picture is never the
    /// only carrier of it. "Averages $210 a month; highest March, $1,317."
    func chartSummary(_ mode: CostsTab.ChartMode) -> String {
        switch mode {
        case .trend:
            guard let peak = trend.max(by: { $0.amount < $1.amount }), !trend.isEmpty else { return "" }
            let sum = trend.reduce(Decimal(0)) { $0 + $1.amount }
            return L10n.costsChartTrendSummary(
                Formatters.currencyWhole(sum / Decimal(trend.count)),
                trendMonthName(peak.month),
                Formatters.currencyWhole(peak.amount)
            )
        case .category:
            guard let top = bucketShares.first else { return "" }
            return L10n.costsChartCategorySummary(top.bucket.displayName, Int((top.fraction * 100).rounded()))
        }
    }

    /// The scrub readout for one bar: "June 2026 — $320".
    func trendSelectionLine(_ month: CostMonth) -> String {
        L10n.costsChartSelection(
            month.month.formatted(.dateTime.month(.wide).year()),
            Formatters.currencyWhole(month.amount)
        )
    }

    /// Month name as the summary sentence says it — with the year once the
    /// chart spans more than one of them.
    private func trendMonthName(_ month: Date) -> String {
        trend.count > 12
            ? month.formatted(.dateTime.month(.wide).year())
            : month.formatted(.dateTime.month(.wide))
    }

    // MARK: - Comparison

    var comparisonTitle: String {
        L10n.costsCompareTitle(String(currentYear), String(currentYear - 1))
    }

    func comparisonHeadline(_ comparison: CostYearComparison) -> String {
        let magnitude = abs(comparison.percentChange)
        if comparison.percentChange > 0 { return L10n.costsCompareMore(magnitude) }
        if comparison.percentChange < 0 { return L10n.costsCompareLess(magnitude) }
        return L10n.costsCompareSame
    }

    func comparisonDetail(_ comparison: CostYearComparison) -> String {
        L10n.costsCompareDetail(
            Formatters.currencyWhole(comparison.thisYearTotal),
            Formatters.currencyWhole(comparison.lastYearTotal),
            String(comparison.year - 1)
        )
    }

    // MARK: - Share

    /// Plain-text summary for the hero's Share action.
    func shareSummary(vehicle: Vehicle?) -> String {
        var lines: [String] = []
        if let vehicle {
            lines.append(vehicle.identityLine)
        }
        lines.append(L10n.costsLabeledValue(period.fullName, formattedTotalSpent))
        if let averageLine {
            lines.append(averageLine)
        }
        if let comparison {
            lines.append(L10n.costsLabeledValue(comparisonTitle, comparisonHeadline(comparison)))
        }
        return lines.joined(separator: "\n")
    }
}
