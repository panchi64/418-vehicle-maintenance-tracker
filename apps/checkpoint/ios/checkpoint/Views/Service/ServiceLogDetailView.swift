//
//  ServiceLogDetailView.swift
//  checkpoint
//
//  Detail view for a single service log showing all recorded information
//

import SwiftUI
import SwiftData

struct ServiceLogDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Bindable var log: ServiceLog

    /// Hands the log to the presenter for deletion. The presenter deletes it in
    /// its sheet's `onDismiss`, not here: a model deleted while this sheet is
    /// still animating away can be read by a view that no longer has it. nil
    /// hides Delete.
    var onDelete: ((ServiceLog) -> Void)? = nil

    /// Whether to confirm before deleting. True when the presenter is itself a
    /// sheet, where the Undo toast (rendered at the app root) would be hidden —
    /// an Undo nobody can see is not a safety net, so ask instead.
    var confirmsDelete = false

    @State private var showEditSheet = false
    @State private var attachmentForDetail: Document?
    @State private var showDeleteConfirmation = false
    @State private var deleteRequestedFromEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Service name header
                serviceHeader

                // Details section
                detailsSection

                // Notes section
                if let notes = log.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                // Attachments
                if !(log.attachments ?? []).isEmpty {
                    AttachmentSection(
                        attachments: log.attachments ?? [],
                        onSelect: { attachmentForDetail = $0 }
                    )
                }

                if onDelete != nil {
                    DestructiveFormButton(title: L10n.logDeleteAction) {
                        requestDelete()
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .trackScreen(.serviceLogDetail)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Service Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("Close")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .toolbarButtonStyle()
                .accessibilityLabel("Edit service log")
            }
        }
        // Delete from the edit form waits for the form to finish dismissing,
        // then runs the same path as the button here.
        .sheet(isPresented: $showEditSheet, onDismiss: {
            guard deleteRequestedFromEdit else { return }
            deleteRequestedFromEdit = false
            requestDelete()
        }) {
            EditServiceLogView(
                log: log,
                onDelete: onDelete == nil ? nil : { deleteRequestedFromEdit = true }
            )
            .environment(appState)
        }
        .sheet(item: $attachmentForDetail) { document in
            DocumentDetailView(document: document)
                .environment(appState)
        }
        .confirmationDialog(
            L10n.logDeleteConfirmTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.commonDelete, role: .destructive) { commitDelete() }
            Button(L10n.commonCancel, role: .cancel) { }
        } message: {
            Text(L10n.logDeleteConfirmMessage)
        }
    }

    // MARK: - Delete

    private func requestDelete() {
        if confirmsDelete {
            showDeleteConfirmation = true
        } else {
            commitDelete()
        }
    }

    private func commitDelete() {
        onDelete?(log)
        dismiss()
    }

    // MARK: - Service Header

    private var serviceHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Category icon
            if let category = log.editableCostCategory {
                Image(systemName: category.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(category.color)
            } else {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }

            Text(log.service?.name ?? L10n.serviceFallbackName)
                .font(.brutalistTitle)
                .foregroundStyle(Theme.textPrimary)

            Text(Formatters.mediumDate.string(from: log.performedDate))
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassCardStyle(intensity: .subtle, padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.service?.name ?? "Service"), \(Formatters.mediumDate.string(from: log.performedDate))")
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        InstrumentSection(title: "Details") {
            VStack(spacing: 0) {
                if let cost = log.editableCost.flatMap({ Formatters.currency.string(from: $0 as NSDecimalNumber) }) {
                    BrutalistDataRow(label: log.sharedCostVisit != nil ? L10n.editVisitTotal : L10n.formCost, value: cost, padding: Spacing.md)
                    ListDivider(leadingPadding: 0)
                }

                if let category = log.editableCostCategory {
                    BrutalistDataRow(label: L10n.formCategory, value: category.displayName, padding: Spacing.md)
                    ListDivider(leadingPadding: 0)
                }

                BrutalistDataRow(label: L10n.formMileage, value: Formatters.mileage(log.mileageAtService), padding: Spacing.md)
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        InstrumentSection(title: L10n.formNotes) {
            Text(notes.brutalistMarkdownAttributed)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
        }
    }
}

#Preview {
    @Previewable @State var log = ServiceLog(
        service: Service(name: "Oil Change", dueDate: nil),
        vehicle: Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        ),
        performedDate: Date.now,
        mileageAtService: 32000,
        cost: 45.99,
        costCategory: .maintenance,
        notes: "Synthetic 0W-20 oil change at local shop. Filter replaced."
    )

    NavigationStack {
        ServiceLogDetailView(log: log)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
    .environment(AppState())
    .preferredColorScheme(.dark)
}
