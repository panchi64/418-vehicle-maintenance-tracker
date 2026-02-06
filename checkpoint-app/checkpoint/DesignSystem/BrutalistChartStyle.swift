//
//  BrutalistChartStyle.swift
//  checkpoint
//
//  Chart styling infrastructure for brutalist design system
//  Enforces zero corner radius, monospace labels, grid lines
//

import SwiftUI
import Charts

// MARK: - Chart Constants

enum ChartConstants {
    static let chartHeight: CGFloat = 160
    static let chartLineWidth: CGFloat = 2
    static let chartGridLineWidth: CGFloat = 0.5
    static let pointSize: CGFloat = 4
}

// MARK: - Brutalist Chart Style Modifier

struct BrutalistChartStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartConstants.chartGridLineWidth))
                        .foregroundStyle(Theme.gridLine)
                    AxisValueLabel()
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(height: ChartConstants.chartHeight)
    }
}

extension View {
    func brutalistChartStyle() -> some View {
        modifier(BrutalistChartStyle())
    }
}

// MARK: - Abbreviated Currency Formatter

enum ChartFormatting {
    static func abbreviatedCurrency(_ value: Double) -> String {
        if value >= 1000 {
            let k = value / 1000
            if k.truncatingRemainder(dividingBy: 1) == 0 {
                return "$\(Int(k))K"
            }
            return String(format: "$%.1fK", k)
        }
        return "$\(Int(value))"
    }
}
