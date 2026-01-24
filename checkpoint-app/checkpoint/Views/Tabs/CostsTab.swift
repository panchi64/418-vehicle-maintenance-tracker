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
        guard let startDate = periodFilter.startDate else {
            return vehicleServiceLogs
        }
        return vehicleServiceLogs.filter { $0.performedDate >= startDate }
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

    private var formattedCostPerMile: String {
        guard let cpm = costPerMile else { return "-" }
        return String(format: "$%.2f/mi", cpm)
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

                // Expense list
                if !logsWithCosts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Expenses")

                        VStack(spacing: 0) {
                            ForEach(Array(logsWithCosts.enumerated()), id: \.element.id) { index, log in
                                expenseRow(log: log)
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
            Text("TOTAL_SPENT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            Text(formattedTotalSpent)
                .font(.brutalistHero)
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())

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
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(formatDate(log.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(Spacing.md)
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
                Text("NO_EXPENSES")
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
                Text("NO_VEHICLE_SELECTED")
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
