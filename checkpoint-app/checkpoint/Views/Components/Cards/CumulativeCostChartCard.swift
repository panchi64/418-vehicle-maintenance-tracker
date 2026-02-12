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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Spending Pace")

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
            }
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
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Spending pace chart showing cumulative costs over time")
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
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
