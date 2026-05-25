//
//  DocumentDetailView.swift
//  checkpoint
//
//  Full-screen sheet detail for a single Document. QuickLook viewer on
//  top, then filename, document type, notes, linked vehicles, and (if the
//  document came from a service log) a footer link back to that log.
//

import SwiftUI
import SwiftData
import QuickLook
import os

private let documentDetailLogger = Logger(category: "Documents")

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Bindable var document: Document
    @Query private var allVehicles: [Vehicle]

    @State private var notesDraft: String = ""
    @State private var previewURL: URL?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showVehiclePicker = false
    @State private var pendingVehicleSelection: Set<UUID> = []
    @State private var showRemoveLastVehicleConfirmation = false
    @State private var pendingRemovalSelection: Set<UUID>?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        previewArea

                        Text(document.fileName)
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        typeSection

                        notesSection

                        linkedVehiclesSection

                        if let log = document.serviceLog {
                            serviceLogFooter(for: log)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(L10n.documentsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        commitNotesIfChanged()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            shareDocument()
                        } label: {
                            Label(L10n.documentsShareAction, systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L10n.documentsDeleteAction, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .toolbarButtonStyle()
                }
            }
            .quickLookPreview($previewURL)
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showVehiclePicker, onDismiss: applyPendingVehicleSelection) {
                VehicleMultiPicker(
                    allVehicles: allVehicles,
                    selection: $pendingVehicleSelection,
                    lockedVehicleIDs: serviceLogVehicleLock
                )
            }
            .confirmationDialog(
                L10n.documentsDeleteConfirmTitle,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.documentsDeleteAction, role: .destructive) { deleteDocument() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(L10n.documentsDeleteConfirmMessage)
            }
            .alert(
                L10n.documentsRemoveLastVehicleConfirmTitle,
                isPresented: $showRemoveLastVehicleConfirmation
            ) {
                Button(L10n.documentsDeleteAction, role: .destructive) {
                    if let selection = pendingRemovalSelection {
                        commitVehicleSelection(selection)
                    }
                    pendingRemovalSelection = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingRemovalSelection = nil
                }
            } message: {
                Text(L10n.documentsRemoveLastVehicleConfirmMessage)
            }
            .onAppear {
                notesDraft = document.notes ?? ""
                openPreview()
            }
            .onDisappear {
                commitNotesIfChanged()
                cleanupTempFiles()
            }
        }
    }

    // MARK: - Sections

    private var previewArea: some View {
        ZStack {
            Rectangle()
                .fill(Theme.surfaceInstrument)

            if let image = document.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(Spacing.sm)
            } else {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: document.documentType.icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(document.documentType.accentColor)

                    Text(document.documentType.displayName.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)
                }
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .brutalistBorder()
        .overlay(alignment: .bottomTrailing) {
            Button {
                openPreview()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("OPEN")
                        .font(.brutalistLabel)
                        .tracking(1)
                }
                .foregroundStyle(Theme.surfaceInstrument)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(Theme.accent)
            }
            .buttonStyle(.plain)
            .padding(Spacing.sm)
            .accessibilityLabel("Open full document")
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.documentsTypeLabel.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Menu {
                ForEach(DocumentType.listOrder) { type in
                    Button {
                        document.documentType = type
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: document.documentType.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(document.documentType.accentColor)

                    Text(document.documentType.displayName.uppercased())
                        .font(.brutalistBody)
                        .tracking(1)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }
        }
    }

    private var notesSection: some View {
        RichNotesEditor(
            label: L10n.documentsNotesLabel,
            text: $notesDraft,
            placeholder: L10n.documentsNotesPlaceholder,
            minHeight: 100
        )
    }

    private var linkedVehiclesSection: some View {
        let linked = document.vehicles ?? []
        return InstrumentSection(title: L10n.documentsLinkedVehiclesLabel, trailing: {
            Button(L10n.documentsLinkedVehiclesEdit.uppercased()) {
                pendingVehicleSelection = Set(linked.map { $0.id })
                showVehiclePicker = true
            }
            .font(.brutalistLabel)
            .tracking(1)
            .foregroundStyle(Theme.accent)
        }) {
            VStack(spacing: 0) {
                if linked.isEmpty {
                    Text("No linked vehicles")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                } else {
                    ForEach(Array(linked.enumerated()), id: \.element.id) { index, vehicle in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)

                            Text(vehicle.displayName)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()
                        }
                        .padding(Spacing.md)

                        if index < linked.count - 1 {
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func serviceLogFooter(for log: ServiceLog) -> some View {
        Button {
            commitNotesIfChanged()
            // Dismiss any documents-library sheet that may be covering
            // ContentView so the service-log sheet has somewhere to present.
            appState.showDocuments = false
            appState.selectedDocument = nil
            appState.selectedServiceLog = log
            dismiss()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.documentsFromServiceLog.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    Text(serviceLogSummary(for: log))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
        .buttonStyle(.plain)
    }

    private func serviceLogSummary(for log: ServiceLog) -> String {
        let name = log.service?.name ?? "Service"
        let date = Formatters.mediumDate.string(from: log.performedDate)
        return "\(name) \u{2022} \(date)"
    }

    // MARK: - Preview

    private func openPreview() {
        // Avoid overwriting a temp file QuickLook may still be reading. The
        // QuickLook modifier resets `previewURL` to nil when the user dismisses
        // the preview, so this guard only blocks concurrent re-opens.
        guard previewURL == nil else { return }
        guard let data = document.data else { return }
        let ext = document.isPDF ? "pdf" : "jpg"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(document.id).\(ext)")

        if FileManager.default.fileExists(atPath: tempURL.path) {
            previewURL = tempURL
            return
        }

        // Move the write off the main thread — externalStorage assets can be
        // tens of MB and synchronous I/O risks the iOS watchdog.
        Task.detached {
            do {
                try data.write(to: tempURL)
                await MainActor.run { previewURL = tempURL }
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    documentDetailLogger.error("Failed writing preview file: \(message)")
                }
            }
        }
    }

    private func cleanupTempFiles() {
        if let url = previewURL {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = shareURL {
            try? FileManager.default.removeItem(at: url)
        }
        previewURL = nil
        shareURL = nil
    }

    // MARK: - Notes

    private func commitNotesIfChanged() {
        let trimmed = notesDraft.isEmpty ? nil : notesDraft
        if document.notes != trimmed {
            document.notes = trimmed
        }
    }

    // MARK: - Sharing

    private func shareDocument() {
        guard let data = document.data else { return }
        let ext = document.isPDF ? "pdf" : "jpg"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("share_\(document.id).\(ext)")
        do {
            try data.write(to: url)
            shareURL = url
            showShareSheet = true
        } catch {
            documentDetailLogger.error("Failed writing share file: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    private func deleteDocument() {
        HapticService.shared.warning()
        modelContext.delete(document)
        try? modelContext.save()
        Document.purgeOrphans(in: modelContext)
        appState.selectedDocument = nil
        dismiss()
    }

    // MARK: - Vehicle Linking

    /// A service-log document is conceptually "owned" by its log's vehicle —
    /// the picker must keep that vehicle linked so the document never falls
    /// out of every vehicle's Documents library.
    private var serviceLogVehicleLock: Set<UUID> {
        guard let id = document.serviceLog?.vehicle?.id else { return [] }
        return [id]
    }

    private func applyPendingVehicleSelection() {
        var nextSelection = pendingVehicleSelection
        // Re-add the service-log's vehicle if the user managed to remove it
        // (shouldn't happen given the picker lock, but enforce here too).
        if let logVehicleID = document.serviceLog?.vehicle?.id {
            nextSelection.insert(logVehicleID)
        }

        let originalIDs = Set((document.vehicles ?? []).map { $0.id })
        guard nextSelection != originalIDs else { return }

        // Empty selection only reachable when there's no service log; confirm
        // before orphan-deleting the document.
        if nextSelection.isEmpty && document.serviceLog == nil {
            pendingRemovalSelection = nextSelection
            showRemoveLastVehicleConfirmation = true
            return
        }

        commitVehicleSelection(nextSelection)
    }

    private func commitVehicleSelection(_ selection: Set<UUID>) {
        let nextVehicles = allVehicles.filter { selection.contains($0.id) }
        document.vehicles = nextVehicles
        try? modelContext.save()

        if nextVehicles.isEmpty && document.serviceLog == nil {
            Document.purgeOrphans(in: modelContext)
            appState.selectedDocument = nil
            dismiss()
        }
    }
}

#Preview {
    let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
    let doc = Document(
        serviceLog: nil,
        data: Data(),
        fileName: "registration_2024.pdf",
        mimeType: "application/pdf",
        documentType: .registration,
        notes: "Renewed in March",
        vehicles: [vehicle]
    )

    return DocumentDetailView(document: doc)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
