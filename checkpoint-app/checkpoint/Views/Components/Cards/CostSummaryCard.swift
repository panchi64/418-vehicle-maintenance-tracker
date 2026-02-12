//
//  CostSummaryCard.swift
//  checkpoint
//
//  Hero card displaying total spent amount with period context
//

import SwiftUI

struct CostSummaryCard: View {
    let formattedTotal: String
    let periodLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Total Spent")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            Text(formattedTotal)
                .font(.brutalistHero)
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(periodLabel)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total spent \(formattedTotal), \(periodLabel)")
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            CostSummaryCard(
                formattedTotal: "$1,234",
                periodLabel: "Year to date"
            )

            CostSummaryCard(
                formattedTotal: "$567",
                periodLabel: "Last 30 days"
            )

            CostSummaryCard(
                formattedTotal: "$0",
                periodLabel: "All time"
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
