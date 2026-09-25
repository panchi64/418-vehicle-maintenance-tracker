//
//  DocumentDetailView.swift
//  checkpoint
//
//  Pushed detail for a single Document. QuickLook viewer on
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
    /// False where the linked log is the one already on screen (the log's own
    /// edit form), which would make the footer link circular.
    var showsServiceLogLink = true
    @Query private var allVehicles: [Vehicle]

    @State private var didOpenPreview = false
    @State private var notesDraft: String = ""
    @State private var previewURL: URL?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showVehiclePicker = false
    @State private var pendingVehicleSelection: Set<UUID> = []
    @State private var showRemoveLastVehicleConfirmation = false
    @State private var pendingRemovalSelection: Set<UUID>?
    @State private var isExtractedTextExpanded = false

    var body: some View {
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

                    if let text = document.extractedText,
                       !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        extractedTextSection(text: text)
                    }

                    linkedVehiclesSection

                    if showsServiceLogLink, let log = document.serviceLog {
                        serviceLogFooter(for: log)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle(L10n.documentsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                .accessibilityLabel(L10n.documentsMoreActions)
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
            Button(L10n.commonCancel, role: .cancel) { }
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
            Button(L10n.commonCancel, role: .cancel) {
                pendingRemovalSelection = nil
            }
        } message: {
            Text(L10n.documentsRemoveLastVehicleConfirmMessage)
        }
        .onAppear {
            notesDraft = document.notes ?? ""
            // Once per visit, not on every return to this screen: popping
            // back from the service log pushed above it re-fires onAppear.
            guard !didOpenPreview else { return }
            didOpenPreview = true
            openPreview()
        }
        // Back, or a push on top, both leave this screen with the draft
        // saved — there is no close button to hang the save on.
        .onDisappear {
            commitNotesIfChanged()
            cleanupTempFiles()
        }
    }

    // MARK: - Sections

    private var previewArea: some View {
        Button {
            openPreview()
        } label: {
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
                            .font(.largeTitle.weight(.light))
                            .foregroundStyle(document.documentType.accentColor)

                        Text(document.documentType.displayName.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.sm)
                }
            }
            // A preview image, not a text container — its fixed height is
            // the frame the thumbnail scales into.
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .brutalistBorder()
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2.weight(.semibold))
                    Text(L10n.documentsOpenBadge)
                        .font(.brutalistLabel)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .foregroundStyle(Theme.surfaceInstrument)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(Theme.accent)
                .padding(Spacing.sm)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.documentsOpenFullLabel)
        .accessibilityHint(L10n.documentsOpenFullHint)
    }

    private var typeSection: some View {
        DocumentTypeMenu(selection: $document.documentType)
    }

    private var notesSection: some View {
        RichNotesEditor(
            label: L10n.documentsNotesLabel,
            text: $notesDraft,
            placeholder: L10n.documentsNotesPlaceholder,
            minHeight: 100
        )
    }

    private func extractedTextSection(text: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExtractedTextExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "text.viewfinder")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)

                    Text(L10n.documentsExtractedTextLabel.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(isExtractedTextExpanded ? 180 : 0))
                }
                .padding(Spacing.md)
                .frame(minHeight: TouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.documentsExtractedTextLabel)
            .accessibilityValue(isExtractedTextExpanded ? L10n.disclosureExpanded : L10n.disclosureCollapsed)

            if isExtractedTextExpanded {
                ListDivider()

                Text(text)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(Spacing.md)
                    .transition(.opacity)
            }
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private var linkedVehiclesSection: some View {
        let linked = document.vehicles ?? []
        return InstrumentSection(title: L10n.documentsLinkedVehiclesLabel, trailing: {
            Button {
                pendingVehicleSelection = Set(linked.map { $0.id })
                showVehiclePicker = true
            } label: {
                Text(L10n.documentsLinkedVehiclesEdit.uppercased())
                    .font(.brutalistLabel)
                    .tracking(1)
                    .foregroundStyle(Theme.accent)
                    .minimumTouchTarget()
            }
        }) {
            VStack(spacing: 0) {
                if linked.isEmpty {
                    Text(L10n.documentsNoLinkedVehicles)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                } else {
                    ForEach(Array(linked.enumerated()), id: \.element.id) { index, vehicle in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "car.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textTertiary)
                                .accessibilityHidden(true)

                            Text(vehicle.displayName)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()
                        }
                        .padding(Spacing.md)

                        if index < linked.count - 1 {
                            ListDivider()
                        }
                    }
                }
            }
        }
    }

    private func serviceLogFooter(for log: ServiceLog) -> some View {
        Button {
            commitNotesIfChanged()
            appState.push(.serviceLog(log))
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func serviceLogSummary(for log: ServiceLog) -> String {
        let name = log.service?.name ?? L10n.documentsServiceFallback
        let date = Formatters.mediumDate.string(from: log.performedDate)
        return L10n.documentsServiceLogSummary(name, date)
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
            dismiss()
        }
    }
}

// MARK: - Sheet host

/// `DocumentDetailView` presented from inside a form sheet, where there is no
/// navigation stack to push onto. Everywhere else the detail is pushed.
struct DocumentDetailSheet: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DocumentDetailView(document: document, showsServiceLogLink: false)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { dismiss() }
                    }
                }
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

    return NavigationStack { DocumentDetailView(document: doc) }
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
