//
//  MonthlyTrendChartCard.swift
//  checkpoint
//
//  Vertical bar chart showing monthly spending trends
//  Supports stacked bars by category when "All" filter is active
//

import SwiftUI
import Charts

struct MonthlyTrendChartCard: View {
    let breakdown: [(month: Date, amount: Decimal)]
    let breakdownByCategory: [(month: Date, category: CostCategory, amount: Decimal)]?
    let isStacked: Bool

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    /// Month stride count for x-axis labels based on data span
    private var xAxisMonthStride: Int {
        breakdown.count > 8 ? 3 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Monthly Trend")

            VStack(spacing: 0) {
                chart
                    .brutalistChartStyle()
                    .padding(Spacing.md)

                if isStacked, let byCategory = breakdownByCategory {
                    legend(for: byCategory)
                }
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )

            // Preserve text rows below chart
            textRows
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        if isStacked, let byCategory = breakdownByCategory {
            Chart(byCategory, id: \.month) { entry in
                BarMark(
                    x: .value("Month", entry.month, unit: .month),
                    y: .value("Amount", NSDecimalNumber(decimal: entry.amount).doubleValue)
                )
                .foregroundStyle(by: .value("Category", entry.category.displayName))
                .cornerRadius(0)
            }
            .chartForegroundStyleScale(categoryColorMapping(from: byCategory))
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: xAxisMonthStride)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisLabel(for: date))
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
        } else {
            Chart(breakdown, id: \.month) { entry in
                BarMark(
                    x: .value("Month", entry.month, unit: .month),
                    y: .value("Amount", NSDecimalNumber(decimal: entry.amount).doubleValue)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(0)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: xAxisMonthStride)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisLabel(for: date))
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
        }
    }

    // MARK: - Legend

    private func legend(for data: [(month: Date, category: CostCategory, amount: Decimal)]) -> some View {
        let categories = Array(Set(data.map(\.category))).sorted { $0.displayName < $1.displayName }

        return HStack(spacing: Spacing.md) {
            ForEach(categories, id: \.self) { category in
                HStack(spacing: Spacing.xs) {
                    Rectangle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)
                    Text(category.displayName.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Text Rows

    private var textRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(breakdown.reversed().enumerated()), id: \.element.month) { index, item in
                HStack(spacing: Spacing.sm) {
                    Text(formatMonthYear(item.month))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(formatCurrency(item.amount))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 60, alignment: .trailing)
                }
                .padding(Spacing.md)

                if index < breakdown.count - 1 {
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

    // MARK: - Helpers

    /// Format x-axis label: "MMM" normally, "MMM 'YY" for January
    private func xAxisLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let monthStr = Self.monthFormatter.string(from: date).uppercased()

        if month == 1 {
            let year = calendar.component(.year, from: date)
            return "\(monthStr)\n'\(String(year).suffix(2))"
        }
        return monthStr
    }

    private func categoryColorMapping(from data: [(month: Date, category: CostCategory, amount: Decimal)]) -> KeyValuePairs<String, Color> {
        let categories = Array(Set(data.map(\.category))).sorted { $0.displayName < $1.displayName }
        // KeyValuePairs must be a literal, so we build conditionally
        switch categories.count {
        case 1:
            return [categories[0].displayName: categories[0].color]
        case 2:
            return [
                categories[0].displayName: categories[0].color,
                categories[1].displayName: categories[1].color
            ]
        default:
            return [
                categories[0].displayName: categories[0].color,
                categories[1].displayName: categories[1].color,
                categories[2].displayName: categories[2].color
            ]
        }
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
    let calendar = Calendar.current

    let months: [(Date, Decimal)] = (0..<6).reversed().map { i in
        let date = calendar.date(byAdding: .month, value: -i, to: .now)!
        let components = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: components)!
        return (monthStart, Decimal(Int.random(in: 80...500)))
    }

    let byCategory: [(Date, CostCategory, Decimal)] = months.flatMap { month, _ in
        [
            (month, CostCategory.maintenance, Decimal(Int.random(in: 30...200))),
            (month, CostCategory.repair, Decimal(Int.random(in: 0...150))),
            (month, CostCategory.upgrade, Decimal(Int.random(in: 0...100)))
        ]
    }

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                MonthlyTrendChartCard(
                    breakdown: months,
                    breakdownByCategory: byCategory,
                    isStacked: true
                )

                MonthlyTrendChartCard(
                    breakdown: months,
                    breakdownByCategory: nil,
                    isStacked: false
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
