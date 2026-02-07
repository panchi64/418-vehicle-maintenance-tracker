//
//  CostsTab.swift
//  checkpoint
//
//  Costs tab showing expense tracking and analytics
//

import SwiftUI
import SwiftData
import Charts

struct CostsTab: View {
    @Bindable var appState: AppState
    @Query var serviceLogs: [ServiceLog]

    @State var periodFilter: PeriodFilter = .ytd
    @State var categoryFilter: CategoryFilter = .all

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

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                filtersSection
                summaryCardsSection
                breakdownSections
                expenseListSection
                emptyStates
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl + 56)
        }
        .trackScreen(.costs)
        .onChange(of: periodFilter) { _, newValue in
            AnalyticsService.shared.capture(.costsPeriodChanged(period: newValue.rawValue))
        }
        .onChange(of: categoryFilter) { _, newValue in
            AnalyticsService.shared.capture(.costsCategoryChanged(category: newValue.rawValue))
        }
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: Spacing.lg) {
            InstrumentSegmentedControl(
                options: PeriodFilter.allCases,
                selection: $periodFilter
            ) { filter in
                filter.rawValue
            }
            .revealAnimation(delay: 0.1)

            InstrumentSegmentedControl(
                options: CategoryFilter.allCases,
                selection: $categoryFilter
            ) { filter in
                filter.rawValue
            }
            .revealAnimation(delay: 0.12)
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        VStack(spacing: Spacing.md) {
            CostSummaryCard(
                formattedTotal: formattedTotalSpent,
                periodLabel: periodLabel
            )
            .revealAnimation(delay: 0.15)

            HStack(spacing: Spacing.md) {
                StatsCard(label: "SERVICES", value: "\(serviceCount)")
                StatsCard(label: "AVG COST", value: formattedAverageCost)
                StatsCard(label: "PER MILE", value: formattedCostPerMile, valueColor: Theme.accent)
            }
            .revealAnimation(delay: 0.2)

            if costPerMile == nil && !logsWithCosts.isEmpty {
                Text(L10n.emptyCostPerMileHint.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Breakdown Sections

    @ViewBuilder
    private var breakdownSections: some View {
        // Spending pace chart
        if cumulativeCostOverTime.count >= 3 {
            CumulativeCostChartCard(data: cumulativeCostOverTime)
                .revealAnimation(delay: 0.22)
        } else if !logsWithCosts.isEmpty {
            ChartPlaceholderCard()
                .revealAnimation(delay: 0.22)
        }

        // Category breakdown (only show when "All" category is selected)
        if categoryFilter == .all && !categoryBreakdown.isEmpty {
            CategoryBreakdownCard(breakdown: categoryBreakdown)
                .revealAnimation(delay: 0.24)
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
            .revealAnimation(delay: 0.26)
        }

        // Monthly trend chart (replaces MonthlyBreakdownCard)
        if monthlyBreakdown.count > 1 && periodFilter != .month {
            MonthlyTrendChartCard(
                breakdown: monthlyBreakdownChronological,
                breakdownByCategory: categoryFilter == .all ? monthlyBreakdownByCategory : nil,
                isStacked: categoryFilter == .all
            )
            .revealAnimation(delay: 0.28)
        } else if logsWithCosts.count == 1 && periodFilter != .month {
            ChartPlaceholderCard()
                .revealAnimation(delay: 0.28)
        }
    }

    // MARK: - Expense List Section

    @ViewBuilder
    private var expenseListSection: some View {
        if !logsWithCosts.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Expenses")

                VStack(spacing: 0) {
                    ForEach(Array(logsWithCosts.enumerated()), id: \.element.id) { index, log in
                        ExpenseRow(log: log) {
                            appState.selectedServiceLog = log
                        }
                        .staggeredReveal(index: index, baseDelay: 0.25)

                        if index < logsWithCosts.count - 1 {
                            ListDivider(leadingPadding: 28)
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
    }

    // MARK: - Empty States

    @ViewBuilder
    private var emptyStates: some View {
        if vehicle != nil && logsWithCosts.isEmpty {
            emptyState
                .revealAnimation(delay: 0.2)
        }

        if vehicle == nil {
            noVehicleState
                .revealAnimation(delay: 0.2)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "dollarsign.circle",
            title: "No Expenses",
            message: "Record service costs when\ncompleting maintenance"
        )
    }

    private var noVehicleState: some View {
        EmptyStateView(
            icon: "car.side.fill",
            title: "No Vehicle",
            message: "Select or add a vehicle\nto view costs"
        )
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
