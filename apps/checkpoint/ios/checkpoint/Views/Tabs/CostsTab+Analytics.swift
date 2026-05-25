//
//  CostsTab+Analytics.swift
//  checkpoint
//
//  Analytics computed properties for CostsTab.
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

// MARK: - Analytics Extension

extension CostsTab {

    // MARK: - Filtered Data

    var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.performedDate > $1.performedDate }
    }

    /// Build the deduped event list for the selected vehicle.
    /// Visits are inserted once; logs that belong to a visit are absorbed.
    var vehicleEvents: [ExpenseEvent] {
        let logs = vehicleServiceLogs
        var seenVisitIDs: Set<UUID> = []
        var events: [ExpenseEvent] = []

        for log in logs {
            if let visit = log.visit {
                guard !seenVisitIDs.contains(visit.id) else { continue }
                seenVisitIDs.insert(visit.id)
                events.append(.visit(visit))
            } else {
                events.append(.standalone(log))
            }
        }

        return events.sorted { $0.date > $1.date }
    }

    var filteredEvents: [ExpenseEvent] {
        var events = vehicleEvents

        if let startDate = periodFilter.startDate {
            events = events.filter { $0.date >= startDate }
        }

        if let category = categoryFilter.costCategory {
            events = events.filter { $0.category == category }
        }

        return events
    }

    /// Events with at least some cost. The expense list and most metrics use
    /// this — events without a cost (e.g. a visit logged without a total) are
    /// excluded from financial summaries but still appear in service history.
    var eventsWithCosts: [ExpenseEvent] {
        filteredEvents.filter { $0.hasCost }
    }

    /// Backwards-compatible accessor: exposed because CostsTab uses it for
    /// empty-state checks. Returns standalone logs that have a real cost,
    /// dropping every visit-bound log (those are surfaced through visits).
    var logsWithCosts: [ServiceLog] {
        eventsWithCosts.compactMap { event in
            if case .standalone(let log) = event { return log }
            return nil
        }
    }

    // MARK: - Cost Metrics

    var totalSpent: Decimal {
        eventsWithCosts.map(\.amount).reduce(0, +)
    }

    var formattedTotalSpent: String {
        Formatters.currencyWhole(totalSpent)
    }

    /// Number of distinct money events (visits + standalone logs with cost).
    /// Replaces the previous "service count" which counted each log of an
    /// un-itemized cluster as a separate service.
    var serviceCount: Int {
        eventsWithCosts.count
    }

    /// Average cost per money event — per visit when bundled, per standalone
    /// log otherwise. Reads as "AVG COST" in the UI.
    var averageCostPerService: Decimal? {
        guard !eventsWithCosts.isEmpty else { return nil }
        return totalSpent / Decimal(eventsWithCosts.count)
    }

    var formattedAverageCost: String {
        guard let avg = averageCostPerService else { return "-" }
        return Formatters.currencyWhole(avg)
    }

    // MARK: - Cost Per Mile

    /// Calculate cost per mile for the filtered period.
    /// Numerator and denominator come from the same event population so the
    /// math reads consistently across visit-heavy and standalone-heavy data.
    var costPerMile: Double? {
        guard vehicle != nil,
              eventsWithCosts.count >= 2 else { return nil }

        let sortedEvents = eventsWithCosts.sorted { $0.date < $1.date }
        guard let oldest = sortedEvents.first,
              let newest = sortedEvents.last,
              newest.mileage > oldest.mileage else { return nil }

        let milesDriven = newest.mileage - oldest.mileage
        guard milesDriven > 0 else { return nil }

        return NSDecimalNumber(decimal: totalSpent).doubleValue / Double(milesDriven)
    }

    var formattedCostPerMile: String {
        guard let cpm = costPerMile else { return "-" }
        let unitAbbr = DistanceSettings.shared.unit.abbreviation
        return String(format: "$%.2f/\(unitAbbr)", cpm)
    }

    // MARK: - Category Breakdown

    var categoryBreakdown: [(category: CostCategory, amount: Decimal, percentage: Double)] {
        guard totalSpent > 0 else { return [] }

        var breakdown: [(CostCategory, Decimal, Double)] = []

        for category in CostCategory.allCases {
            let categoryEvents = eventsWithCosts.filter { $0.category == category }
            let amount = categoryEvents.map(\.amount).reduce(0, +)
            if amount > 0 {
                let percentage = NSDecimalNumber(decimal: amount).doubleValue
                    / NSDecimalNumber(decimal: totalSpent).doubleValue * 100
                breakdown.append((category, amount, percentage))
            }
        }

        return breakdown.sorted { $0.1 > $1.1 }
    }

    // MARK: - Monthly Breakdown

    var monthlyBreakdown: [(month: Date, amount: Decimal)] {
        let calendar = Calendar.current
        var monthlyTotals: [Date: Decimal] = [:]

        for event in eventsWithCosts {
            let components = calendar.dateComponents([.year, .month], from: event.date)
            if let monthStart = calendar.date(from: components) {
                monthlyTotals[monthStart, default: 0] += event.amount
            }
        }

        return monthlyTotals.map { ($0.key, $0.value) }.sorted { $0.0 > $1.0 }
    }

    var monthlyBreakdownChronological: [(month: Date, amount: Decimal)] {
        monthlyBreakdown.sorted { $0.month < $1.month }
    }

    var monthlyBreakdownByCategory: [(month: Date, category: CostCategory, amount: Decimal)] {
        let calendar = Calendar.current
        var grouped: [Date: [CostCategory: Decimal]] = [:]

        for event in eventsWithCosts {
            let components = calendar.dateComponents([.year, .month], from: event.date)
            if let monthStart = calendar.date(from: components) {
                let category = event.category ?? .maintenance
                grouped[monthStart, default: [:]][category, default: 0] += event.amount
            }
        }

        var result: [(month: Date, category: CostCategory, amount: Decimal)] = []
        for (month, categories) in grouped {
            for (category, amount) in categories {
                result.append((month: month, category: category, amount: amount))
            }
        }

        return result.sorted { $0.month < $1.month }
    }

    // MARK: - Cumulative Cost Over Time

    var cumulativeCostOverTime: [(date: Date, cumulativeAmount: Decimal)] {
        let calendar = Calendar.current
        let sorted = eventsWithCosts.sorted { $0.date < $1.date }

        var dailyTotals: [(date: Date, amount: Decimal)] = []
        for event in sorted {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
            let dayDate = calendar.date(from: dayComponents) ?? event.date

            if let lastIndex = dailyTotals.indices.last, dailyTotals[lastIndex].date == dayDate {
                dailyTotals[lastIndex].amount += event.amount
            } else {
                dailyTotals.append((date: dayDate, amount: event.amount))
            }
        }

        var cumulative: Decimal = 0
        return dailyTotals.map { entry in
            cumulative += entry.amount
            return (date: entry.date, cumulativeAmount: cumulative)
        }
    }

    // MARK: - Yearly Roundup

    var currentYear: Int {
        if periodFilter == .year, let newest = eventsWithCosts.first {
            return Calendar.current.component(.year, from: newest.date)
        }
        return Calendar.current.component(.year, from: Date.now)
    }

    var previousYearLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        let calendar = Calendar.current
        let previousYear = currentYear - 1

        return serviceLogs
            .filter { $0.vehicle?.id == vehicle.id }
            .filter { calendar.component(.year, from: $0.performedDate) == previousYear }
    }

    var shouldShowYearlyRoundup: Bool {
        (periodFilter == .year || periodFilter == .all) && !eventsWithCosts.isEmpty
    }

    // MARK: - Period Label

    var periodLabel: String {
        switch periodFilter {
        case .month:
            return "Last 30 days"
        case .ytd:
            return "Year to date"
        case .year:
            return "Last 12 months"
        case .all:
            return "All time"
        }
    }
}
