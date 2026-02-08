//
//  RecallAlertCard.swift
//  checkpoint
//
//  Safety recall alert card for the Home tab
//  Shows NHTSA recall information with urgency styling
//

import SwiftUI

struct RecallAlertCard: View {
    /// Max recalls shown inline before prompting "view all"
    private static let inlineLimit = 3
    let recalls: [RecallInfo]

    @State private var isExpanded = false
    @State private var showAllRecalls = false

    private var hasParkItRecall: Bool {
        recalls.contains { $0.parkIt }
    }

    private var countText: String {
        let count = recalls.count
        return "\(count) Open Recall\(count == 1 ? "" : "s")"
    }

    private var inlineRecalls: [RecallInfo] {
        Array(recalls.prefix(RecallAlertCard.inlineLimit))
    }

    private var hasOverflow: Bool {
        recalls.count > RecallAlertCard.inlineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
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

            // Expanded recall list (capped at inlineLimit)
            if isExpanded {
                Rectangle()
                    .fill(Theme.statusOverdue.opacity(0.3))
                    .frame(height: 1)

                VStack(spacing: 0) {
                    ForEach(Array(inlineRecalls.enumerated()), id: \.element.id) { index, recall in
                        recallRow(recall)

                        if index < inlineRecalls.count - 1 {
                            Rectangle()
                                .fill(Theme.statusOverdue.opacity(0.15))
                                .frame(height: 1)
                                .padding(.leading, Spacing.md)
                        }
                    }
                }

                // "View all" button when there are more recalls than shown
                if hasOverflow {
                    Rectangle()
                        .fill(Theme.statusOverdue.opacity(0.3))
                        .frame(height: 1)

                    Button {
                        showAllRecalls = true
                    } label: {
                        HStack {
                            Text("VIEW ALL \(recalls.count) RECALLS")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.statusOverdue)
                                .tracking(1.5)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.statusOverdue)
                        }
                        .padding(Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Collapse footer
                Rectangle()
                    .fill(Theme.statusOverdue.opacity(0.3))
                    .frame(height: 1)

                Button {
                    HapticService.shared.tabChanged()
                    withAnimation(.easeOut(duration: Theme.animationMedium)) {
                        isExpanded = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.statusOverdue.opacity(0.6))
                        Text("COLLAPSE")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.statusOverdue.opacity(0.6))
                            .tracking(1.5)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.statusOverdue.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
        .sheet(isPresented: $showAllRecalls) {
            RecallListSheet(recalls: recalls)
        }
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

// MARK: - Recall List Sheet

struct RecallListSheet: View {
    let recalls: [RecallInfo]
    @Environment(\.dismiss) private var dismiss
    @State private var expandedRecallIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(recalls, id: \.id) { recall in
                        RecallAccordionCard(
                            recall: recall,
                            isExpanded: expandedRecallIDs.contains(recall.id)
                        ) {
                            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                                if expandedRecallIDs.contains(recall.id) {
                                    expandedRecallIDs.remove(recall.id)
                                } else {
                                    expandedRecallIDs.insert(recall.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.statusOverdue)
                        Text("\(recalls.count) OPEN RECALLS")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.statusOverdue)
                            .tracking(1.5)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Recall Accordion Card

/// Individual collapsible recall card for the sheet view.
/// Collapsed: shows component name and campaign number.
/// Expanded: shows full detail (summary, risk, remedy).
private struct RecallAccordionCard: View {
    let recall: RecallInfo
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button {
                onToggle()
            } label: {
                HStack(spacing: Spacing.sm) {
                    // Park-it indicator
                    if recall.parkIt {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.statusOverdue)
                    }

                    // Component name
                    Text(recall.component)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(isExpanded ? nil : 1)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.statusOverdue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                Rectangle()
                    .fill(Theme.statusOverdue.opacity(0.3))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Summary
                    Text("SUMMARY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.statusOverdue.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
        .clipped()
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
