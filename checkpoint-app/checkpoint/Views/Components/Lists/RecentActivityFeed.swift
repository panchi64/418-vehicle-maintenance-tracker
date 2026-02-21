//
//  RecentActivityFeed.swift
//  checkpoint
//
//  Shows last 2-3 completed services with date and cost
//

import SwiftUI

struct RecentActivityFeed: View {
    let serviceLogs: [ServiceLog]
    var maxItems: Int = 3

    private var recentLogs: [ServiceLog] {
        serviceLogs
            .sorted { $0.performedDate > $1.performedDate }
            .prefix(maxItems)
            .map { $0 }
    }

    var body: some View {
        if !recentLogs.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Recent Activity")

                VStack(spacing: 0) {
                    ForEach(Array(recentLogs.enumerated()), id: \.element.id) { index, log in
                        activityRow(log: log)

                        if index < recentLogs.count - 1 {
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
    }

    private func activityRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            // Checkmark indicator
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)
                .accessibilityHidden(true)

            // Service name and date
            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(formatDate(log.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            // Cost (if available)
            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.service?.name ?? "Service") completed \(formatDate(log.performedDate))")
        .accessibilityValue(log.formattedCost ?? "")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            // With data
            RecentActivityFeed(serviceLogs: [
                {
                    let log = ServiceLog(
                        performedDate: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
                        mileageAtService: 32500,
                        cost: 45.99
                    )
                    return log
                }(),
                {
                    let log = ServiceLog(
                        performedDate: Calendar.current.date(byAdding: .day, value: -35, to: .now)!,
                        mileageAtService: 31000,
                        cost: 0
                    )
                    return log
                }(),
                {
                    let log = ServiceLog(
                        performedDate: Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
                        mileageAtService: 28000,
                        cost: 125.50
                    )
                    return log
                }()
            ])

            // Empty state (shows nothing)
            RecentActivityFeed(serviceLogs: [])
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
