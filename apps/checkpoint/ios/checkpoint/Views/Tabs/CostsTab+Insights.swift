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

// MARK: - Insights Extension

extension CostsTab {

    // MARK: - Prior-Period Window

    var priorPeriodRange: (start: Date, end: Date)? {
        let now = Date.now
        let calendar = Calendar.current

        switch periodFilter {
        case .month:
            guard let priorEnd = calendar.date(byAdding: .month, value: -1, to: now),
                  let priorStart = calendar.date(byAdding: .month, value: -2, to: now)
            else { return nil }
            return (priorStart, priorEnd)
        case .ytd:
            // Same DOY range one year earlier.
            guard let priorEnd = calendar.date(byAdding: .year, value: -1, to: now),
                  let priorStart = calendar.date(from: calendar.dateComponents([.year], from: priorEnd))
            else { return nil }
            return (priorStart, priorEnd)
        case .year:
            guard let priorEnd = calendar.date(byAdding: .year, value: -1, to: now),
                  let priorStart = calendar.date(byAdding: .year, value: -2, to: now)
            else { return nil }
            return (priorStart, priorEnd)
        case .all:
            return nil
        }
    }

    /// Applies the active category filter so a "repair-only" delta compares
    /// repair-to-repair, not repair-to-everything.
    var priorPeriodEvents: [ExpenseEvent] {
        guard let range = priorPeriodRange else { return [] }

        var events = vehicleEvents.filter { $0.date >= range.start && $0.date < range.end }
        if let category = categoryFilter.costCategory {
            events = events.filter { $0.category == category }
        }
        return events.filter { $0.hasCost }
    }

    var priorPeriodTotal: Decimal {
        priorPeriodEvents.map(\.amount).reduce(0, +)
    }

    // MARK: - Period Delta

    var periodDeltaAmount: Decimal? {
        guard priorPeriodRange != nil, priorPeriodTotal > 0 else { return nil }
        return totalSpent - priorPeriodTotal
    }

    var periodDeltaDirection: TrendDirection {
        guard let delta = periodDeltaAmount else { return .flat }
        if delta > 0 { return .up }
        if delta < 0 { return .down }
        return .flat
    }

    var priorPeriodLabel: String {
        switch periodFilter {
        case .month: return L10n.costsHeadlinePriorMonth
        case .ytd:
            let priorYear = Calendar.current.component(.year, from: Date.now) - 1
            return L10n.costsHeadlinePriorYTD(priorYear)
        case .year: return L10n.costsHeadlinePriorYear
        case .all: return ""
        }
    }

    // MARK: - Preventive / Reactive / Discretionary Split

    var preventiveShare: Double { categoryShare(.maintenance) }
    var reactiveShare: Double { categoryShare(.repair) }
    var discretionaryShare: Double { categoryShare(.upgrade) }

    private func categoryShare(_ category: CostCategory) -> Double {
        guard totalSpent > 0 else { return 0 }
        let amount = eventsWithCosts
            .filter { $0.category == category }
            .map(\.amount)
            .reduce(0, +)
        let ratio = (amount as NSDecimalNumber).doubleValue / (totalSpent as NSDecimalNumber).doubleValue
        return ratio * 100
    }

    // MARK: - Year-End Projection

    /// Returns nil unless `periodFilter == .ytd` — see `CostsInsightsCore`
    /// for the projection math (early-January gated to avoid noise).
    var yearEndProjection: Decimal? {
        guard periodFilter == .ytd else { return nil }
        return CostsInsightsCore.projectYearEnd(totalSpent: totalSpent, now: .now)
    }

    // MARK: - Repair Cluster Detection

    /// Operates on all vehicle events (not the filtered set) so the warning
    /// shows even when the user has narrowed to a single category.
    var repairCluster: RepairClusterSignal? {
        CostsInsightsCore.detectRepairCluster(events: vehicleEvents)
    }

    // MARK: - Top Expenses

    var topExpenses: [ExpenseEvent] {
        CostsInsightsCore.topExpenses(events: eventsWithCosts)
    }

    // MARK: - Anomaly Detection

    var anomalyEventIDs: Set<UUID> {
        CostsInsightsCore.detectAnomalies(events: eventsWithCosts)
    }

    // MARK: - Cost-Per-Mile Trend

    var priorCostPerMile: Double? {
        let prior = priorPeriodEvents
        guard prior.count >= 2 else { return nil }

        let sorted = prior.sorted { $0.date < $1.date }
        guard let oldest = sorted.first,
              let newest = sorted.last,
              newest.mileage > oldest.mileage else { return nil }

        let milesDriven = newest.mileage - oldest.mileage
        guard milesDriven > 0 else { return nil }

        let total = prior.map(\.amount).reduce(0, +)
        return NSDecimalNumber(decimal: total).doubleValue / Double(milesDriven)
    }

    var costPerMileDelta: Double? {
        guard let current = costPerMile, let prior = priorCostPerMile else { return nil }
        return current - prior
    }

    var costPerMileDeltaDirection: TrendDirection {
        guard let delta = costPerMileDelta else { return .flat }
        if delta > 0.005 { return .up }
        if delta < -0.005 { return .down }
        return .flat
    }

    // MARK: - Share Summary

    var costShareSummary: String {
        var lines: [String] = []

        if let vehicle = vehicle {
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
