//
//  DocumentsView.swift
//  checkpoint
//
//  Pushed library of every Document linked to one vehicle (AppRoute).
//
//  A system List, like Services: grouped by DocumentType.listOrder,
//  searchable across filename / notes / extracted text / type. Every row
//  action has two doors (F14) — swipe and long-press — and delete is the same
//  everywhere: at once, with Undo (`DocumentDeleteAction`). Select mode
//  mirrors Services': Share and Delete in the bottom bar, Delete confirmed
//  first because it acts on several at once.
//

import SwiftUI
import SwiftData
import os

private let documentsViewLogger = Logger(category: "Documents")

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let vehicle: Vehicle
    @Query private var allVehicles: [Vehicle]

    @State private var searchText: String = ""
    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []

    @State private var showAddSheet = false
    @State private var showBulkDeleteConfirmation = false
    @State private var shareItems: [URL] = []
    @State private var showShareSheet = false

    private var rowLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 1
    }

    private var allDocuments: [Document] {
        vehicle.documents ?? []
    }

    private func groupedDocuments(_ documents: [Document]) -> [(type: DocumentType, docs: [Document])] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matches = query.isEmpty ? documents : documents.filter { doc in
            doc.fileName.localizedCaseInsensitiveContains(query)
                || (doc.notes?.localizedCaseInsensitiveContains(query) ?? false)
                || (doc.extractedText?.localizedCaseInsensitiveContains(query) ?? false)
                || doc.documentType.displayName.localizedCaseInsensitiveContains(query)
        }
        return DocumentType.listOrder.compactMap { type in
            let docs = matches
                .filter { $0.documentType == type }
                .sorted { $0.createdAt > $1.createdAt }
            return docs.isEmpty ? nil : (type: type, docs: docs)
        }
    }

    var body: some View {
        // Resolved once per body (Views/CLAUDE.md: derive once, pass down).
        let documents = allDocuments
        let groups = groupedDocuments(documents)

        ZStack {
            AtmosphericBackground()

            if documents.isEmpty {
                ContentUnavailableView {
                    Label(L10n.documentsEmptyTitle, systemImage: "doc.text")
                } description: {
                    Text(L10n.documentsEmptyMessage)
                } actions: {
                    Button(L10n.documentsEmptyAction) { showAddSheet = true }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.accent)
                }
            } else {
                list(groups)
                    .overlay {
                        if groups.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
            }
        }
        .navigationTitle(L10n.documentsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: L10n.documentsSearchPlaceholder)
        .toolbar { toolbarItems(hasDocuments: !documents.isEmpty) }
        .toolbar(isSelecting ? .hidden : .automatic, for: .tabBar)
        .onChange(of: documents.isEmpty) { _, isEmpty in
            if isEmpty { setSelecting(false) }
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
        // A multi-item delete is confirmed first, centered, as in Services'
        // Select mode; it still offers Undo afterwards.
        .alert(
            L10n.documentsDeleteBulkConfirmTitle(selectedIDs.count),
            isPresented: $showBulkDeleteConfirmation
        ) {
            Button(L10n.documentsDeleteAction, role: .destructive) {
                let targets = selectedDocuments
                setSelecting(false)
                DocumentDeleteAction.perform(targets, in: modelContext)
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.documentsDeleteBulkConfirmMessage)
        }
    }

    // MARK: - List

    private func list(_ groups: [(type: DocumentType, docs: [Document])]) -> some View {
        List(selection: $selectedIDs) {
            ForEach(groups, id: \.type) { group in
                Section {
                    ForEach(group.docs) { doc in
                        row(doc)
                    }
                } header: {
                    InstrumentSectionHeader(title: group.type.displayName) {
                        Text(verbatim: "\(group.docs.count)")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .servicesListHeader()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, Binding(
            get: { isSelecting ? .active : .inactive },
            set: { setSelecting($0.isEditing) }
        ))
        .animation(.default, value: isSelecting)
    }

    private func row(_ doc: Document) -> some View {
        NavigationLink(value: AppRoute.document(doc)) {
            DocumentRowContent(document: doc, lineLimit: rowLineLimit)
        }
        .tag(doc.id)
        .servicesListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            deleteButton(doc)
            shareButton(doc)
        }
        .contextMenu {
            shareButton(doc)
            Button {
                appState.push(.document(doc))
            } label: {
                Label(L10n.documentsEditNotes, systemImage: "pencil")
            }
            deleteButton(doc)
        }
    }

    private func deleteButton(_ doc: Document) -> some View {
        Button(role: .destructive) {
            selectedIDs.remove(doc.id)
            DocumentDeleteAction.perform([doc], in: modelContext)
        } label: {
            Label(L10n.documentsDeleteAction, systemImage: "trash")
        }
    }

    private func shareButton(_ doc: Document) -> some View {
        Button {
            share([doc])
        } label: {
            Label(L10n.documentsShareAction, systemImage: "square.and.arrow.up")
        }
        .tint(Theme.accent)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarItems(hasDocuments: Bool) -> some ToolbarContent {
        if hasDocuments {
            ToolbarItem(placement: .primaryAction) {
                Button(isSelecting ? L10n.documentsSelectionDoneAction : L10n.documentsSelectAction) {
                    setSelecting(!isSelecting)
                }
            }
        }

        if !isSelecting {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.documentsAdd)
            }
        }

        if isSelecting {
            ToolbarItem(placement: .bottomBar) {
                Button(L10n.documentsShareCount(selectedIDs.count)) {
                    share(selectedDocuments)
                }
                .disabled(selectedIDs.isEmpty)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button(L10n.documentsDeleteCount(selectedIDs.count), role: .destructive) {
                    showBulkDeleteConfirmation = true
                }
                .disabled(selectedIDs.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private var selectedDocuments: [Document] {
        allDocuments.filter { selectedIDs.contains($0.id) }
    }

    private func setSelecting(_ selecting: Bool) {
        isSelecting = selecting
        selectedIDs.removeAll()
    }

    private func share(_ documents: [Document]) {
        let urls = documents.compactMap { writeTempFile(for: $0) }
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

// MARK: - Row

/// Thumbnail, filename (the row's primary), type, first line of notes, and a
/// shared-with count when the file is linked to more than one vehicle.
private struct DocumentRowContent: View {
    let document: Document
    let lineLimit: Int

    var body: some View {
        let linkedCount = document.vehicles?.count ?? 0

        HStack(spacing: Spacing.md) {
            AttachmentThumbnail(attachment: document)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(lineLimit)
                    .truncationMode(.middle)

                Text(document.documentType.displayName)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(lineLimit)

                if let notes = document.notes,
                   let firstLine = notes.split(whereSeparator: \.isNewline).first,
                   !firstLine.isEmpty {
                    Text(String(firstLine))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(lineLimit)
                }

                if linkedCount > 1 {
                    Text(L10n.documentsLinkedCount(linkedCount))
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)

    return NavigationStack { DocumentsView(vehicle: vehicle) }
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
