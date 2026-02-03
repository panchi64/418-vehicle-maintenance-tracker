//
//  RecallAlertCard.swift
//  checkpoint
//
//  Safety recall alert card for the Home tab
//  Shows NHTSA recall information with urgency styling
//

import SwiftUI

struct RecallAlertCard: View {
    let recalls: [RecallInfo]

    @State private var isExpanded = false

    private var hasParkItRecall: Bool {
        recalls.contains { $0.parkIt }
    }

    private var countText: String {
        let count = recalls.count
        return "\(count) Open Recall\(count == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                // Soft haptic feedback for expand/collapse
                HapticService.shared.tabChanged()
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.statusOverdue)

                    if hasParkItRecall {
                        Text("PARK IT")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.statusOverdue)
                            .tracking(2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.statusOverdue.opacity(0.2))
                    }

                    Text(countText.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.statusOverdue)
                        .tracking(1.5)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.statusOverdue)
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded recall list
            if isExpanded {
                Rectangle()
                    .fill(Theme.statusOverdue.opacity(0.3))
                    .frame(height: 1)

                VStack(spacing: 0) {
                    ForEach(Array(recalls.enumerated()), id: \.element.id) { index, recall in
                        recallRow(recall)

                        if index < recalls.count - 1 {
                            Rectangle()
                                .fill(Theme.statusOverdue.opacity(0.15))
                                .frame(height: 1)
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
            }
        }
        .background(Theme.statusOverdue.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Recall Row

    private func recallRow(_ recall: RecallInfo) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Component
            HStack(spacing: Spacing.xs) {
                Text("COMPONENT")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                if recall.parkIt {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.statusOverdue)
                }
            }

            Text(recall.component)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            // Summary
            Text("SUMMARY")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
                .padding(.top, Spacing.xs)

            Text(recall.summary)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Consequence
            if !recall.consequence.isEmpty {
                Text("RISK")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusOverdue)
                    .tracking(1)
                    .padding(.top, Spacing.xs)

                Text(recall.consequence)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Remedy
            if !recall.remedy.isEmpty {
                Text("REMEDY")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusGood)
                    .tracking(1)
                    .padding(.top, Spacing.xs)

                Text(recall.remedy)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Campaign number & date
            HStack {
                Text("NHTSA #\(recall.campaignNumber)")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                Spacer()

                if !recall.reportDate.isEmpty {
                    Text(recall.reportDate)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                RecallAlertCard(recalls: [
                    RecallInfo(
                        campaignNumber: "24V123",
                        component: "AIR BAGS: FRONTAL",
                        summary: "The front passenger air bag inflator may explode during deployment.",
                        consequence: "An exploding inflator may result in sharp metal fragments striking the driver or passengers.",
                        remedy: "Dealers will replace the front passenger air bag inflator, free of charge.",
                        reportDate: "01/15/2024",
                        parkIt: true,
                        parkOutside: true
                    ),
                    RecallInfo(
                        campaignNumber: "23V456",
                        component: "FUEL SYSTEM, GASOLINE: DELIVERY: FUEL PUMP",
                        summary: "The fuel pump may fail causing the engine to stall.",
                        consequence: "An engine stall while driving increases the risk of a crash.",
                        remedy: "Dealers will replace the fuel pump assembly, free of charge.",
                        reportDate: "06/20/2023",
                        parkIt: false,
                        parkOutside: false
                    )
                ])

                RecallAlertCard(recalls: [
                    RecallInfo(
                        campaignNumber: "24V789",
                        component: "STEERING",
                        summary: "The steering column may detach from the steering gear.",
                        consequence: "Loss of steering control increases the risk of a crash.",
                        remedy: "Dealers will inspect and tighten the steering column, free of charge.",
                        reportDate: "03/10/2024",
                        parkIt: false,
                        parkOutside: false
                    )
                ])
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
