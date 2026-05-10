//
//  RecallSheetView.swift
//  checkpoint
//
//  Full-screen recall list, replacing both the inline expansion in
//  `RecallAlertCard` and the prior `RecallDetailSheet`. Groups recalls into
//  severity sections (Do Not Drive → Park Outside → Open), shows a
//  freshness subtitle in the toolbar, and exposes a "Show resolved" toggle
//  that surfaces the user's resolved recalls in a fourth section.
//

import SwiftUI
import SwiftData

struct RecallSheetView: View {
    let vehicle: Vehicle
    let recalls: [RecallInfo]
    /// Hands a planned-service prefill back to the parent. The parent stores it
    /// and presents AddServiceView in the sheet's `onDismiss` callback so iOS
    /// can finish the dismiss animation before the next sheet appears. When nil
    /// (e.g. opened from Settings), the "Add as planned service" CTA is hidden.
    let onRequestAddPlannedService: ((SeasonalPrefill) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var vehicleAcknowledgments: [RecallAcknowledgment]
    @State private var expandedRecallIDs: Set<String> = []
    @State private var showResolved = false

    init(
        vehicle: Vehicle,
        recalls: [RecallInfo],
        onRequestAddPlannedService: ((SeasonalPrefill) -> Void)? = nil
    ) {
        self.vehicle = vehicle
        self.recalls = recalls
        self.onRequestAddPlannedService = onRequestAddPlannedService
        let id = vehicle.id
        _vehicleAcknowledgments = Query(filter: #Predicate<RecallAcknowledgment> { $0.vehicleID == id })
    }

    private var acks: [String: RecallAcknowledgment] {
        Dictionary(
            vehicleAcknowledgments.map { ($0.campaignNumber, $0) },
            uniquingKeysWith: { lhs, _ in lhs }
        )
    }

    /// Recalls that count toward the "open" header (excludes resolved).
    private var activeRecalls: [RecallInfo] {
        recalls.filter { acks[$0.campaignNumber]?.status != .resolved }
    }

    private var resolvedRecalls: [RecallInfo] {
        recalls
            .filter { acks[$0.campaignNumber]?.status == .resolved }
            .sortedNewestFirst()
    }

    private var severityGroups: [(severity: RecallSeverity, recalls: [RecallInfo])] {
        activeRecalls.groupedBySeverity()
    }

    private var showSectionHeaders: Bool {
        severityGroups.count > 1
    }

    private var titleText: String {
        let count = activeRecalls.count
        return count == 1 ? L10n.recallSheetTitleSingular : L10n.recallSheetTitlePlural(count)
    }

    private var lastCheckedSubtitle: String? {
        guard let timeAgo = RecallCheckCache.shared.lastCheckedDescription else { return nil }
        return L10n.recallLastChecked(timeAgo)
    }

    /// Renders the empty placeholder when nothing else would draw — prevents the
    /// sheet from collapsing to an empty ScrollView (which leaves a blank screen
    /// under the toolbar).
    private var isEmptyState: Bool {
        severityGroups.isEmpty && (!showResolved || resolvedRecalls.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xs) {
                    ForEach(severityGroups, id: \.severity) { group in
                        if showSectionHeaders {
                            InstrumentSectionHeader(title: group.severity.label.uppercased())
                                .padding(.top, Spacing.sm)
                        }
                        ForEach(group.recalls, id: \.id) { recall in
                            recallRow(recall)
                        }
                    }

                    if showResolved && !resolvedRecalls.isEmpty {
                        InstrumentSectionHeader(title: L10n.recallSectionResolved.uppercased())
                            .padding(.top, Spacing.sm)
                        ForEach(resolvedRecalls, id: \.id) { recall in
                            recallRow(recall)
                        }
                    }

                    if isEmptyState {
                        emptyState
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
                    VStack(spacing: 2) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.statusOverdue)
                            Text(titleText.uppercased())
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.statusOverdue)
                                .tracking(1.5)
                        }
                        if let subtitle = lastCheckedSubtitle {
                            Text(subtitle)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !resolvedRecalls.isEmpty {
                        Button {
                            showResolved.toggle()
                        } label: {
                            Label {
                                Text(L10n.recallToggleShowResolved)
                            } icon: {
                                Image(systemName: showResolved ? "checkmark.circle.fill" : "circle")
                            }
                        }
                        .tint(showResolved ? Theme.accent : Theme.textSecondary)
                        .accessibilityLabel(L10n.recallToggleShowResolved)
                        .accessibilityValue(showResolved ? "On" : "Off")
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
        .onAppear {
            RecallAckStore(context: modelContext).clearExpiredSnoozes(for: vehicle.id)
            // If everything's already resolved, surface the resolved section so the user
            // sees something — otherwise the sheet looks broken (header says "0 open").
            if activeRecalls.isEmpty && !resolvedRecalls.isEmpty {
                showResolved = true
            }
            AnalyticsService.shared.capture(.recallSheetOpened(recallCount: activeRecalls.count))
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.statusGood)

            Text(L10n.recallEmptyAllClear.uppercased())
                .font(.brutalistHeading)
                .foregroundStyle(Theme.textPrimary)
                .tracking(1.5)

            if !resolvedRecalls.isEmpty {
                Text(L10n.recallEmptyToggleHint)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Row factory

    private func recallRow(_ recall: RecallInfo) -> some View {
        let status = acks[recall.campaignNumber]?.status ?? .open
        return RecallRowCard(
            recall: recall,
            vehicle: vehicle,
            status: status,
            isExpanded: expandedRecallIDs.contains(recall.id),
            onToggle: {
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    if expandedRecallIDs.contains(recall.id) {
                        expandedRecallIDs.remove(recall.id)
                    } else {
                        expandedRecallIDs.insert(recall.id)
                    }
                }
            },
            onSetStatus: { newStatus in
                let store = RecallAckStore(context: modelContext)
                store.setStatus(newStatus, vehicleID: vehicle.id, campaignNumber: recall.campaignNumber)
                AnalyticsService.shared.capture(.recallStatusChanged(
                    status: newStatus.rawValue,
                    campaignNumber: recall.campaignNumber
                ))
            },
            onAddPlannedService: onRequestAddPlannedService.map { handler in
                {
                    let prefill = SeasonalPrefill(
                        reminderID: "recall_\(recall.campaignNumber)",
                        serviceName: L10n.recallPlannedServiceName(recall.component.localizedCapitalized),
                        dueDate: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
                        intervalMonths: 0
                    )
                    handler(prefill)
                    dismiss()
                }
            }
        )
    }
}
