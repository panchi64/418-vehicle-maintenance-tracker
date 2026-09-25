//
//  ServiceDetailView.swift
//  checkpoint
//
//  One service: where it stands, its schedule, and what has been done.
//  Pushed (a detail you read and back out of); Edit is in the toolbar,
//  Delete at the end of the scroll. Sections live in
//  ServiceDetailView+Sections.swift.
//

import SwiftUI
import SwiftData

struct ServiceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) var appState

    @Bindable var service: Service
    let vehicle: Vehicle

    @State private var showEditSheet = false
    @State private var showMarkDoneSheet = false
    @State private var didCompleteMark = false
    @State private var confirmDelete = false
    /// Set when Delete is confirmed; the delete runs once this screen has
    /// popped, so nothing on its way out reads a deleted model.
    @State private var deleteAfterPop = false

    var body: some View {
        // Judged by the same effective mileage as the list row that opened
        // this screen — raw `currentMileage` here let the two disagree.
        let mileage = vehicle.mileageEstimate
        let status = service.status(currentMileage: mileage.effective)
        let logs = (service.logs ?? []).sorted { $0.performedDate > $1.performedDate }

        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Log-only services have no status to headline.
                if status != .neutral {
                    statusCard(status: status, mileage: mileage)
                }

                primaryAction(status: status)

                // Chain-spawn clears intervals on the closed row, so
                // `hasDueTracking` is the right gate for the schedule.
                if service.hasDueTracking {
                    scheduleSection
                }

                if !logs.isEmpty {
                    historySection(logs)
                    insightsSection(logs, mileage: mileage)
                }

                let attachments = logs.flatMap { $0.attachments ?? [] }.sorted { $0.createdAt < $1.createdAt }
                if !attachments.isEmpty {
                    AttachmentSection(
                        attachments: attachments,
                        onSelect: { appState.push(.document($0)) }
                    )
                }

                endActions
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .trackScreen(.serviceDetail)
        .background(Theme.backgroundPrimary)
        .navigationTitle(service.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.servicesActionEdit) {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            // Deleted from the edit form: nothing left to show.
            if service.modelContext == nil || service.isDeleted {
                dismiss()
            }
        }) {
            EditServiceView(service: service, vehicle: vehicle)
        }
        .sheet(isPresented: $showMarkDoneSheet, onDismiss: {
            if didCompleteMark {
                didCompleteMark = false
                dismiss()
            }
        }) {
            MarkServiceDoneSheet(service: service, vehicle: vehicle, onSaved: {
                didCompleteMark = true
            })
        }
        .confirmationDialog(
            L10n.serviceDeleteConfirmTitle,
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button(L10n.commonDelete, role: .destructive) {
                deleteAfterPop = true
                dismiss()
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.serviceDeleteConfirmMessage)
        }
        .onDisappear {
            guard deleteAfterPop else { return }
            deleteAfterPop = false
            ServiceDeleteAction.delete([service], vehicle: vehicle, in: modelContext)
        }
    }

    // MARK: - Status

    /// The hero: status, then how far off it is, then when. The figure keeps
    /// to one line and scales down rather than breaking mid-word at large
    /// type ("remain/ing" in a narrow card at AX5).
    private func statusCard(status: ServiceStatus, mileage: MileageEstimate) -> some View {
        let urgency = service.urgencyText(currentMileage: mileage.effective)

        return VStack(spacing: Spacing.md) {
            StatusTag(status: status)

            if let urgency {
                Text(urgency)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Text(service.dueLine)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassCardStyle(intensity: .subtle, padding: 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.readoutStatus(status))
        .accessibilityValue([urgency, service.dueLine].compactMap { $0 }.joined(separator: ", "))
    }

    // MARK: - Actions

    /// One primary action: complete it, or — for a log-only service — give it
    /// a schedule.
    @ViewBuilder
    private func primaryAction(status: ServiceStatus) -> some View {
        if status == .neutral {
            Button {
                showEditSheet = true
            } label: {
                Label(L10n.servicesDetailSetUpReminder, systemImage: "bell.badge")
            }
            .buttonStyle(.primary)
        } else {
            Button {
                showMarkDoneSheet = true
            } label: {
                Label(L10n.servicesActionMarkDone, systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.primary)
        }
    }

    /// Rarer, heavier actions at the end of the scroll. Stop Tracking takes a
    /// skipped service off the schedule without inventing a log for it.
    private var endActions: some View {
        VStack(spacing: Spacing.sm) {
            if service.hasDueTracking {
                Button {
                    ServiceDeleteAction.stopTracking(service, vehicle: vehicle)
                } label: {
                    Label(L10n.servicesActionStopTracking, systemImage: "bell.slash")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(L10n.servicesDetailStopTrackingHint)
            }

            DestructiveFormButton(title: L10n.serviceDeleteAction) {
                confirmDelete = true
            }
        }
        .padding(.top, Spacing.lg)
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    @Previewable @State var service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 34500,
        intervalMonths: 6,
        intervalMiles: 5000
    )

    NavigationStack {
        ServiceDetailView(service: service, vehicle: vehicle)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .environment(AppState())
    .preferredColorScheme(.dark)
}
