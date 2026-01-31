//
//  CostsTab+Analytics.swift
//  checkpoint
//
//  Analytics computed properties for CostsTab
//

import Foundation

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

    var filteredLogs: [ServiceLog] {
        var logs = vehicleServiceLogs

        // Filter by period
        if let startDate = periodFilter.startDate {
            logs = logs.filter { $0.performedDate >= startDate }
        }

        // Filter by category
        if let category = categoryFilter.costCategory {
            logs = logs.filter { $0.costCategory == category }
        }

        return logs
    }

    var logsWithCosts: [ServiceLog] {
        filteredLogs.filter { $0.cost != nil && $0.cost! > 0 }
    }

    // MARK: - Cost Metrics

    var totalSpent: Decimal {
        logsWithCosts.compactMap { $0.cost }.reduce(0, +)
    }

    var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0"
    }

    var serviceCount: Int {
        filteredLogs.count
    }

    var averageCostPerService: Decimal? {
        guard logsWithCosts.count > 0 else { return nil }
        return totalSpent / Decimal(logsWithCosts.count)
    }

    var formattedAverageCost: String {
        guard let avg = averageCostPerService else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: avg as NSDecimalNumber) ?? "-"
    }

    // MARK: - Cost Per Mile

    /// Calculate cost per mile for the filtered period
    var costPerMile: Double? {
        guard vehicle != nil,
              logsWithCosts.count >= 2 else { return nil }

        // Get oldest and newest logs in period
        let sortedLogs = filteredLogs.sorted { $0.performedDate < $1.performedDate }
        guard let oldest = sortedLogs.first,
              let newest = sortedLogs.last,
              newest.mileageAtService > oldest.mileageAtService else { return nil }

        let milesDriven = newest.mileageAtService - oldest.mileageAtService
        guard milesDriven > 0 else { return nil }

        return NSDecimalNumber(decimal: totalSpent).doubleValue / Double(milesDriven)
    }

    /// Calculate lifetime cost per mile
    var lifetimeCostPerMile: Double? {
        guard vehicle != nil else { return nil }

        // Get all logs with costs for this vehicle (no period filter)
        let allLogs = vehicleServiceLogs.filter { $0.cost != nil && $0.cost! > 0 }
        guard allLogs.count >= 2 else { return nil }

        let sortedLogs = allLogs.sorted { $0.performedDate < $1.performedDate }
        guard let oldest = sortedLogs.first,
              let newest = sortedLogs.last,
              newest.mileageAtService > oldest.mileageAtService else { return nil }

        let milesDriven = newest.mileageAtService - oldest.mileageAtService
        let totalCost = allLogs.compactMap { $0.cost }.reduce(0, +)
        guard milesDriven > 0 else { return nil }

        return NSDecimalNumber(decimal: totalCost).doubleValue / Double(milesDriven)
    }

    var formattedCostPerMile: String {
        guard let cpm = costPerMile else { return "-" }
        return String(format: "$%.2f/mi", cpm)
    }

    // MARK: - Category Breakdown

    var categoryBreakdown: [(category: CostCategory, amount: Decimal, percentage: Double)] {
        guard totalSpent > 0 else { return [] }

        var breakdown: [(CostCategory, Decimal, Double)] = []

        for category in CostCategory.allCases {
            let categoryLogs = logsWithCosts.filter { $0.costCategory == category }
            let amount = categoryLogs.compactMap { $0.cost }.reduce(0, +)
            if amount > 0 {
                let percentage = NSDecimalNumber(decimal: amount).doubleValue / NSDecimalNumber(decimal: totalSpent).doubleValue * 100
                breakdown.append((category, amount, percentage))
            }
        }

        return breakdown.sorted { $0.1 > $1.1 }
    }

    // MARK: - Monthly Breakdown

    var monthlyBreakdown: [(month: Date, amount: Decimal)] {
        let calendar = Calendar.current

        // Group logs by month
        var monthlyTotals: [Date: Decimal] = [:]

        for log in logsWithCosts {
            let components = calendar.dateComponents([.year, .month], from: log.performedDate)
            if let monthStart = calendar.date(from: components) {
                monthlyTotals[monthStart, default: 0] += log.cost ?? 0
            }
        }

        // Sort by date (most recent first)
        return monthlyTotals.map { ($0.key, $0.value) }.sorted { $0.0 > $1.0 }
    }

    // MARK: - Yearly Roundup

    var currentYear: Int {
        Calendar.current.component(.year, from: Date.now)
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
        (periodFilter == .year || periodFilter == .all) && !logsWithCosts.isEmpty
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
