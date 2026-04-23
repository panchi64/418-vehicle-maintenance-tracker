//
//  CategoryBreakdownCard.swift
//  checkpoint
//
//  Card displaying cost breakdown by category with percentages
//

import SwiftUI

struct CategoryBreakdownCard: View {
    let breakdown: [(category: CostCategory, amount: Decimal, percentage: Double)]

    private var totalAmount: Decimal {
        breakdown.map(\.amount).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "By Category")

            VStack(spacing: 0) {
                // Proportion bar
                if totalAmount > 0 {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            ForEach(breakdown, id: \.category) { item in
                                let fraction = CGFloat(NSDecimalNumber(decimal: item.amount).doubleValue
                                    / NSDecimalNumber(decimal: totalAmount).doubleValue)
                                let minWidth: CGFloat = 4
                                Rectangle()
                                    .fill(item.category.color)
                                    .frame(width: max(minWidth, fraction * geo.size.width))
                            }
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)
                        .padding(.horizontal, Spacing.md)
                }

                ForEach(breakdown, id: \.category) { item in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(item.category.color)
                            .frame(width: 20)
                            .accessibilityHidden(true)

                        Text(item.category.displayName)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 40, alignment: .trailing)

                        Text(formatCurrency(item.amount))
                            .font(.brutalistBody)
                            .foregroundStyle(item.category.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 60, alignment: .trailing)
                    }
                    .padding(Spacing.md)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.category.displayName), \(formatCurrency(item.amount)), \(String(format: "%.0f", item.percentage)) percent")

                    if item.category != breakdown.last?.category {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                            .padding(.leading, 28)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        Formatters.currencyWhole(amount)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            CategoryBreakdownCard(breakdown: [
                (category: .maintenance, amount: 450.00, percentage: 60),
                (category: .repair, amount: 225.00, percentage: 30),
                (category: .upgrade, amount: 75.00, percentage: 10)
            ])

            CategoryBreakdownCard(breakdown: [
                (category: .repair, amount: 1200.00, percentage: 80),
                (category: .maintenance, amount: 300.00, percentage: 20)
            ])
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
