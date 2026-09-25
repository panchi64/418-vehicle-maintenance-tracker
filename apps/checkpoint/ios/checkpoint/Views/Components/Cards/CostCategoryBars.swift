//
//  CostCategoryBars.swift
//  checkpoint
//
//  The Costs tab's Category picture: one row per bucket, largest first —
//  name, amount and share in text, then a thin proportional bar. The largest
//  bucket's bar is the accent; the rest recede. Category hue is not used:
//  the text names every bucket, and color is spoken for by status.
//
//  "Uncategorized" is a bucket like any other, so the rows always sum to the
//  period total the hero shows.
//

import SwiftUI

struct CostCategoryBars: View {
    let shares: [CostBucketShare]
    /// Chart title and written summary, reused for the Audio Graph.
    let title: String
    let summary: String

    @ScaledMetric(relativeTo: .footnote) private var barHeight: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(shares.enumerated()), id: \.element.id) { index, share in
                row(share, isLargest: index == 0)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityChartDescriptor(descriptor)
    }

    private func row(_ share: CostBucketShare, isLargest: Bool) -> some View {
        let amount = Formatters.currencyWhole(share.amount)
        let percent = Int((share.fraction * 100).rounded())

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            AdaptiveStack(spacing: Spacing.sm) {
                Text(share.bucket.displayName)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                AdaptiveSpacer()
                Text(L10n.costsCategoryAmountShare(amount, percent))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: barHeight)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(isLargest ? Theme.accent : Theme.accentMuted)
                            .frame(width: geo.size.width * min(max(share.fraction, 0), 1))
                    }
                }
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.readoutCategoryShare(share.bucket.displayName, amount, percent))
    }

    private var descriptor: CostChartDescriptor {
        let points = shares.map { SpokenChartPoint(label: $0.bucket.displayName, amount: $0.amount) }
        return CostChartDescriptor(
            title: title,
            summary: summary,
            xAxisTitle: L10n.costsChartCategory,
            yAxisTitle: L10n.readoutChartAxisAmount,
            categories: points.map(\.label),
            series: [SpokenChartSeries(name: L10n.readoutChartSeriesSpending, points: points)],
            currencyCode: Formatters.currencyWhole.currencyCode ?? "USD"
        )
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CostCategoryBars(
            shares: [
                CostBucketShare(bucket: .category(.repair), amount: 1200, fraction: 0.6),
                CostBucketShare(bucket: .category(.maintenance), amount: 600, fraction: 0.3),
                CostBucketShare(bucket: .uncategorized, amount: 200, fraction: 0.1)
            ],
            title: "By Category, USD",
            summary: ""
        )
        .padding(Spacing.screenHorizontal)
    }
}
