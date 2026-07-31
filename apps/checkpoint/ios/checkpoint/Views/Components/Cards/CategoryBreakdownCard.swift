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
                        let widths = segmentWidths(in: geo.size.width)
                        HStack(spacing: 0) {
                            ForEach(Array(breakdown.enumerated()), id: \.element.category) { index, item in
                                Rectangle()
                                    .fill(item.category.color)
                                    .frame(width: widths[index])
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

    /// Segment widths that sum to exactly `totalWidth`.
    ///
    /// Every category gets a visible floor first, then shares what's left in
    /// proportion. Taking `max(floor, fraction * width)` per segment instead —
    /// which is what this did — makes the bar wider than its container as soon
    /// as any category rounds below the floor: three categories at 98/1/1 came
    /// out ~8pt over and spilled past the card's right border, since a
    /// `GeometryReader` doesn't clip what overflows it.
    private func segmentWidths(in totalWidth: CGFloat) -> [CGFloat] {
        let total = NSDecimalNumber(decimal: totalAmount).doubleValue
        let fractions = breakdown.map {
            CGFloat(NSDecimalNumber(decimal: $0.amount).doubleValue / total)
        }

        let minWidth: CGFloat = 4
        let floorTotal = minWidth * CGFloat(fractions.count)
        // Not enough room to floor every segment: fall back to pure proportion,
        // which still sums to the container width.
        guard totalWidth > floorTotal else {
            return fractions.map { $0 * totalWidth }
        }

        let shared = totalWidth - floorTotal
        return fractions.map { minWidth + $0 * shared }
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
