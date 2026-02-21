//
//  RecallDetailSheet.swift
//  checkpoint
//
//  Full-list sheet for viewing all recall details.
//  Extracted from RecallAlertCard for single-responsibility.
//

import SwiftUI

struct RecallDetailSheet: View {
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
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
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
            .accessibilityLabel("\(recall.component), \(isExpanded ? "expanded" : "collapsed")")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand details")

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
                .transition(.opacity)
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
