//
//  CostTrendChart.swift
//  checkpoint
//
//  The Costs tab's Trend picture: one bar per calendar month, oldest first,
//  empty months kept. The highest month is the accent bar; the rest recede.
//
//  Scrubbing shows the month under the finger as a callout inside the chart,
//  above its bar. It used to highlight the matching expense row instead, which
//  was usually off-screen — the answer to "what was that bar?" appeared
//  somewhere the user wasn't looking.
//
//  Bare chart, no card: the section header and the written summary belong to
//  the caller's section, not to the picture.
//

import SwiftUI
import Charts

struct CostTrendChart: View {
    let months: [CostMonth]
    /// Chart title and written summary, reused for the Audio Graph.
    let title: String
    let summary: String
    /// The scrub callout's text for one month ("June 2026 — $320").
    let selectionLabel: @MainActor (CostMonth) -> String

    @State private var selectedDate: Date?

    private var selected: CostMonth? {
        guard let selectedDate else { return nil }
        let calendar = Calendar.current
        return months.first { calendar.isDate($0.month, equalTo: selectedDate, toGranularity: .month) }
    }

    private var peakMonth: Date? {
        months.max(by: { $0.amount < $1.amount })?.month
    }

    /// Past a year of bars, label every third month so labels don't collide.
    private var labelStride: Int {
        months.count > 12 ? 3 : (months.count > 7 ? 2 : 1)
    }

    var body: some View {
        let selected = self.selected

        Chart {
            // Declared first so the rule sits behind the bars; the callout
            // still draws above everything.
            if let selected {
                RuleMark(x: .value(L10n.readoutChartAxisMonth, selected.month, unit: .month))
                    .foregroundStyle(Theme.gridLine)
                    .lineStyle(StrokeStyle(lineWidth: Theme.borderWidth))
                    .annotation(
                        position: .top,
                        spacing: Spacing.xs,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        Text(selectionLabel(selected))
                            .font(.brutalistBodyEmphasis)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Theme.backgroundElevated)
                            .brutalistBorder()
                    }
            }

            ForEach(months) { entry in
                BarMark(
                    x: .value(L10n.readoutChartAxisMonth, entry.month, unit: .month),
                    y: .value(L10n.readoutChartAxisAmount, NSDecimalNumber(decimal: entry.amount).doubleValue)
                )
                .foregroundStyle(entry.month == (selected?.month ?? peakMonth) ? Theme.accent : Theme.accentMuted)
                .cornerRadius(0)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: labelStride)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.narrow))
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: ChartConstants.chartGridLineWidth))
                    .foregroundStyle(Theme.gridLine)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ChartFormatting.abbreviatedCurrency(amount))
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .frame(height: ChartConstants.chartHeight)
        .accessibilityChartDescriptor(descriptor)
        .onChange(of: months) { _, _ in
            selectedDate = nil
        }
    }

    private var descriptor: CostChartDescriptor {
        let points = months.map {
            SpokenChartPoint(label: $0.month.formatted(.dateTime.month(.wide).year()), amount: $0.amount)
        }
        return CostChartDescriptor(
            title: title,
            summary: summary,
            xAxisTitle: L10n.readoutChartAxisMonth,
            yAxisTitle: L10n.readoutChartAxisAmount,
            categories: points.map(\.label),
            series: [SpokenChartSeries(name: L10n.readoutChartSeriesSpending, points: points)],
            currencyCode: Formatters.currencyWhole.currencyCode ?? "USD"
        )
    }
}

#Preview {
    let calendar = Calendar.current
    let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now))!
    let amounts: [Decimal] = [120, 0, 540, 80, 1317, 60, 210, 0, 95]
    let months = amounts.enumerated().map { index, amount in
        CostMonth(
            month: calendar.date(byAdding: .month, value: index - (amounts.count - 1), to: thisMonth)!,
            amount: amount
        )
    }

    return ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CostTrendChart(
            months: months,
            title: "Per Month, USD",
            summary: "",
            selectionLabel: { Formatters.currencyWhole($0.amount) }
        )
        .padding(Spacing.screenHorizontal)
    }
}
