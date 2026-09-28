import Charts
import SwiftUI

/// A station's 30-day price (PRODUCT.md §6.1 depth): one point per report
/// day, joined only between consecutive days so gaps stay gaps. The scale
/// doesn't start at zero, and the caption says so. VoiceOver gets the
/// headline plus an Audio Graph through Swift Charts.
struct PriceTrendChart: View {
    let trend: PriceTrend

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(trend.headline(unit: unit)).textRole(.headline).foregroundStyle(Color(.ink))
            Chart {
                ForEach(Array(runs.enumerated()), id: \.offset) { index, run in
                    ForEach(run, id: \.day) { point in
                        LineMark(x: .value("Día", point.day, unit: .day), y: .value("Precio", value(point)), series: .value("Tramo", index))
                            .foregroundStyle(.tint)
                            .interpolationMethod(.linear)
                        PointMark(x: .value("Día", point.day, unit: .day), y: .value("Precio", value(point)))
                            .foregroundStyle(.tint)
                            .symbolSize(24)
                    }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXScale(range: .plotDimension(padding: Spacing.s4))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { axis in
                    AxisGridLine()
                    AxisValueLabel {
                        if let cents = axis.as(Double.self) {
                            Text(verbatim: GlanceNumbers.dollars(cents: Int(cents.rounded()), locale: locale))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { axis in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = axis.as(Date.self) {
                            Text(verbatim: day.island(.dateTime.day().month(.abbreviated), locale: locale))
                        }
                    }
                }
            }
            .frame(height: 160)
            .accessibilityLabel(Text(trend.headline(unit: unit)))
            Text("Un punto por día con reportes de vecinos. Los días sin reportes quedan en blanco. La escala no empieza en cero.", comment: "Price chart caption: how the chart is drawn")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The value in the user's unit, in cents.
    private func value(_ point: PriceTrend.Point) -> Double {
        let cents = point.centsPerLitre
        return unit == .litre ? cents : cents * FuelPrice.litresPerGallon
    }

    /// Consecutive-day runs: a line never crosses a day nobody reported.
    private var runs: [[PriceTrend.Point]] {
        var runs: [[PriceTrend.Point]] = []
        for point in trend.points {
            if let last = runs.last?.last,
               let days = PuertoRico.calendar.dateComponents([.day], from: last.day, to: point.day).day, days <= 1 {
                runs[runs.count - 1].append(point)
            } else {
                runs.append([point])
            }
        }
        return runs
    }
}
