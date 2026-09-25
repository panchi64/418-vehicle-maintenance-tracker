//
//  CostChartDescriptors.swift
//  checkpoint
//
//  Audio Graph descriptors for the Costs charts.
//
//  Without these VoiceOver reads a Swift Charts chart as its marks' raw
//  values, or — once a card combines it — as a single sentence naming the
//  chart and nothing in it. A descriptor gives VoiceOver users the same data
//  a sighted user reads off the bars: every point with a spoken x value
//  ("June 2026", never "6/26"), the amount, and a one-line summary.
//
//  The descriptors are built from strings formatted on the main actor, so
//  `makeChartDescriptor()` reads only plain values and needs no isolation.
//

import Accessibility
import SwiftUI

// MARK: - Point

/// One chart point, already formatted for speech.
nonisolated struct SpokenChartPoint: Sendable {
    /// Spoken category, e.g. "June 2026" or "June 6".
    let label: String
    let value: Double

    init(label: String, amount: Decimal) {
        self.label = label
        self.value = NSDecimalNumber(decimal: amount).doubleValue
    }
}

/// One series of points. Stacked charts pass one per cost category.
nonisolated struct SpokenChartSeries: Sendable {
    let name: String
    let points: [SpokenChartPoint]
}

// MARK: - Descriptor

/// A categorical-x, currency-y chart description shared by both Costs charts.
nonisolated struct CostChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let summary: String
    let xAxisTitle: String
    let yAxisTitle: String
    /// Category order along x, left to right.
    let categories: [String]
    let series: [SpokenChartSeries]
    /// ISO 4217 code for spoken y values — pass the one `Formatters` uses so
    /// VoiceOver and the axis labels agree.
    let currencyCode: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let maxValue = series.flatMap(\.points).map(\.value).max() ?? 0
        let code = currencyCode

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: xAxisTitle,
            categoryOrder: categories
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: yAxisTitle,
            range: 0...max(maxValue, 1),
            gridlinePositions: []
        ) { value in
            value.formatted(.currency(code: code).precision(.fractionLength(0)))
        }

        return AXChartDescriptor(
            title: title,
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: series.map { series in
                AXDataSeriesDescriptor(
                    name: series.name,
                    isContinuous: false,
                    dataPoints: series.points.map { AXDataPoint(x: $0.label, y: $0.value) }
                )
            }
        )
    }
}
