//
//  YearlyCostRoundupCard.swift
//  checkpoint
//
//  Annual summary card showing total spent, YoY comparison,
//  category breakdown, and miles driven.
//

import SwiftUI
import SwiftData

struct YearlyCostRoundupCard: View {
    let year: Int
    let serviceLogs: [ServiceLog]
    let previousYearLogs: [ServiceLog]

    private var calendar: Calendar { Calendar.current }

    // MARK: - Computed Properties

    private var yearLogs: [ServiceLog] {
        serviceLogs.filter { log in
            calendar.component(.year, from: log.performedDate) == year
        }
    }

    private var logsWithCosts: [ServiceLog] {
        yearLogs.filter { $0.cost != nil && $0.cost! > 0 }
    }

    private var totalSpent: Decimal {
        logsWithCosts.compactMap { $0.cost }.reduce(0, +)
    }

    private var previousYearTotal: Decimal {
        previousYearLogs
            .filter { $0.cost != nil && $0.cost! > 0 }
            .compactMap { $0.cost }
            .reduce(0, +)
    }

    private var yearOverYearChange: Double? {
        guard previousYearTotal > 0 else { return nil }
        let current = NSDecimalNumber(decimal: totalSpent).doubleValue
        let previous = NSDecimalNumber(decimal: previousYearTotal).doubleValue
        return ((current - previous) / previous) * 100
    }

    private var serviceCount: Int {
        yearLogs.count
    }

    private var estimatedMilesDriven: Int? {
        let sortedLogs = yearLogs.sorted { $0.performedDate < $1.performedDate }
        guard let first = sortedLogs.first,
              let last = sortedLogs.last,
              last.mileageAtService > first.mileageAtService else { return nil }
        return last.mileageAtService - first.mileageAtService
    }

    private var categoryBreakdown: [(category: CostCategory, amount: Decimal, percentage: Double)] {
        guard totalSpent > 0 else { return [] }

        var breakdown: [(CostCategory, Decimal, Double)] = []

        for category in CostCategory.allCases {
            let categoryLogs = logsWithCosts.filter { $0.costCategory == category }
            let amount = categoryLogs.compactMap { $0.cost }.reduce(0, +)
            if amount > 0 {
                let percentage = NSDecimalNumber(decimal: amount).doubleValue /
                    NSDecimalNumber(decimal: totalSpent).doubleValue * 100
                breakdown.append((category, amount, percentage))
            }
        }

        return breakdown.sorted { $0.1 > $1.1 }
    }

    // MARK: - Formatters

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }

    private func formatMiles(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "~" + (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)")
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)

            // Total spent section
            totalSpentSection

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)

            // Category breakdown
            if !categoryBreakdown.isEmpty {
                categorySection

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }

            // Footer stats
            footerSection
        }
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("\(String(year)) YEARLY ROUNDUP")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
    }

    // MARK: - Total Spent Section

    private var totalSpentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("TOTAL SPENT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(formatCurrency(totalSpent))
                .font(.brutalistHero)
                .foregroundStyle(Theme.accent)

            if let change = yearOverYearChange {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .bold))

                    Text(String(format: "%.0f%% from %d", abs(change), year - 1))
                        .font(.brutalistSecondary)
                }
                .foregroundStyle(change >= 0 ? Theme.statusOverdue : Theme.statusGood)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("BY CATEGORY")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
                .padding(.bottom, Spacing.xs)

            ForEach(categoryBreakdown, id: \.category) { item in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(item.category.color)
                        .frame(width: 16)

                    Text(item.category.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text(formatCurrency(item.amount))
                        .font(.brutalistBody)
                        .foregroundStyle(item.category.color)

                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SERVICES")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                Text("\(serviceCount)")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("MILES")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                if let miles = estimatedMilesDriven {
                    Text(formatMiles(miles))
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                } else {
                    Text("-")
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
    }
}

#Preview {
    let vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 45000
    )

    let sampleLogs = ServiceLog.sampleLogs(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                YearlyCostRoundupCard(
                    year: 2025,
                    serviceLogs: sampleLogs,
                    previousYearLogs: []
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
