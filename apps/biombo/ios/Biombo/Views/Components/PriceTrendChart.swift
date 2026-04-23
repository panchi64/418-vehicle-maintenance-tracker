import SwiftUI
import SwiftData
import Charts
import DesignKit

struct PriceTrendChart: View {
    @Environment(\.theme) private var theme
    @Query private var points: [PriceHistoryPoint]

    init(stationId: String, days: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        _points = Query(
            filter: #Predicate<PriceHistoryPoint> { point in
                point.stationId == stationId && point.date > cutoff
            },
            sort: \.date
        )
    }

    var body: some View {
        if points.isEmpty {
            placeholder
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                if let regular = point.regular {
                    LineMark(
                        x: .value("history.date", point.date),
                        y: .value("history.price", regular)
                    )
                    .foregroundStyle(theme.accent)
                    .interpolationMethod(.linear)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine().foregroundStyle(theme.gridLine.opacity(0.3))
                AxisValueLabel()
                    .font(theme.font(.caption2))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(theme.gridLine.opacity(0.3))
                AxisValueLabel()
                    .font(theme.font(.caption2))
                    .foregroundStyle(theme.textTertiary)
            }
        }
    }

    private var placeholder: some View {
        Text("history.empty")
            .font(theme.font(.caption))
            .foregroundStyle(theme.textTertiary)
            .textCase(.uppercase)
            .tracking(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .brutalistBorder(color: theme.borderSubtle, lineWidth: 2)
    }
}
