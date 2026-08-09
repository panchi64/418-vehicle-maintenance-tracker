//
//  CostsTab+Analytics.swift
//  checkpoint
//
//  The Costs tab's numbers, derived in one pass.
//
//  All money metrics flow from `ExpenseEvent`s, not raw `ServiceLog`s.
//  An ExpenseEvent is one of:
//    - a standalone log with cost > 0
//    - a Service Visit with totalCost > 0
//
//  This means a Service Visit holding 4 services contributes ONCE to totals,
//  not 4 fabricated quarter-shares (the original bug). Logs that belong to a
//  visit but are not the visit itself are absorbed into the visit event.
//

import Foundation

// MARK: - Expense Event

/// Either a standalone service log with a cost or a Service Visit with a total.
/// Used as the unit of analysis for every cost-side metric.
enum ExpenseEvent: Identifiable {
    case standalone(ServiceLog)
    case visit(ServiceVisit)

    var id: UUID {
        switch self {
        case .standalone(let log): return log.id
        case .visit(let visit): return visit.id
        }
    }

    var date: Date {
        switch self {
        case .standalone(let log): return log.performedDate
        case .visit(let visit): return visit.performedDate
        }
    }

    var mileage: Int {
        switch self {
        case .standalone(let log): return log.mileageAtService
        case .visit(let visit): return visit.mileageAtVisit
        }
    }

    var amount: Decimal {
        switch self {
        case .standalone(let log): return log.cost ?? 0
        case .visit(let visit): return visit.totalCost ?? 0
        }
    }

    var category: CostCategory? {
        switch self {
        case .standalone(let log): return log.costCategory
        case .visit(let visit): return visit.costCategory
        }
    }

    var hasCost: Bool { amount > 0 }
}

// MARK: - Costs Metrics

/// Every number the Costs tab displays, computed once from the vehicle's logs
/// and the active filters.
///
/// This used to be ~40 computed properties in an extension on `CostsTab`, each
/// re-deriving the one below it. Because SwiftUI reads a property every time the
/// body mentions it, a single render of this tab rebuilt the deduped event list
/// dozens of times — and rebuilding it walks `log.visit` and `log.vehicle` for
/// every log, faulting SwiftData relationships each time. That was the bulk of
/// the pause when switching to this tab.
///
/// Rules for anything added here:
/// - **Stored, not computed**, if it iterates the events.
/// - Computed is fine for arithmetic or formatting over already-stored values.
struct CostsMetrics {
    /// Every event for the vehicle, newest first, ignoring both filters. Signals
    /// that should survive narrowing (the repair-cluster warning, the category
    /// option counts) read this.
    let allEvents: [ExpenseEvent]

    /// Period- and category-filtered events that carry a cost. The expense list
    /// and nearly every metric below are built from these.
    let events: [ExpenseEvent]

    /// The vehicle's full service history, newest first.
    let logs: [ServiceLog]

    let totalSpent: Decimal
    let averageCost: Decimal?
    let costPerMile: Double?

    let hasPriorPeriod: Bool
    let priorPeriodTotal: Decimal
    let priorCostPerMile: Double?

    let categoryBreakdown: [(category: CostCategory, amount: Decimal, percentage: Double)]
    /// Percentage of `totalSpent` per category, 0 when nothing was spent.
    let categoryShares: [CostCategory: Double]

    /// Newest month first — the reading order of a list.
    let monthlyBreakdown: [(month: Date, amount: Decimal)]
    /// Oldest month first — the reading order of a chart's x-axis.
    let monthlyBreakdownChronological: [(month: Date, amount: Decimal)]
    let monthlyBreakdownByCategory: [(month: Date, category: CostCategory, amount: Decimal)]
    let cumulativeCostOverTime: [(date: Date, cumulativeAmount: Decimal)]

    let repairCluster: RepairClusterSignal?
    let topExpenses: [ExpenseEvent]
    let anomalyEventIDs: Set<UUID>
    let yearEndProjection: Decimal?

    let currentYear: Int
    let previousYearLogs: [ServiceLog]

    let period: CostsTab.PeriodFilter
    let category: CostsTab.CategoryFilter

    // MARK: - Derivation

    /// - Parameter logs: the vehicle's logs, newest first. Already scoped to the
    ///   vehicle by the caller's query, so this does not re-filter them.
    init(
        logs: [ServiceLog],
        hasVehicle: Bool,
        period: CostsTab.PeriodFilter,
        category: CostsTab.CategoryFilter,
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.logs = logs
        self.period = period
        self.category = category

        // Build the deduped event list: visits are inserted once, and logs that
        // belong to a visit are absorbed into it.
        var seenVisitIDs: Set<UUID> = []
        var built: [ExpenseEvent] = []
        built.reserveCapacity(logs.count)
        for log in logs {
            if let visit = log.visit {
                guard !seenVisitIDs.contains(visit.id) else { continue }
                seenVisitIDs.insert(visit.id)
                built.append(.visit(visit))
            } else {
                built.append(.standalone(log))
            }
        }
        // A visit's date can differ from the log that pulled it in, so the order
        // logs arrived in doesn't guarantee the events are sorted.
        let allEvents = built.sorted { $0.date > $1.date }
        self.allEvents = allEvents

        var filtered = allEvents
        if let startDate = period.startDate(now: now, calendar: calendar) {
            filtered = filtered.filter { $0.date >= startDate }
        }
        if let wanted = category.costCategory {
            filtered = filtered.filter { $0.category == wanted }
        }
        // Events without a cost stay out of financial summaries — they still
        // appear in service history.
        let events = filtered.filter { $0.hasCost }
        self.events = events

        let totalSpent = events.reduce(Decimal(0)) { $0 + $1.amount }
        self.totalSpent = totalSpent
        self.averageCost = events.isEmpty ? nil : totalSpent / Decimal(events.count)

        // Numerator and denominator come from the same event population so the
        // math reads consistently across visit-heavy and standalone-heavy data.
        self.costPerMile = hasVehicle
            ? Self.costPerMile(events: events, total: totalSpent)
            : nil

        // MARK: Prior-period comparison

        let priorRange = Self.priorPeriodRange(period: period, now: now, calendar: calendar)
        self.hasPriorPeriod = priorRange != nil

        // The active category filter applies, so a "repair-only" delta compares
        // repair to repair rather than repair to everything.
        let priorEvents: [ExpenseEvent]
        if let priorRange {
            priorEvents = allEvents.filter {
                $0.date >= priorRange.start && $0.date < priorRange.end && $0.hasCost
                    && (category.costCategory == nil || $0.category == category.costCategory)
            }
        } else {
            priorEvents = []
        }
        let priorTotal = priorEvents.reduce(Decimal(0)) { $0 + $1.amount }
        self.priorPeriodTotal = priorTotal
        self.priorCostPerMile = Self.costPerMile(events: priorEvents, total: priorTotal)

        // MARK: Category split

        // Only events that state a category count toward the breakdown and the
        // share split — an uncategorised expense is not evidence of preventive
        // spending. The stacked monthly chart below does assume `.maintenance`
        // for them, because a stacked bar has to put every dollar somewhere.
        var amountByCategory: [CostCategory: Decimal] = [:]
        for event in events {
            guard let eventCategory = event.category else { continue }
            amountByCategory[eventCategory, default: 0] += event.amount
        }

        let totalDouble = NSDecimalNumber(decimal: totalSpent).doubleValue
        var breakdown: [(category: CostCategory, amount: Decimal, percentage: Double)] = []
        var shares: [CostCategory: Double] = [:]
        if totalDouble > 0 {
            for costCategory in CostCategory.allCases {
                let amount = amountByCategory[costCategory] ?? 0
                let percentage = NSDecimalNumber(decimal: amount).doubleValue / totalDouble * 100
                shares[costCategory] = percentage
                if amount > 0 {
                    breakdown.append((costCategory, amount, percentage))
                }
            }
        }
        self.categoryBreakdown = breakdown.sorted { $0.amount > $1.amount }
        self.categoryShares = shares

        // MARK: Time series

        var monthlyTotals: [Date: Decimal] = [:]
        var monthlyByCategory: [Date: [CostCategory: Decimal]] = [:]
        for event in events {
            let components = calendar.dateComponents([.year, .month], from: event.date)
            guard let monthStart = calendar.date(from: components) else { continue }
            monthlyTotals[monthStart, default: 0] += event.amount
            monthlyByCategory[monthStart, default: [:]][event.category ?? .maintenance, default: 0] += event.amount
        }

        let monthly = monthlyTotals
            .map { (month: $0.key, amount: $0.value) }
            .sorted { $0.month > $1.month }
        self.monthlyBreakdown = monthly
        self.monthlyBreakdownChronological = Array(monthly.reversed())
        self.monthlyBreakdownByCategory = monthlyByCategory
            .flatMap { month, categories in
                categories.map { (month: month, category: $0.key, amount: $0.value) }
            }
            .sorted { $0.month < $1.month }

        var dailyTotals: [(date: Date, amount: Decimal)] = []
        for event in events.reversed() {  // oldest first
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
            let dayDate = calendar.date(from: dayComponents) ?? event.date

            if let lastIndex = dailyTotals.indices.last, dailyTotals[lastIndex].date == dayDate {
                dailyTotals[lastIndex].amount += event.amount
            } else {
                dailyTotals.append((date: dayDate, amount: event.amount))
            }
        }
        var running: Decimal = 0
        self.cumulativeCostOverTime = dailyTotals.map { entry in
            running += entry.amount
            return (date: entry.date, cumulativeAmount: running)
        }

        // MARK: Signals

        // Operates on all events, not the filtered set, so the warning still
        // shows when the user has narrowed to a single category.
        self.repairCluster = CostsInsightsCore.detectRepairCluster(events: allEvents, calendar: calendar)
        self.topExpenses = CostsInsightsCore.topExpenses(events: events)
        self.anomalyEventIDs = CostsInsightsCore.detectAnomalies(events: events)
        self.yearEndProjection = period == .ytd
            ? CostsInsightsCore.projectYearEnd(totalSpent: totalSpent, now: now, calendar: calendar)
            : nil

        // MARK: Yearly roundup

        let year: Int
        if period == .year, let newest = events.first {
            year = calendar.component(.year, from: newest.date)
        } else {
            year = calendar.component(.year, from: now)
        }
        self.currentYear = year
        self.previousYearLogs = logs.filter {
            calendar.component(.year, from: $0.performedDate) == year - 1
        }
    }

    /// Spend per mile across an event set: total cost over the distance between
    /// its oldest and newest odometer readings. Needs two events and forward
    /// motion between them.
    private static func costPerMile(events: [ExpenseEvent], total: Decimal) -> Double? {
        guard events.count >= 2 else { return nil }

        let sorted = events.sorted { $0.date < $1.date }
        guard let oldest = sorted.first,
              let newest = sorted.last,
              newest.mileage > oldest.mileage else { return nil }

        let milesDriven = newest.mileage - oldest.mileage
        guard milesDriven > 0 else { return nil }

        return NSDecimalNumber(decimal: total).doubleValue / Double(milesDriven)
    }

    /// The window the current period is compared against. `all` has no prior.
    private static func priorPeriodRange(
        period: CostsTab.PeriodFilter,
        now: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date)? {
        switch period {
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
}
