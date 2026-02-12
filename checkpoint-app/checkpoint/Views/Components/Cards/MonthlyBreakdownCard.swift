//
//  MonthlyBreakdownCard.swift
//  checkpoint
//
//  Card displaying monthly cost breakdown with bar indicators
//

import SwiftUI

struct MonthlyBreakdownCard: View {
    let breakdown: [(month: Date, amount: Decimal)]
    let maxDisplayCount: Int

    init(breakdown: [(month: Date, amount: Decimal)], maxDisplayCount: Int = 6) {
        self.breakdown = breakdown
        self.maxDisplayCount = maxDisplayCount
    }

    private var displayedItems: [(month: Date, amount: Decimal)] {
        Array(breakdown.prefix(maxDisplayCount))
    }

    private var maxAmount: Decimal {
        displayedItems.map(\.amount).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Monthly Breakdown")

            VStack(spacing: 0) {
                ForEach(Array(displayedItems.enumerated()), id: \.element.month) { index, item in
                    HStack(spacing: Spacing.sm) {
                        Text(formatMonthYear(item.month))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Simple bar indicator
                        if maxAmount > 0 {
                            let ratio = CGFloat(NSDecimalNumber(decimal: item.amount).doubleValue / NSDecimalNumber(decimal: maxAmount).doubleValue)
                            let barWidth = min(ratio * 60, 60)
                            Rectangle()
                                .fill(Theme.accent.opacity(0.3))
                                .frame(width: max(barWidth, 4), height: 8)
                        }

                        Text(formatCurrency(item.amount))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 60, alignment: .trailing)
                    }
                    .padding(Spacing.md)

                    if index < displayedItems.count - 1 {
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly cost breakdown")
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        Formatters.currencyWhole(amount)
    }
}

#Preview {
    let calendar = Calendar.current

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                MonthlyBreakdownCard(breakdown: [
                    (month: Date.now, amount: 350.00),
                    (month: calendar.date(byAdding: .month, value: -1, to: .now)!, amount: 125.00),
                    (month: calendar.date(byAdding: .month, value: -2, to: .now)!, amount: 275.00),
                    (month: calendar.date(byAdding: .month, value: -3, to: .now)!, amount: 89.00),
                    (month: calendar.date(byAdding: .month, value: -4, to: .now)!, amount: 450.00),
                    (month: calendar.date(byAdding: .month, value: -5, to: .now)!, amount: 200.00)
                ])

                MonthlyBreakdownCard(breakdown: [
                    (month: Date.now, amount: 150.00),
                    (month: calendar.date(byAdding: .month, value: -1, to: .now)!, amount: 150.00)
                ])
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
