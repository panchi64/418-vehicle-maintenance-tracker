import SwiftUI

extension CostsTab {

    // MARK: - Period

    /// The one control. A system segmented picker: short segment labels, the
    /// full period name spoken.
    var periodPicker: some View {
        Picker(L10n.costsPeriodPickerLabel, selection: $periodFilter) {
            ForEach(PeriodFilter.allCases) { period in
                Text(period.shortName)
                    .accessibilityLabel(period.fullName)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: periodFilter)
    }

    // MARK: - Hero

    /// The period total, and the monthly average as its one secondary figure.
    func heroSection(_ metrics: CostsMetrics) -> some View {
        ReadoutSection(title: periodFilter.fullName) {
            RollingNumberText(
                metrics.formattedTotalSpent,
                minimumScaleFactor: 0.5,
                resetToken: vehicle?.id
            )
            .font(.brutalistHero)
            .foregroundStyle(Theme.accent)
            .lineLimit(1)
            .accessibilityLabel(L10n.costsLabeledValue(periodFilter.fullName, metrics.formattedTotalSpent))
            .tourTarget(.costsHeadline, active: onboardingState.currentPhase.isTour)
        } supporting: {
            if let line = metrics.averageLine, let amount = metrics.formattedMonthlyAverage {
                averageText(line, amount: amount)
            }
        } action: {
            ShareLink(
                item: metrics.shareSummary(vehicle: vehicle),
                subject: Text(L10n.costsShareSubject)
            ) {
                Text(L10n.costsShareAction)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: TouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.readoutShareCostSummary)
        }
    }

    /// One localized sentence with its amount set in the heavier face — so the
    /// figure reads as a figure without splitting the sentence in two.
    private func averageText(_ line: String, amount: String) -> Text {
        var attributed = AttributedString(line)
        attributed.font = .brutalistSecondary
        attributed.foregroundColor = Theme.textTertiary
        if let range = attributed.range(of: amount) {
            attributed[range].font = .brutalistHeading
            attributed[range].foregroundColor = Theme.textSecondary
        }
        return Text(attributed)
    }

    // MARK: - Chart

    /// ONE chart section. Units in the title; a written summary always, so the
    /// chart is never the only carrier of its point.
    func chartSection(_ metrics: CostsMetrics) -> some View {
        let title = metrics.chartTitle(chartMode)
        let summary = metrics.chartSummary(chartMode)

        return ReadoutSection(title: title) {
            if metrics.chartIsReady(chartMode) {
                switch chartMode {
                case .trend:
                    CostTrendChart(
                        months: metrics.trend,
                        title: title,
                        summary: summary,
                        selectionLabel: { metrics.trendSelectionLine($0) }
                    )
                case .category:
                    CostCategoryBars(shares: metrics.bucketShares, title: title, summary: summary)
                }
            } else {
                InsufficientDataNote(message: metrics.chartNote(chartMode))
            }
        } supporting: {
            if metrics.chartIsReady(chartMode) {
                Text(summary)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } action: {
            HStack(spacing: Spacing.sm) {
                ForEach(ChartMode.allCases) { mode in
                    Chip(label: mode.label, variant: .plain, isSelected: chartMode == mode) {
                        chartMode = mode
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: chartMode)
        }
    }

    // MARK: - Comparison

    /// This year so far against the same stretch of last year. Independent of
    /// the period: it is always a calendar comparison.
    func comparisonSection(_ metrics: CostsMetrics) -> some View {
        ReadoutSection(title: metrics.comparisonTitle) {
            if let comparison = metrics.comparison {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    // Direction on a shape as well as in the words.
                    Image(systemName: comparisonSymbol(comparison))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityHidden(true)
                    Text(metrics.comparisonHeadline(comparison))
                        .font(.brutalistBodyEmphasis)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                InsufficientDataNote(message: L10n.costsNoteCompare)
            }
        } supporting: {
            if let comparison = metrics.comparison {
                Text(metrics.comparisonDetail(comparison))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func comparisonSymbol(_ comparison: CostYearComparison) -> String {
        if comparison.percentChange > 0 { return "arrowtriangle.up.fill" }
        if comparison.percentChange < 0 { return "arrowtriangle.down.fill" }
        return "equal"
    }

    // MARK: - Expenses by month

    @ViewBuilder
    func expenseSections(_ metrics: CostsMetrics) -> some View {
        if metrics.monthGroups.isEmpty {
            ReadoutSection(title: L10n.costsExpenses) {
                InsufficientDataNote(message: L10n.costsNoteEmptyPeriod)
            }
            .costsListRow()
        } else {
            let anomalies = metrics.anomalyEventIDs
            ForEach(metrics.monthGroups) { group in
                Section {
                    InstrumentSectionHeader(title: group.month.formatted(.dateTime.month(.wide).year())) {
                        Text(Formatters.currency.string(from: group.total as NSDecimalNumber) ?? "")
                            .font(.brutalistBodyEmphasis)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .costsListRow(top: Spacing.lg, bottom: Spacing.xs)

                    ForEach(Array(group.events.enumerated()), id: \.element.id) { index, event in
                        expenseRow(event, isAnomalous: anomalies.contains(event.id))
                            .overlay(alignment: .bottom) {
                                if index < group.events.count - 1 {
                                    ListDivider()
                                }
                            }
                            .costsListRow(top: 0, bottom: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func expenseRow(_ event: ExpenseEvent, isAnomalous: Bool) -> some View {
        switch event {
        case .standalone(let log):
            ExpenseRow(log: log, isAnomalous: isAnomalous) {
                appState.push(.serviceLog(log))
            }
            // Swipe and long-press reach the same Delete (with undo).
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    ServiceLogDeleteAction.perform(log, offerUndo: true)
                } label: {
                    Label(L10n.logDeleteAction, systemImage: "trash")
                }
            }
            .serviceLogDeleteMenu { ServiceLogDeleteAction.perform(log, offerUndo: true) }
        case .visit(let visit):
            VisitExpenseRow(visit: visit, isAnomalous: isAnomalous) {
                appState.push(.visit(visit))
            }
        }
    }
}

// MARK: - Row chrome

extension View {
    /// The brutalist row: screen-edge insets, no system background or
    /// separator (rows draw their own 1pt rule).
    func costsListRow(top: CGFloat = Spacing.md, bottom: CGFloat = Spacing.md) -> some View {
        self
            .listRowInsets(EdgeInsets(
                top: top,
                leading: Spacing.screenHorizontal,
                bottom: bottom,
                trailing: Spacing.screenHorizontal
            ))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
