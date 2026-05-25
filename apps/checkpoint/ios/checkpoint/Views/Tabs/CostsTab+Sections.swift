import SwiftUI

extension CostsTab {

    // MARK: - Filters

    @ViewBuilder
    var filtersSection: some View {
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

    // MARK: - Headline + Stats

    @ViewBuilder
    var summaryCardsSection: some View {
        VStack(spacing: Spacing.md) {
            CostHeadlineCard(
                formattedTotal: formattedTotalSpent,
                periodLabel: periodLabel,
                deltaAmount: periodDeltaAmount,
                deltaDirection: periodDeltaDirection,
                priorPeriodLabel: priorPeriodLabel,
                reactiveShare: Int(reactiveShare.rounded()),
                preventiveShare: Int(preventiveShare.rounded()),
                discretionaryShare: Int(discretionaryShare.rounded()),
                projection: yearEndProjection,
                shareSummary: costShareSummary
            )
            .revealAnimation(delay: 0.15)

            let cpm = cpmDelta
            HStack(spacing: Spacing.md) {
                StatsCard(label: "SERVICES", value: "\(serviceCount)")
                StatsCard(label: "AVG COST", value: formattedAverageCost)
                StatsCard(
                    label: "PER MILE",
                    value: formattedCostPerMile,
                    valueColor: Theme.accent,
                    subvalue: cpm?.label,
                    subvalueColor: cpm?.color ?? Theme.textTertiary
                )
            }
            .revealAnimation(delay: 0.2)

            if costPerMile == nil && !eventsWithCosts.isEmpty {
                Text(L10n.emptyCostPerMileHint.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Breakdown / Insights

    @ViewBuilder
    var breakdownSections: some View {
        if let cluster = repairCluster {
            RepairClusterWarningCard(
                count: cluster.count,
                formattedTotal: Formatters.currencyWhole(cluster.totalAmount)
            )
            .revealAnimation(delay: 0.21)
        }

        if cumulativeCostOverTime.count >= 3 {
            CumulativeCostChartCard(
                data: cumulativeCostOverTime,
                onSelectionChange: { date in
                    handleChartSelection(nearestTo: date)
                }
            )
            .revealAnimation(delay: 0.22)
        } else if !eventsWithCosts.isEmpty {
            ChartPlaceholderCard(message: "3+ expenses to show spending pace")
                .revealAnimation(delay: 0.22)
        }

        if categoryFilter == .all && !categoryBreakdown.isEmpty {
            CategoryBreakdownCard(breakdown: categoryBreakdown)
                .revealAnimation(delay: 0.24)
        }

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

        if monthlyBreakdown.count > 1 && periodFilter != .month {
            MonthlyTrendChartCard(
                breakdown: monthlyBreakdownChronological,
                breakdownByCategory: categoryFilter == .all ? monthlyBreakdownByCategory : nil,
                isStacked: categoryFilter == .all,
                onSelectionChange: { month in
                    handleMonthSelection(month: month)
                }
            )
            .revealAnimation(delay: 0.28)
        } else if eventsWithCosts.count == 1 && periodFilter != .month {
            ChartPlaceholderCard(message: "Expenses in 2+ months to show trends")
                .revealAnimation(delay: 0.28)
        }

        if topExpenses.count >= 2 {
            TopExpensesCard(
                events: topExpenses,
                onSelectLog: { log in appState.selectedServiceLog = log },
                onSelectVisit: { visit in appState.selectedServiceVisit = visit }
            )
            .revealAnimation(delay: 0.30)
        }

        if let upcoming = upcomingTeaser {
            UpcomingServicesLinkCard(
                nextServiceName: upcoming.nextName,
                additionalCount: upcoming.additional,
                onTap: { appState.selectedTab = .home }
            )
            .revealAnimation(delay: 0.32)
        }
    }

    // MARK: - Expense List

    @ViewBuilder
    func expenseListSection(scrollProxy: ScrollViewProxy) -> some View {
        if !eventsWithCosts.isEmpty {
            let anomalies = anomalyEventIDs
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Expenses")

                VStack(spacing: 0) {
                    ForEach(Array(eventsWithCosts.enumerated()), id: \.element.id) { index, event in
                        expenseRow(for: event, isAnomalous: anomalies.contains(event.id))
                            .id(event.id)
                            .staggeredReveal(index: index, baseDelay: 0.25)

                        if index < eventsWithCosts.count - 1 {
                            ListDivider(leadingPadding: 28)
                        }
                    }
                }
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }
        }
    }

    @ViewBuilder
    private func expenseRow(for event: ExpenseEvent, isAnomalous: Bool) -> some View {
        let isHighlighted = highlightedEventID == event.id

        switch event {
        case .standalone(let log):
            ExpenseRow(
                log: log,
                isAnomalous: isAnomalous,
                isHighlighted: isHighlighted
            ) {
                appState.selectedServiceLog = log
            }
        case .visit(let visit):
            VisitExpenseRow(
                visit: visit,
                isAnomalous: isAnomalous,
                isHighlighted: isHighlighted
            ) {
                appState.selectedServiceVisit = visit
            }
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    var emptyStates: some View {
        if vehicle != nil && eventsWithCosts.isEmpty {
            CostsEmptyStateView(hasLoggedAny: !vehicleServiceLogs.isEmpty)
                .revealAnimation(delay: 0.2)
        }

        if vehicle == nil {
            EmptyStateView(
                icon: "car.side.fill",
                title: "No Vehicle",
                message: "Select or add a vehicle\nto view costs"
            )
            .revealAnimation(delay: 0.2)
        }
    }

    // MARK: - Helpers

    struct CPMDelta {
        let label: String
        let color: Color
    }

    var cpmDelta: CPMDelta? {
        guard costPerMile != nil, priorCostPerMile != nil,
              let delta = costPerMileDelta else { return nil }

        let unitAbbr = DistanceSettings.shared.unit.abbreviation
        let absStr = String(format: "$%.2f/%@", abs(delta), unitAbbr)

        let label: String
        let color: Color
        switch costPerMileDeltaDirection {
        case .up:
            label = L10n.costsCPMDeltaUp(absStr)
            color = Theme.statusOverdue
        case .down:
            label = L10n.costsCPMDeltaDown(absStr)
            color = Theme.statusGood
        case .flat:
            label = L10n.costsCPMDeltaFlat
            color = Theme.textTertiary
        }
        return CPMDelta(label: label, color: color)
    }

    var upcomingTeaser: (nextName: String, additional: Int)? {
        guard let vehicle = vehicle else { return nil }
        let items = vehicle.allUpcomingItems
        guard let first = items.first else { return nil }
        return (first.itemName, max(0, items.count - 1))
    }

    /// Resolve the event whose `date` is closest to `target` (within ±3 days)
    /// and pulse-highlight it in the list.
    func handleChartSelection(nearestTo target: Date?) {
        guard let target else {
            clearHighlight()
            return
        }
        let nearest = eventsWithCosts.min(by: {
            abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target))
        })
        guard let nearest,
              abs(nearest.date.timeIntervalSince(target)) <= 60 * 60 * 24 * 3 else {
            clearHighlight()
            return
        }
        applyHighlight(nearest.id)
    }

    func handleMonthSelection(month: Date?) {
        guard let month else {
            clearHighlight()
            return
        }
        let calendar = Calendar.current
        let inMonth = eventsWithCosts.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }
        guard let pick = inMonth.max(by: { $0.amount < $1.amount }) else {
            clearHighlight()
            return
        }
        applyHighlight(pick.id)
    }

    private func clearHighlight() {
        guard highlightedEventID != nil else { return }
        highlightedEventID = nil
    }

    private func applyHighlight(_ id: UUID) {
        guard highlightedEventID != id else { return }
        withAnimation(.easeOut(duration: Theme.animationMedium)) {
            highlightedEventID = id
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            if highlightedEventID == id {
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    highlightedEventID = nil
                }
            }
        }
    }
}
