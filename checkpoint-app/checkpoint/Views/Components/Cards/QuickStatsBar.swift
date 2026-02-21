//
//  QuickStatsBar.swift
//  checkpoint
//
//  Compact horizontal bar showing YTD spend and services completed
//

import SwiftUI

struct QuickStatsBar: View {
    let serviceLogs: [ServiceLog]

    private var ytdLogs: [ServiceLog] {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: .now)) ?? .now
        return serviceLogs.filter { $0.performedDate >= startOfYear }
    }

    private var ytdSpend: Decimal {
        ytdLogs.compactMap { $0.cost }.reduce(0, +)
    }

    private var ytdServicesCount: Int {
        ytdLogs.count
    }

    private var formattedYTDSpend: String {
        ytdLogs.isEmpty ? "\u{2014}" : Formatters.currencyWhole(ytdSpend)
    }

    private var formattedYTDCount: String {
        ytdLogs.isEmpty ? "\u{2014}" : "\(ytdServicesCount)"
    }

    var body: some View {
        HStack(spacing: 0) {
            // YTD Spend
            statItem(
                label: "YTD",
                value: formattedYTDSpend,
                valueColor: Theme.accent
            )

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(width: Theme.borderWidth)

            // Services Completed
            statItem(
                label: "SERVICES",
                value: formattedYTDCount,
                valueColor: Theme.textPrimary
            )
        }
        .frame(height: 56)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Year to date: \(formattedYTDSpend) spent, \(ytdServicesCount) services completed")
    }

    private func statItem(label: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            // With data
            QuickStatsBar(serviceLogs: [
                ServiceLog(
                    performedDate: .now,
                    mileageAtService: 32500,
                    cost: 45.99
                ),
                ServiceLog(
                    performedDate: Calendar.current.date(byAdding: .month, value: -2, to: .now)!,
                    mileageAtService: 30000,
                    cost: 125.50
                ),
                ServiceLog(
                    performedDate: Calendar.current.date(byAdding: .month, value: -4, to: .now)!,
                    mileageAtService: 28000,
                    cost: 89.00
                ),
                ServiceLog(
                    performedDate: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
                    mileageAtService: 20000,
                    cost: 200.00
                )
            ])

            // Empty state
            QuickStatsBar(serviceLogs: [])
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
