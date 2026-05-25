//
//  RecallAlertCard.swift
//  checkpoint
//
//  Compact tap-target on the Home tab. Shows worst severity + count and
//  opens the full `RecallSheetView` on tap. Long-press exposes a snooze
//  menu (disabled when any recall is parkIt — safety override).
//

import SwiftUI
import SwiftData

struct RecallAlertCard: View {
    let vehicle: Vehicle
    /// Recalls that pass the visibility filter — drives the label and snooze count.
    let recalls: [RecallInfo]
    /// Full recall set (including resolved). Drives sheet contents so the
    /// "Show resolved" toggle has data to surface.
    let allRecalls: [RecallInfo]
    /// Passed in by parent (matches HomeTab's pattern of forwarding AppState
    /// instead of relying on environment injection that isn't set up here).
    let appState: AppState

    @Environment(\.modelContext) private var modelContext
    @State private var showSheet = false
    @State private var pendingAddServicePrefill: SeasonalPrefill?
    /// Tracks the (vehicle, recall-count) pair we last captured an impression
    /// for, so re-renders don't re-fire the analytics event.
    @State private var lastImpressionKey: String?

    private var worstSeverity: RecallSeverity { recalls.worstSeverity }
    private var hasParkIt: Bool { worstSeverity == .parkIt }

    private var countText: String {
        let count = recalls.count
        return "\(count) \(count == 1 ? "RECALL" : "RECALLS")"
    }

    private var severityLabel: String { worstSeverity.label.uppercased() }

    var body: some View {
        Button {
            HapticService.shared.tabChanged()
            showSheet = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.statusOverdue)

                if hasParkIt {
                    Text("PARK IT")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.statusOverdue)
                        .tracking(2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.statusOverdue.opacity(0.2))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(severityLabel)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.statusOverdue)
                        .tracking(1.5)
                    Text(countText)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.statusOverdue.opacity(0.8))
                        .tracking(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.statusOverdue)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .recallCardStyle()
        .contextMenu { snoozeMenu }
        .accessibilityLabel("\(severityLabel), \(countText). Tap for details.")
        .sheet(isPresented: $showSheet, onDismiss: presentPendingAddServiceIfNeeded) {
            RecallSheetView(
                vehicle: vehicle,
                recalls: allRecalls,
                onRequestAddPlannedService: { pendingAddServicePrefill = $0 }
            )
        }
        .onAppear { captureImpressionIfNeeded() }
        .onChange(of: allRecalls.count) { _, _ in captureImpressionIfNeeded() }
        .onChange(of: vehicle.id) { _, _ in captureImpressionIfNeeded() }
    }

    private func captureImpressionIfNeeded() {
        // Report the full fetched recall count (not the visible/post-filter
        // count) so the historical `recall_count` metric in PostHog stays
        // comparable to pre-impression-relocation values.
        let key = "\(vehicle.id)-\(allRecalls.count)"
        guard key != lastImpressionKey else { return }
        lastImpressionKey = key
        AnalyticsService.shared.capture(.recallAlertShown(recallCount: allRecalls.count))
    }

    // MARK: - Snooze menu

    @ViewBuilder
    private var snoozeMenu: some View {
        Section(L10n.recallSnoozeMenuTitle) {
            Button {
                snooze(days: 7)
            } label: {
                Label(L10n.recallSnooze7Days, systemImage: "clock")
            }
            .disabled(hasParkIt)

            Button {
                snooze(days: 30)
            } label: {
                Label(L10n.recallSnooze30Days, systemImage: "clock.badge")
            }
            .disabled(hasParkIt)

            if hasParkIt {
                Text(L10n.recallSnoozeDisabledParkIt)
            }
        }
    }

    /// Fires after the recall sheet finishes its dismiss animation, so a queued
    /// AddServiceView can present cleanly without iOS's only-one-sheet-at-a-time race.
    private func presentPendingAddServiceIfNeeded() {
        guard let prefill = pendingAddServicePrefill else { return }
        appState.seasonalPrefill = prefill
        appState.addServiceMode = .remind
        appState.showAddService = true
        pendingAddServicePrefill = nil
    }

    private func snooze(days: Int) {
        let store = RecallAckStore(context: modelContext)
        let count = store.snooze(recalls, days: days, vehicleID: vehicle.id)
        if count > 0 {
            AnalyticsService.shared.capture(.recallSnoozed(days: days, recallCount: count))
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Vehicle.self, RecallAcknowledgment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vehicle = Vehicle(name: "Civic", make: "Honda", model: "Civic", year: 2022, currentMileage: 30_000)
    container.mainContext.insert(vehicle)
    let previewAppState = AppState()

    let parkItRecalls: [RecallInfo] = [
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
    ]

    let openOnlyRecalls: [RecallInfo] = [
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
    ]

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                RecallAlertCard(vehicle: vehicle, recalls: parkItRecalls, allRecalls: parkItRecalls, appState: previewAppState)
                RecallAlertCard(vehicle: vehicle, recalls: openOnlyRecalls, allRecalls: openOnlyRecalls, appState: previewAppState)
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
