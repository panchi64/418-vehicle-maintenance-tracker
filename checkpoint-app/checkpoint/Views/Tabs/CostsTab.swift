//
//  CostsTab.swift
//  checkpoint
//
//  Costs tab showing expense tracking and analytics
//

import SwiftUI
import SwiftData

struct CostsTab: View {
    @Bindable var appState: AppState
    @Query private var serviceLogs: [ServiceLog]

    @State private var periodFilter: PeriodFilter = .ytd
    @State private var categoryFilter: CategoryFilter = .all

    enum PeriodFilter: String, CaseIterable {
        case month = "Month"
        case ytd = "YTD"
        case year = "Year"
        case all = "All"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: .now)
            case .ytd:
                return calendar.date(from: calendar.dateComponents([.year], from: .now))
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: .now)
            case .all:
                return nil
            }
        }
    }

    enum CategoryFilter: String, CaseIterable {
        case all = "All"
        case maintenance = "Maint"
        case repair = "Repair"
        case upgrade = "Upgrade"

        var costCategory: CostCategory? {
            switch self {
            case .all: return nil
            case .maintenance: return .maintenance
            case .repair: return .repair
            case .upgrade: return .upgrade
            }
        }
    }

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.performedDate > $1.performedDate }
    }

    private var filteredLogs: [ServiceLog] {
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

    private var logsWithCosts: [ServiceLog] {
        filteredLogs.filter { $0.cost != nil && $0.cost! > 0 }
    }

    private var totalSpent: Decimal {
        logsWithCosts.compactMap { $0.cost }.reduce(0, +)
    }

    private var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0"
    }

    private var serviceCount: Int {
        filteredLogs.count
    }

    private var averageCostPerService: Decimal? {
        guard logsWithCosts.count > 0 else { return nil }
        return totalSpent / Decimal(logsWithCosts.count)
    }

    private var formattedAverageCost: String {
        guard let avg = averageCostPerService else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: avg as NSDecimalNumber) ?? "-"
    }

    /// Calculate cost per mile for the filtered period
    private var costPerMile: Double? {
        guard let vehicle = vehicle,
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
    private var lifetimeCostPerMile: Double? {
        guard let vehicle = vehicle else { return nil }

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

    private var formattedCostPerMile: String {
        guard let cpm = costPerMile else { return "-" }
        return String(format: "$%.2f/mi", cpm)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: [(category: CostCategory, amount: Decimal, percentage: Double)] {
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

        // Also include uncategorized
        let uncategorizedLogs = logsWithCosts.filter { $0.costCategory == nil }
        let uncategorizedAmount = uncategorizedLogs.compactMap { $0.cost }.reduce(0, +)
        if uncategorizedAmount > 0 {
            // We'll handle uncategorized separately in the view
        }

        return breakdown.sorted { $0.1 > $1.1 }
    }

    // MARK: - Monthly Breakdown

    private var monthlyBreakdown: [(month: Date, amount: Decimal)] {
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

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date.now)
    }

    private var previousYearLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        let calendar = Calendar.current
        let previousYear = currentYear - 1

        return serviceLogs
            .filter { $0.vehicle?.id == vehicle.id }
            .filter { calendar.component(.year, from: $0.performedDate) == previousYear }
    }

    private var shouldShowYearlyRoundup: Bool {
        (periodFilter == .year || periodFilter == .all) && !logsWithCosts.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Period filter
                InstrumentSegmentedControl(
                    options: PeriodFilter.allCases,
                    selection: $periodFilter
                ) { filter in
                    filter.rawValue
                }
                .revealAnimation(delay: 0.1)

                // Category filter
                InstrumentSegmentedControl(
                    options: CategoryFilter.allCases,
                    selection: $categoryFilter
                ) { filter in
                    filter.rawValue
                }
                .revealAnimation(delay: 0.12)

                // Summary cards
                VStack(spacing: Spacing.md) {
                    // Total spent card (hero)
                    totalSpentCard
                        .revealAnimation(delay: 0.15)

                    // Stats row
                    HStack(spacing: Spacing.md) {
                        statsCard(
                            label: "SERVICES",
                            value: "\(serviceCount)",
                            valueColor: Theme.textPrimary
                        )

                        statsCard(
                            label: "AVG COST",
                            value: formattedAverageCost,
                            valueColor: Theme.textPrimary
                        )

                        statsCard(
                            label: "PER MILE",
                            value: formattedCostPerMile,
                            valueColor: Theme.accent
                        )
                    }
                    .revealAnimation(delay: 0.2)
                }

                // Category breakdown (only show when "All" category is selected)
                if categoryFilter == .all && !categoryBreakdown.isEmpty {
                    categoryBreakdownSection
                        .revealAnimation(delay: 0.22)
                }

                // Yearly roundup card (show for Year and All periods)
                if shouldShowYearlyRoundup {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Yearly Summary")

                        YearlyCostRoundupCard(
                            year: currentYear,
                            serviceLogs: vehicleServiceLogs,
                            previousYearLogs: previousYearLogs
                        )
                    }
                    .revealAnimation(delay: 0.24)
                }

                // Monthly summary (show for Year and All periods)
                if (periodFilter == .year || periodFilter == .all) && monthlyBreakdown.count > 1 {
                    monthlySummarySection
                        .revealAnimation(delay: 0.26)
                }

                // Expense list
                if !logsWithCosts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Expenses")

                        VStack(spacing: 0) {
                            ForEach(Array(logsWithCosts.enumerated()), id: \.element.id) { index, log in
                                Button {
                                    appState.selectedServiceLog = log
                                } label: {
                                    expenseRow(log: log)
                                }
                                .buttonStyle(.plain)
                                .staggeredReveal(index: index, baseDelay: 0.25)

                                if index < logsWithCosts.count - 1 {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(height: 1)
                                        .padding(.leading, 28)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )
                    }
                }

                // Empty state
                if vehicle != nil && logsWithCosts.isEmpty {
                    emptyState
                        .revealAnimation(delay: 0.2)
                }

                // No vehicle state
                if vehicle == nil {
                    noVehicleState
                        .revealAnimation(delay: 0.2)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl + 56)
        }
    }

    // MARK: - Total Spent Card

    private var totalSpentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Total Spent")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            Text(formattedTotalSpent)
                .font(.brutalistHero)
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(periodLabel)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private var periodLabel: String {
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

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "By Category")

            VStack(spacing: 0) {
                ForEach(categoryBreakdown, id: \.category) { item in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(item.category.color)
                            .frame(width: 20)

                        Text(item.category.displayName)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 40, alignment: .trailing)

                        Text(formatCurrency(item.amount))
                            .font(.brutalistBody)
                            .foregroundStyle(item.category.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 60, alignment: .trailing)
                    }
                    .padding(Spacing.md)

                    if item.category != categoryBreakdown.last?.category {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                            .padding(.leading, 28)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Monthly Summary Section

    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Monthly Breakdown")

            VStack(spacing: 0) {
                ForEach(Array(monthlyBreakdown.prefix(6).enumerated()), id: \.element.month) { index, item in
                    HStack(spacing: Spacing.sm) {
                        Text(formatMonthYear(item.month))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Simple bar indicator
                        if let maxAmount = monthlyBreakdown.prefix(6).map(\.amount).max(), maxAmount > 0 {
                            let ratio = CGFloat(NSDecimalNumber(decimal: item.amount).doubleValue / NSDecimalNumber(decimal: maxAmount).doubleValue)
                            let barWidth = min(ratio * 60, 60)
                            Rectangle()
                                .fill(Theme.accent.opacity(0.3))
                                .frame(width: max(barWidth, 4), height: 8)
                        }

                        Text(formatCurrency(item.amount))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 60, alignment: .trailing)
                    }
                    .padding(Spacing.md)

                    if index < min(monthlyBreakdown.count, 6) - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Stats Card

    private func statsCard(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(value)
                .font(.brutalistHeading)
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Expense Row

    private func expenseRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            // Category icon or default
            if let category = log.costCategory {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(category.color)
                    .frame(width: 20)
            } else {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatDate(log.performedDate))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    if let category = log.costCategory {
                        Text("//")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        Text(category.displayName.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(category.color)
                            .tracking(0.5)
                    }
                }
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistHeading)
                    .foregroundStyle(log.costCategory?.color ?? Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("No Expenses")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Record service costs when\ncompleting maintenance")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    private var noVehicleState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "car.side.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("No Vehicle")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Select or add a vehicle\nto view costs")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        CostsTab(appState: appState)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
