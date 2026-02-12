//
//  ChartPlaceholderCard.swift
//  checkpoint
//
//  Placeholder shown when a chart has insufficient data
//

import SwiftUI

struct ChartPlaceholderCard: View {
    var message: String = L10n.emptyChartPlaceholder

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)

            Text(message.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: ChartConstants.chartHeight)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ChartPlaceholderCard()
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
