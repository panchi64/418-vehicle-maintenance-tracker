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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()

    /// Recalls sorted by report date descending (most recent first).
    private var sortedRecalls: [RecallInfo] {
        recalls.sorted { a, b in
            let dateA = Self.dateFormatter.date(from: a.reportDate) ?? .distantPast
            let dateB = Self.dateFormatter.date(from: b.reportDate) ?? .distantPast
            return dateA > dateB
        }
    }

    private var inlineRecalls: [RecallInfo] {
        Array(sortedRecalls.prefix(RecallAlertCard.inlineLimit))
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
            .accessibilityLabel(isExpanded ? "Collapse recall details" : "Expand recall details, \(countText)")

            // Expanded recall list (capped at inlineLimit)
            if isExpanded {
                VStack(spacing: 0) {
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
                            .frame(minHeight: 44)
                            .padding(.horizontal, Spacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View all \(recalls.count) recalls")
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
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Collapse recall details")
                }
                .transition(.opacity)
            }
        }
        .background(Theme.statusOverdue.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
        .sheet(isPresented: $showAllRecalls) {
            RecallDetailSheet(recalls: sortedRecalls)
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

            // NHTSA link
            if let nhtsaURL = URL(string: "https://www.nhtsa.gov/recalls") {
                Link(destination: nhtsaURL) {
                    HStack(spacing: Spacing.xs) {
                        Text("VIEW ON NHTSA")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .tracking(1.5)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.accent.opacity(0.1))
                    .contentShape(Rectangle())
                }
                .padding(.top, Spacing.sm)
                .accessibilityLabel("View recall \(recall.campaignNumber) on NHTSA website")
            }
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
