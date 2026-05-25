//
//  DocumentsView.swift
//  checkpoint
//
//  Full-screen sheet listing every Document linked to a single vehicle.
//
//  Documents are grouped by DocumentType.listOrder, support search across
//  filename / notes / extractedText / type, and offer multi-select
//  share + delete. Tapping a row presents DocumentDetailView; long-press
//  opens a context menu with the same actions plus a destination-aware
//  "Edit Notes" shortcut.
//

import SwiftUI
import SwiftData
import QuickLook
import os

private let documentsViewLogger = Logger(category: "Documents")

struct DocumentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let vehicle: Vehicle
    @Query private var allVehicles: [Vehicle]

    @State private var searchText: String = ""
    @State private var isSelectionMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []

    @State private var showAddSheet = false
    @State private var documentForDetail: Document?
    @State private var documentToDelete: Document?
    @State private var showBulkDeleteConfirmation = false
    @State private var shareItems: [URL] = []
    @State private var showShareSheet = false

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
        NavigationStack {
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
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .sheet(item: $documentForDetail) { doc in
                DocumentDetailView(document: doc)
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
                Button("Cancel", role: .cancel) {
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
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(L10n.documentsDeleteBulkConfirmMessage)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if isSelectionMode {
                    exitSelectionMode()
                } else {
                    appState.showDocuments = false
                    dismiss()
                }
            } label: {
                if isSelectionMode {
                    Text(L10n.documentsSelectionDoneAction)
                        .font(.brutalistBody)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .accessibilityLabel(isSelectionMode ? "Done" : "Close")
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
            }
        }
    }

    // MARK: - Selection Bottom Bar

    private var selectionToolbar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                shareSelected()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
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
                    Text("\(L10n.documentsDeleteAction) (\(selectedIDs.count))")
                }
                .font(.brutalistBody)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Theme.statusOverdue)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
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
            VStack(spacing: Spacing.lg) {
                searchField

                if filteredDocuments.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(groupedDocuments, id: \.type) { group in
                        section(for: group.type, docs: group.docs)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField(L10n.documentsSearchPlaceholder, text: $searchText)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private var filteredEmptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.textTertiary)

            Text("No Results")
                .font(.brutalistHeading)
                .foregroundStyle(Theme.textPrimary)

            Text("Try a different search term")
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(type.accentColor)

                Text("\(type.displayName.uppercased()) (\(docs.count))")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)
            }

            VStack(spacing: 0) {
                ForEach(Array(docs.enumerated()), id: \.element.id) { index, doc in
                    documentRow(doc)

                    if index < docs.count - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
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
                    Text(doc.fileName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(doc.documentType.displayName)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)

                    if let notes = doc.notes,
                       let firstLine = notes.split(whereSeparator: \.isNewline).first,
                       !firstLine.isEmpty {
                        Text(String(firstLine))
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelectionMode && isSelected ? .isSelected : [])
        .accessibilityValue(isSelectionMode ? (isSelected ? "Selected" : "Not selected") : "")
        .contextMenu {
            if !isSelectionMode {
                Button {
                    shareSingle(doc)
                } label: {
                    Label(L10n.documentsShareAction, systemImage: "square.and.arrow.up")
                }

                Button {
                    documentForDetail = doc
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
            documentForDetail = doc
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
        try? modelContext.save()
        Document.purgeOrphans(in: modelContext)
        documentToDelete = nil
        selectedIDs.remove(doc.id)
    }

    private func deleteSelected() {
        let targets = allDocuments.filter { selectedIDs.contains($0.id) }
        for doc in targets {
            modelContext.delete(doc)
        }
        try? modelContext.save()
        Document.purgeOrphans(in: modelContext)
        exitSelectionMode()
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

    return DocumentsView(vehicle: vehicle)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
