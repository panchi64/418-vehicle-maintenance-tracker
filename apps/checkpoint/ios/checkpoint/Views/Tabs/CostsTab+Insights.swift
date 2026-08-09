import Foundation

// MARK: - Trend Direction

enum TrendDirection {
    case up, down, flat

    /// "Worse" direction for cost metrics: spending more = up = bad.
    /// Used to pick `Theme.statusOverdue` vs `Theme.statusGood`.
    var isUnfavorable: Bool { self == .up }
}

// MARK: - Repair Cluster Signal

struct RepairClusterSignal: Equatable {
    let count: Int
    let totalAmount: Decimal
    let windowStart: Date
    let windowEnd: Date
}

// MARK: - Pure Helpers

enum CostsInsightsCore {
    /// Detect a repair cluster among the given events. Returns nil unless ≥2
    /// `.repair`-category events fall inside a rolling 90-day window anchored
    /// to the most recent repair.
    static func detectRepairCluster(events: [ExpenseEvent], calendar: Calendar = .current) -> RepairClusterSignal? {
        let repairs = events
            .filter { $0.category == .repair && $0.hasCost }
            .sorted { $0.date > $1.date }

        guard let anchor = repairs.first,
              let windowStart = calendar.date(byAdding: .day, value: -90, to: anchor.date)
        else { return nil }

        let inWindow = repairs.filter { $0.date >= windowStart && $0.date <= anchor.date }
        guard inWindow.count >= 2 else { return nil }

        let total = inWindow.map(\.amount).reduce(0, +)
        return RepairClusterSignal(
            count: inWindow.count,
            totalAmount: total,
            windowStart: windowStart,
            windowEnd: anchor.date
        )
    }

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

    /// Top-N events by amount, descending.
    static func topExpenses(events: [ExpenseEvent], limit: Int = 3) -> [ExpenseEvent] {
        Array(events.sorted { $0.amount > $1.amount }.prefix(limit))
    }

    /// Project YTD spending to year-end given the fraction of the year already
    /// elapsed. Returns nil for early-January (< 2% elapsed) since the
    /// projection isn't meaningful yet.
    static func projectYearEnd(totalSpent: Decimal, now: Date, calendar: Calendar = .current) -> Decimal? {
        guard totalSpent > 0,
              let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
              let yearEnd = calendar.date(from: DateComponents(year: calendar.component(.year, from: now) + 1))
        else { return nil }

        let elapsed = now.timeIntervalSince(yearStart)
        let total = yearEnd.timeIntervalSince(yearStart)
        guard elapsed > 0, elapsed < total else { return nil }

        let fractionElapsed = elapsed / total
        guard fractionElapsed >= 0.02 else { return nil }

        let totalDouble = NSDecimalNumber(decimal: totalSpent).doubleValue
        return Decimal(totalDouble / fractionElapsed)
    }
}

// MARK: - Presentation

/// Everything here reads values `CostsMetrics` already stored — arithmetic,
/// comparisons, and formatting. Nothing in this extension iterates the event
/// list, which is what keeps these safe to read repeatedly from a view body.
extension CostsMetrics {

    // MARK: - Counts and Money

    /// Number of distinct money events (visits + standalone logs with cost).
    /// Not a service count: each log of an un-itemized visit is not its own
    /// expense.
    var serviceCount: Int { events.count }

    var isEmpty: Bool { events.isEmpty }

    var formattedTotalSpent: String { Formatters.currencyWhole(totalSpent) }

    var formattedAverageCost: String {
        guard let averageCost else { return "-" }
        return Formatters.currencyWhole(averageCost)
    }

    var formattedCostPerMile: String {
        guard let costPerMile else { return "-" }
        let unitAbbr = DistanceSettings.shared.unit.abbreviation
        return String(format: "$%.2f/\(unitAbbr)", costPerMile)
    }

    // MARK: - Period Delta

    var periodDeltaAmount: Decimal? {
        guard hasPriorPeriod, priorPeriodTotal > 0 else { return nil }
        return totalSpent - priorPeriodTotal
    }

    var periodDeltaDirection: TrendDirection {
        guard let delta = periodDeltaAmount else { return .flat }
        if delta > 0 { return .up }
        if delta < 0 { return .down }
        return .flat
    }

    // MARK: - Preventive / Reactive / Discretionary Split

    var preventiveShare: Double { categoryShares[.maintenance] ?? 0 }
    var reactiveShare: Double { categoryShares[.repair] ?? 0 }
    var discretionaryShare: Double { categoryShares[.upgrade] ?? 0 }

    // MARK: - Cost-Per-Mile Trend

    var costPerMileDelta: Double? {
        guard let costPerMile, let priorCostPerMile else { return nil }
        return costPerMile - priorCostPerMile
    }

    var costPerMileDeltaDirection: TrendDirection {
        guard let delta = costPerMileDelta else { return .flat }
        if delta > 0.005 { return .up }
        if delta < -0.005 { return .down }
        return .flat
    }

    // MARK: - Labels

    var periodLabel: String {
        switch period {
        case .month: return "Last 30 days"
        case .ytd: return "Year to date"
        case .year: return "Last 12 months"
        case .all: return "All time"
        }
    }

    var priorPeriodLabel: String {
        switch period {
        case .month: return L10n.costsHeadlinePriorMonth
        case .ytd:
            let priorYear = Calendar.current.component(.year, from: Date.now) - 1
            return L10n.costsHeadlinePriorYTD(priorYear)
        case .year: return L10n.costsHeadlinePriorYear
        case .all: return ""
        }
    }

    var shouldShowYearlyRoundup: Bool {
        (period == .year || period == .all) && !events.isEmpty
    }

    // MARK: - Share Summary

    func costShareSummary(vehicle: Vehicle?) -> String {
        var lines: [String] = []

        if let vehicle {
            lines.append("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
        }
        lines.append("\(periodLabel.uppercased()) · \(formattedTotalSpent)")

        if let delta = periodDeltaAmount {
            let absAmount = Formatters.currencyWhole(abs(delta))
            let line: String
            switch periodDeltaDirection {
            case .up: line = L10n.costsHeadlineDeltaUp(absAmount, priorPeriodLabel)
            case .down: line = L10n.costsHeadlineDeltaDown(absAmount, priorPeriodLabel)
            case .flat: line = L10n.costsHeadlineDeltaFlat(priorPeriodLabel)
            }
            lines.append(line)
        }

        if totalSpent > 0 {
            lines.append(L10n.costsHeadlineSplit(
                Int(reactiveShare.rounded()),
                Int(preventiveShare.rounded()),
                Int(discretionaryShare.rounded())
            ))
        }

        if let projection = yearEndProjection {
            lines.append(L10n.costsHeadlineProjection(Formatters.currencyWhole(projection)))
        }

        return lines.joined(separator: "\n")
    }
}
