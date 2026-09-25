//
//  DocumentsView.swift
//  checkpoint
//
//  Pushed screen listing every Document linked to a single vehicle.
//
//  Documents are grouped by DocumentType.listOrder, support search across
//  filename / notes / extractedText / type, and offer multi-select
//  share + delete. Tapping a row pushes DocumentDetailView; long-press
//  opens a context menu with the same actions plus a destination-aware
//  "Edit Notes" shortcut.
//

import SwiftUI
import SwiftData
import QuickLook
import os

private let documentsViewLogger = Logger(category: "Documents")

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let vehicle: Vehicle
    @Query private var allVehicles: [Vehicle]

    @State private var searchText: String = ""
    @State private var isSelectionMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []

    @State private var showAddSheet = false
    @State private var documentToDelete: Document?
    @State private var showBulkDeleteConfirmation = false
    @State private var shareItems: [URL] = []
    @State private var showShareSheet = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var rowLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 1
    }

    private var allDocuments: [Document] {
        vehicle.documents ?? []
    }

    private var filteredDocuments: [Document] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return allDocuments }

        return allDocuments.filter { doc in
            if doc.fileName.localizedCaseInsensitiveContains(query) { return true }
            if let notes = doc.notes, notes.localizedCaseInsensitiveContains(query) { return true }
            if let text = doc.extractedText, text.localizedCaseInsensitiveContains(query) { return true }
            if doc.documentType.displayName.localizedCaseInsensitiveContains(query) { return true }
            return false
        }
    }

    private var groupedDocuments: [(type: DocumentType, docs: [Document])] {
        let documents = filteredDocuments
        return DocumentType.listOrder.compactMap { type in
            let matches = documents
                .filter { $0.documentType == type }
                .sorted { $0.createdAt > $1.createdAt }
            return matches.isEmpty ? nil : (type: type, docs: matches)
        }
    }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            if allDocuments.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: L10n.documentsEmptyTitle,
                    message: L10n.documentsEmptyMessage,
                    action: { showAddSheet = true },
                    actionLabel: L10n.documentsEmptyAction
                )
            } else {
                contentScroll
            }
        }
        .navigationTitle(L10n.documentsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isSelectionMode)
        .searchable(text: $searchText, prompt: L10n.documentsSearchPlaceholder)
        .toolbar { toolbarItems }
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode {
                selectionToolbar
            }
        }
        .sheet(isPresented: $showAddSheet) {
            DocumentPickerSheet(
                currentVehicle: vehicle,
                availableVehicles: allVehicles,
                serviceLog: nil,
                onSave: { _ in
                    // No-op: SwiftData relationship update propagates the
                    // new Document into vehicle.documents automatically.
                }
            )
        }
        .sheet(isPresented: $showShareSheet, onDismiss: cleanupShareItems) {
            ShareSheet(items: shareItems)
        }
        .confirmationDialog(
            L10n.documentsDeleteConfirmTitle,
            isPresented: Binding(
                get: { documentToDelete != nil },
                set: { newValue in
                    if !newValue { documentToDelete = nil }
                }
            ),
            titleVisibility: .visible,
            presenting: documentToDelete
        ) { doc in
            Button(L10n.documentsDeleteAction, role: .destructive) {
                deleteDocument(doc)
            }
            Button(L10n.commonCancel, role: .cancel) {
                documentToDelete = nil
            }
        } message: { _ in
            Text(L10n.documentsDeleteConfirmMessage)
        }
        .alert(
            L10n.documentsDeleteBulkConfirmTitle(selectedIDs.count),
            isPresented: $showBulkDeleteConfirmation
        ) {
            Button(L10n.documentsDeleteAction, role: .destructive) {
                deleteSelected()
            }
            Button(L10n.commonCancel, role: .cancel) { }
        } message: {
            Text(L10n.documentsDeleteBulkConfirmMessage)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // Pushed, so the back button leaves. Selection mode swaps it for Done,
        // which only exits selection.
        if isSelectionMode {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    exitSelectionMode()
                } label: {
                    Text(L10n.documentsSelectionDoneAction)
                        .font(.brutalistBody)
                }
                .accessibilityLabel(L10n.documentsSelectionDoneAction)
            }
        }

        if !isSelectionMode && !allDocuments.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.documentsSelectAction) {
                    enterSelectionMode()
                }
                .toolbarButtonStyle()
            }
        }

        if !isSelectionMode {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarButtonStyle()
                .accessibilityLabel(L10n.documentsAdd)
            }
        }

        if isSelectionMode {
            ToolbarItem(placement: .primaryAction) {
                Text("\(selectedIDs.count)")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.2))
                    .accessibilityLabel(L10n.documentsSelectedCount(selectedIDs.count))
            }
        }
    }

    // MARK: - Selection Bottom Bar

    private var selectionToolbar: some View {
        // Share and Delete side by side at standard sizes; stacked at
        // accessibility sizes so each keeps its count legible.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.sm))

        return layout {
            Button {
                shareSelected()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityHidden(true)
                    Text(L10n.documentsShareCount(selectedIDs.count))
                }
            }
            .buttonStyle(.secondary)
            .disabled(selectedIDs.isEmpty)

            Button {
                showBulkDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .accessibilityHidden(true)
                    Text(L10n.documentsDeleteCount(selectedIDs.count))
                        .multilineTextAlignment(.center)
                }
                .font(.brutalistBody)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Theme.statusOverdue)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.buttonHeight)
                .background(Theme.statusOverdue.opacity(0.1))
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedIDs.isEmpty)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.sm)
        .background(Theme.surfaceInstrument)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
        }
    }

    // MARK: - Content

    private var contentScroll: some View {
        ScrollView {
            let groups = groupedDocuments

            VStack(spacing: Spacing.lg) {
                if groups.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(groups, id: \.type) { group in
                        section(for: group.type, docs: group.docs)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        // Search filters as you type, so the keyboard is in the way of the
        // results the moment you stop typing. Dragging the list dismisses it,
        // which is what a reader reaches for first.
        .scrollDismissesKeyboard(.interactively)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)

            Text(L10n.documentsNoResultsTitle)
                .font(.brutalistHeading)
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.documentsNoResultsMessage)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
    }

    // MARK: - Section

    private func section(for type: DocumentType, docs: [Document]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: type.icon)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(type.accentColor)
                    .accessibilityHidden(true)

                Text(L10n.documentsSectionTitle(type.displayName, docs.count))
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .accessibilityAddTraits(.isHeader)

                ListDivider()
            }

            VStack(spacing: 0) {
                ForEach(Array(docs.enumerated()), id: \.element.id) { index, doc in
                    documentRow(doc)

                    if index < docs.count - 1 {
                        ListDivider()
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    // MARK: - Row

    private func documentRow(_ doc: Document) -> some View {
        let isSelected = selectedIDs.contains(doc.id)
        let linkedCount = doc.vehicles?.count ?? 0

        return Button {
            handleRowTap(doc)
        } label: {
            HStack(spacing: Spacing.md) {
                AttachmentThumbnail(attachment: doc)

                VStack(alignment: .leading, spacing: 4) {
                    // One line at standard sizes; at accessibility sizes a
                    // single line holds a handful of characters, so allow more.
                    Text(doc.fileName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(rowLineLimit)
                        .truncationMode(.middle)

                    Text(doc.documentType.displayName)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(rowLineLimit)

                    if let notes = doc.notes,
                       let firstLine = notes.split(whereSeparator: \.isNewline).first,
                       !firstLine.isEmpty {
                        Text(String(firstLine))
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(rowLineLimit)
                    }

                    if linkedCount > 1 {
                        Text(L10n.documentsLinkedCount(linkedCount))
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.15))
                    }
                }

                Spacer(minLength: Spacing.sm)

                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The trait speaks "Selected"; a value saying it again was doubled.
        .accessibilityAddTraits(isSelectionMode && isSelected ? .isSelected : [])
        .contextMenu {
            if !isSelectionMode {
                Button {
                    shareSingle(doc)
                } label: {
                    Label(L10n.documentsShareAction, systemImage: "square.and.arrow.up")
                }

                Button {
                    appState.push(.document(doc))
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    documentToDelete = doc
                } label: {
                    Label(L10n.documentsDeleteAction, systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Actions

    private func handleRowTap(_ doc: Document) {
        if isSelectionMode {
            if selectedIDs.contains(doc.id) {
                selectedIDs.remove(doc.id)
            } else {
                selectedIDs.insert(doc.id)
            }
            HapticService.shared.selectionChanged()
        } else {
            appState.push(.document(doc))
        }
    }

    private func enterSelectionMode() {
        isSelectionMode = true
        selectedIDs.removeAll()
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedIDs.removeAll()
    }

    private func deleteDocument(_ doc: Document) {
        modelContext.delete(doc)
        saveAfterDelete()
        Document.purgeOrphans(in: modelContext)
        documentToDelete = nil
        selectedIDs.remove(doc.id)
    }

    private func deleteSelected() {
        let targets = allDocuments.filter { selectedIDs.contains($0.id) }
        for doc in targets {
            modelContext.delete(doc)
        }
        saveAfterDelete()
        Document.purgeOrphans(in: modelContext)
        exitSelectionMode()
    }

    /// Persist a user-initiated delete. On failure, log it and surface a toast
    /// rather than silently swallowing the error — the row would otherwise
    /// reappear on the next fetch with no explanation.
    private func saveAfterDelete() {
        do {
            try modelContext.save()
        } catch {
            documentsViewLogger.error("Document delete save failed: \(error.localizedDescription)")
            ToastService.shared.show(
                L10n.documentsDeleteError,
                icon: "exclamationmark.triangle",
                style: .error
            )
        }
    }

    private func shareSingle(_ doc: Document) {
        guard let url = writeTempFile(for: doc) else { return }
        shareItems = [url]
        showShareSheet = true
    }

    private func shareSelected() {
        let targets = allDocuments.filter { selectedIDs.contains($0.id) }
        let urls = targets.compactMap { writeTempFile(for: $0) }
        guard !urls.isEmpty else { return }
        shareItems = urls
        showShareSheet = true
    }

    private func writeTempFile(for doc: Document) -> URL? {
        guard let data = doc.data else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(doc.id)_\(doc.fileName)")
        do {
            try data.write(to: url)
            return url
        } catch {
            documentsViewLogger.error("Failed writing temp file for share: \(error.localizedDescription)")
            return nil
        }
    }

    private func cleanupShareItems() {
        // Delete the temp files we wrote for the iOS share sheet; otherwise
        // tmp/ accumulates document blobs across sessions.
        for url in shareItems {
            try? FileManager.default.removeItem(at: url)
        }
        shareItems = []
    }
}

#Preview {
    let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)

    return NavigationStack { DocumentsView(vehicle: vehicle) }
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
