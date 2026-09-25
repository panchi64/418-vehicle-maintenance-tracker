import SwiftUI

extension CostsTab {

    // MARK: - Filters

    /// Category options for the period currently in view, plus All.
    ///
    /// Only categories the vehicle actually has an entry for are offered:
    /// listing a category with zero entries is offering a route to an empty
    /// screen. Counts sit beside each option so the choice is informed.
    ///
    /// Deliberately reads `allEvents` rather than the filtered set — narrowing to
    /// one category must not remove the others from the picker.
    func categoryOptions(_ metrics: CostsMetrics) -> [PickerOption<CategoryFilter>] {
        let inPeriod: [ExpenseEvent] = {
            guard let startDate = periodFilter.startDate else { return metrics.allEvents }
            return metrics.allEvents.filter { $0.date >= startDate }
        }()

        var countByCategory: [CostCategory: Int] = [:]
        for event in inPeriod {
            guard let category = event.category else { continue }
            countByCategory[category, default: 0] += 1
        }

        return [PickerOption(value: .all, label: CategoryFilter.all.displayName, count: inPeriod.count)]
            + CategoryFilter.allCases
                .compactMap { filter -> PickerOption<CategoryFilter>? in
                    guard let category = filter.costCategory,
                          let count = countByCategory[category], count > 0 else { return nil }
                    return PickerOption(value: filter, label: filter.displayName, count: count)
                }
                .sorted { ($0.count ?? 0) > ($1.count ?? 0) }
    }

    /// ONE row of chrome, not two. Period is the segmented control because it
    /// changes the scope of every number on the screen; category is a
    /// FilterControl, which scales to six categories where neither a segmented
    /// control nor a scrolling chip row does — the chip row hid three of the six
    /// off the right edge, and 4 periods × 4 categories was 16 states stacked
    /// above nine independently-gated cards.
    func filtersSection(_ metrics: CostsMetrics) -> some View {
        FilterControlRow(
            name: L10n.costsCategoryDimension,
            options: categoryOptions(metrics),
            selection: $categoryFilter,
            defaultValue: .all
        ) {
            InstrumentSegmentedControl(
                options: PeriodFilter.allCases,
                selection: $periodFilter
            ) { filter in
                filter.displayName
            }
        }
    }

    // MARK: - Headline + Stats

    @ViewBuilder
    func summaryCardsSection(_ metrics: CostsMetrics) -> some View {
        VStack(spacing: Spacing.md) {
            CostHeadlineCard(
                formattedTotal: metrics.formattedTotalSpent,
                periodLabel: metrics.periodLabel,
                deltaAmount: metrics.periodDeltaAmount,
                deltaDirection: metrics.periodDeltaDirection,
                priorPeriodLabel: metrics.priorPeriodLabel,
                reactiveShare: Int(metrics.reactiveShare.rounded()),
                preventiveShare: Int(metrics.preventiveShare.rounded()),
                discretionaryShare: Int(metrics.discretionaryShare.rounded()),
                projection: metrics.yearEndProjection,
                shareSummary: metrics.costShareSummary(vehicle: vehicle),
                subjectID: vehicle?.id
            )
            .tourTarget(.costsHeadline, active: onboardingState.currentPhase.isTour)
            .revealAnimation(delay: 0.15)

            let cpm = cpmDelta(metrics)
            StatsCardRow {
                StatsCard(
                    label: L10n.costsStatServices,
                    value: "\(metrics.serviceCount)",
                    subjectID: vehicle?.id
                )
                StatsCard(
                    label: L10n.costsStatAvgCost,
                    value: metrics.formattedAverageCost,
                    subjectID: vehicle?.id
                )
                StatsCard(
                    label: L10n.costsStatPerMile,
                    value: metrics.formattedCostPerMile,
                    valueColor: Theme.accent,
                    subvalue: cpm?.label,
                    subvalueColor: cpm?.color ?? Theme.textTertiary,
                    subjectID: vehicle?.id
                )
            }
            .revealAnimation(delay: 0.2)

            if metrics.costPerMile == nil && !metrics.isEmpty {
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
    func breakdownSections(_ metrics: CostsMetrics) -> some View {
        if let cluster = metrics.repairCluster {
            RepairClusterWarningCard(
                count: cluster.count,
                formattedTotal: Formatters.currencyWhole(cluster.totalAmount)
            )
            .revealAnimation(delay: 0.21)
        }

        if metrics.cumulativeCostOverTime.count >= 3 {
            CumulativeCostChartCard(
                data: metrics.cumulativeCostOverTime,
                onSelectionChange: { date in
                    handleChartSelection(nearestTo: date, in: metrics)
                }
            )
            .revealAnimation(delay: 0.22)
        } else if !metrics.isEmpty {
            ChartPlaceholderCard(message: "3+ expenses to show spending pace")
                .revealAnimation(delay: 0.22)
        }

        if categoryFilter == .all && !metrics.categoryBreakdown.isEmpty {
            CategoryBreakdownCard(breakdown: metrics.categoryBreakdown)
                .revealAnimation(delay: 0.24)
        }

        if metrics.shouldShowYearlyRoundup {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Yearly Summary")
                YearlyCostRoundupCard(
                    year: metrics.currentYear,
                    serviceLogs: metrics.logs,
                    previousYearLogs: metrics.previousYearLogs
                )
            }
            .revealAnimation(delay: 0.26)
        }

        if metrics.monthlyBreakdown.count > 1 && periodFilter != .month {
            MonthlyTrendChartCard(
                breakdown: metrics.monthlyBreakdownChronological,
                breakdownByCategory: categoryFilter == .all ? metrics.monthlyBreakdownByCategory : nil,
                isStacked: categoryFilter == .all,
                onSelectionChange: { month in
                    handleMonthSelection(month: month, in: metrics)
                }
            )
            .revealAnimation(delay: 0.28)
        } else if metrics.serviceCount == 1 && periodFilter != .month {
            ChartPlaceholderCard(message: "Expenses in 2+ months to show trends")
                .revealAnimation(delay: 0.28)
        }

        if metrics.topExpenses.count >= 2 {
            TopExpensesCard(
                events: metrics.topExpenses,
                onSelectLog: { log in appState.push(.serviceLog(log)) },
                onSelectVisit: { visit in appState.push(.visit(visit)) }
            )
            .revealAnimation(delay: 0.30)
        }

        if let upcoming = upcomingTeaser {
            UpcomingServicesLinkCard(
                nextServiceName: upcoming.nextName,
                additionalCount: upcoming.additional,
                // Services, not Home. Home shows at most three upcoming items;
                // this card names one and counts the rest, so it has to land on
                // the list that actually contains them. Sending it to Home also
                // completed a loop — Home's Recent Activity used to point back
                // here.
                onTap: { appState.selectedTab = .services }
            )
            .revealAnimation(delay: 0.32)
        }
    }

    // MARK: - Expense List

    @ViewBuilder
    func expenseListSection(_ metrics: CostsMetrics) -> some View {
        if !metrics.isEmpty {
            let anomalies = metrics.anomalyEventIDs
            let events = metrics.events
            // Unboxed, matching Home and Services: a titled section of
            // divider-separated rows is already one group, and this tab's
            // headline and stat cards are boxed, so a bordered list here
            // competed with them.
            ReadoutSection(title: L10n.costsExpenses) {
                VStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        expenseRow(for: event, isAnomalous: anomalies.contains(event.id))
                            .staggeredReveal(index: index, baseDelay: 0.25)

                        if index < events.count - 1 {
                            ListDivider()
                        }
                    }
                }
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
                appState.push(.serviceLog(log))
            }
            .serviceLogDeleteMenu { ServiceLogDeleteAction.perform(log, offerUndo: true) }
        case .visit(let visit):
            VisitExpenseRow(
                visit: visit,
                isAnomalous: isAnomalous,
                isHighlighted: isHighlighted
            ) {
                appState.push(.visit(visit))
            }
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    func emptyStates(_ metrics: CostsMetrics) -> some View {
        if vehicle != nil && metrics.isEmpty {
            CostsEmptyStateView(hasLoggedAny: !metrics.logs.isEmpty)
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

    func cpmDelta(_ metrics: CostsMetrics) -> CPMDelta? {
        guard let delta = metrics.costPerMileDelta else { return nil }

        let unitAbbr = DistanceSettings.shared.unit.abbreviation
        let absStr = String(format: "$%.2f/%@", abs(delta), unitAbbr)

        let label: String
        let color: Color
        switch metrics.costPerMileDeltaDirection {
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
    func handleChartSelection(nearestTo target: Date?, in metrics: CostsMetrics) {
        guard let target else {
            clearHighlight()
            return
        }
        let nearest = metrics.events.min(by: {
            abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target))
        })
        guard let nearest,
              abs(nearest.date.timeIntervalSince(target)) <= 60 * 60 * 24 * 3 else {
            clearHighlight()
            return
        }
        applyHighlight(nearest.id)
    }

    func handleMonthSelection(month: Date?, in metrics: CostsMetrics) {
        guard let month else {
            clearHighlight()
            return
        }
        let calendar = Calendar.current
        let inMonth = metrics.events.filter {
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
