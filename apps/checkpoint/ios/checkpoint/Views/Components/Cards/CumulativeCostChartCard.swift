//
//  CumulativeCostChartCard.swift
//  checkpoint
//
//  Area chart showing cumulative spending pace over time
//  Answers: "How fast am I spending money?"
//

import SwiftUI
import Charts

struct CumulativeCostChartCard: View {
    let data: [(date: Date, cumulativeAmount: Decimal)]
    var onSelectionChange: ((Date?) -> Void)? = nil

    @State private var selectedDate: Date?

    /// Find the data entry nearest to the selected date
    private var selectedEntry: (date: Date, cumulativeAmount: Decimal)? {
        guard let selectedDate else { return nil }
        return data.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.readoutChartPaceTitle)

            ZStack(alignment: .topLeading) {
                Chart(data, id: \.date) { entry in
                    let amount = NSDecimalNumber(decimal: entry.cumulativeAmount).doubleValue

                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Total", amount)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Theme.accent.opacity(0.15),
                                Theme.accent.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Total", amount)
                    )
                    .foregroundStyle(Theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: ChartConstants.chartLineWidth))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Total", amount)
                    )
                    .foregroundStyle(Theme.accent)
                    .symbolSize(ChartConstants.pointSize * ChartConstants.pointSize)
                    .symbol(.square)

                    if let selected = selectedEntry, selected.date == entry.date {
                        RuleMark(x: .value("Selected", selected.date))
                            .foregroundStyle(Theme.textTertiary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXSelection(value: $selectedDate)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(Self.dateFormatter.string(from: date).uppercased())
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: ChartConstants.chartGridLineWidth))
                            .foregroundStyle(Theme.gridLine)
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(ChartFormatting.abbreviatedCurrency(doubleValue))
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.clear)
                }
                .frame(height: ChartConstants.chartHeight)
                .accessibilityChartDescriptor(chartDescriptor)

                // Selection overlay
                if let entry = selectedEntry {
                    selectionOverlay(date: entry.date, amount: entry.cumulativeAmount)
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
        // Contain, not combine: combining flattened the chart into one
        // sentence and hid its Audio Graph.
        .accessibilityElement(children: .contain)
        .onChange(of: selectedEntry?.date) { _, newDate in
            onSelectionChange?(newDate)
        }
    }

    private func selectionOverlay(date: Date, amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.dateFormatter.string(from: date).uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(Formatters.currencyWhole(amount))
                .font(.brutalistHeading)
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f
    }()

    /// Spoken date for VoiceOver: "June 6", not "Jun 6" or "6/6". Carries the
    /// year only when the data crosses one, where "June 6" would be ambiguous.
    private static func spokenDate(_ date: Date, withYear: Bool) -> String {
        withYear
            ? date.formatted(.dateTime.month(.wide).day().year())
            : date.formatted(.dateTime.month(.wide).day())
    }

    /// Audio Graph description: the running total at each expense, with the
    /// final total and its date as the summary.
    private var chartDescriptor: CostChartDescriptor {
        let calendar = Calendar.current
        let years = Set(data.map { calendar.component(.year, from: $0.date) })
        let withYear = years.count > 1
        let points = data.map {
            SpokenChartPoint(label: Self.spokenDate($0.date, withYear: withYear), amount: $0.cumulativeAmount)
        }
        let summary = data.last.map {
            L10n.readoutChartPaceSummary(
                Formatters.currencyWhole($0.cumulativeAmount),
                Self.spokenDate($0.date, withYear: withYear),
                data.count
            )
        } ?? ""

        // Two expenses on one day share a label; the axis lists it once.
        var seen = Set<String>()
        let categories = points.map(\.label).filter { seen.insert($0).inserted }

        return CostChartDescriptor(
            title: L10n.readoutChartPaceTitle,
            summary: summary,
            xAxisTitle: L10n.readoutChartAxisDate,
            yAxisTitle: L10n.readoutChartAxisTotal,
            categories: categories,
            series: [SpokenChartSeries(name: L10n.readoutChartAxisTotal, points: points)],
            currencyCode: Formatters.currencyWhole.currencyCode ?? "USD"
        )
    }
}

#Preview {
    let calendar = Calendar.current

    let sampleData: [(date: Date, cumulativeAmount: Decimal)] = [
        (calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!, Decimal(85)),
        (calendar.date(from: DateComponents(year: 2025, month: 3, day: 2))!, Decimal(210)),
        (calendar.date(from: DateComponents(year: 2025, month: 5, day: 18))!, Decimal(450)),
        (calendar.date(from: DateComponents(year: 2025, month: 7, day: 8))!, Decimal(525)),
        (calendar.date(from: DateComponents(year: 2025, month: 9, day: 22))!, Decimal(780)),
        (calendar.date(from: DateComponents(year: 2025, month: 11, day: 5))!, Decimal(1050))
    ]

    return ZStack {
        AtmosphericBackground()

        CumulativeCostChartCard(data: sampleData)
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
