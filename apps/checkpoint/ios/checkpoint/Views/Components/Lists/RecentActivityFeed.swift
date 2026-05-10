//
//  RecentActivityFeed.swift
//  checkpoint
//
//  Shows last 2-3 completed service entries — either a standalone log or a
//  Service Visit summary row. A visit holding 4 services renders as ONE row,
//  not 4 ("Service Visit · Mar 12 · $320"), so the feed stays scannable.
//

import SwiftUI

struct RecentActivityFeed: View {
    let serviceLogs: [ServiceLog]
    var maxItems: Int = 3

    private enum Item: Identifiable {
        case standalone(ServiceLog)
        case visit(ServiceVisit, [ServiceLog])

        var id: UUID {
            switch self {
            case .standalone(let log): return log.id
            case .visit(let visit, _): return visit.id
            }
        }

        var anchorDate: Date {
            switch self {
            case .standalone(let log): return log.performedDate
            case .visit(let visit, _): return visit.performedDate
            }
        }
    }

    private var items: [Item] {
        let sorted = serviceLogs.sorted { $0.performedDate > $1.performedDate }
        var seenVisitIDs: Set<UUID> = []
        var result: [Item] = []

        for log in sorted {
            if let visit = log.visit {
                guard !seenVisitIDs.contains(visit.id) else { continue }
                seenVisitIDs.insert(visit.id)
                let logsInVisit = sorted.filter { $0.visit?.id == visit.id }
                result.append(.visit(visit, logsInVisit))
            } else {
                result.append(.standalone(log))
            }
            if result.count >= maxItems { break }
        }

        return result
    }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Recent Activity")

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        switch item {
                        case .standalone(let log):
                            standaloneRow(log: log)
                        case .visit(let visit, let logs):
                            visitRow(visit: visit, logs: logs)
                        }

                        if index < items.count - 1 {
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

    private func standaloneRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)
                .accessibilityHidden(true)

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

    private func visitRow(visit: ServiceVisit, logs: [ServiceLog]) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.rectangle.stack")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Service Visit · \(logs.count) services")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(formatDate(visit.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = visit.formattedTotalCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Service Visit on \(formatDate(visit.performedDate)), \(logs.count) services")
        .accessibilityValue(visit.formattedTotalCost ?? "")
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
                        performedDate: Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
                        mileageAtService: 28000,
                        cost: 125.50
                    )
                    return log
                }()
            ])

            RecentActivityFeed(serviceLogs: [])
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
