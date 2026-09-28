//
//  VehicleNotesView.swift
//  checkpoint
//
//  A vehicle's notes (AppRoute.notes) — a Readout. Reached from the Notes
//  row in Home's specs panel. Resolved in tools/sketchpad
//  (screens/VehicleNotes.tsx).
//
//  Pinned notes first under "Pinned", then the rest newest-changed first
//  under "Notes": the reference notes (paint code, torque specs) stay where
//  the hand expects them. Each row's primary is the note's title; its first
//  line of text and a meta line ("Sep 12 · 2 attachments") step down. A
//  system List like Documents: searchable, the add button in the toolbar,
//  every row action two ways (F14) — swipe and long-press — for Pin and
//  Delete. Delete is confirmed: a note has no Undo.
//
//  Tapping a note opens it in the note sheet (a task: it is filled in and
//  saved). Its attachments stay in the Documents library when it goes.
//

import SwiftUI
import SwiftData

struct VehicleNotesView: View {
    let vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var searchText = ""
    @State private var pendingDeletion: VehicleNote?

    var body: some View {
        let notes = vehicle.sortedNotes
        let matches = notes.filter { $0.matches(searchText) }
        let pinned = matches.filter(\.isPinned)
        let others = matches.filter { !$0.isPinned }

        ZStack {
            AtmosphericBackground()

            if notes.isEmpty {
                ContentUnavailableView {
                    Label(L10n.notesEmptyTitle, systemImage: "note.text")
                } description: {
                    Text(L10n.notesEmptyMessage)
                } actions: {
                    Button(L10n.notesAdd, action: addNote)
                        .buttonStyle(.glassProminent)
                        .tint(Theme.accent)
                }
            } else {
                List {
                    if !pinned.isEmpty {
                        section(L10n.notesPinned, notes: pinned)
                    }
                    if !others.isEmpty {
                        section(L10n.notesAll, notes: others)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .readableListMargins()
                .overlay {
                    if matches.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
        .navigationTitle(L10n.notesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: L10n.notesSearchPlaceholder)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.notesAdd, systemImage: "plus", action: addNote)
            }
        }
        .alert(L10n.notesDeleteConfirmTitle, isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button(L10n.commonDelete, role: .destructive) {
                if let note = pendingDeletion { delete(note) }
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.notesDeleteConfirmMessage)
        }
        .trackScreen(.vehicleNotes)
    }

    private func section(_ title: String, notes: [VehicleNote]) -> some View {
        Section {
            ForEach(notes, id: \.id) { note in
                row(note)
            }
        } header: {
            InstrumentSectionHeader(title: title) {
                Text(verbatim: "\(notes.count)")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }
            .servicesListHeader()
        }
    }

    private func row(_ note: VehicleNote) -> some View {
        Button {
            open(note)
        } label: {
            VehicleNoteRowContent(note: note, lineLimit: dynamicTypeSize.isAccessibilitySize ? 3 : 1)
        }
        .buttonStyle(.plain)
        .servicesListRow()
        .onScreenEntity(VehicleNoteEntity.self, id: note.id)
        .swipeActions(edge: .trailing) {
            deleteButton(note)
            pinButton(note)
        }
        .contextMenu {
            pinButton(note)
            deleteButton(note)
        }
    }

    private func pinButton(_ note: VehicleNote) -> some View {
        Button {
            VehicleNoteService.setPinned(!note.isPinned, on: note)
            try? modelContext.save()
            SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        } label: {
            Label(
                note.isPinned ? L10n.notesUnpin : L10n.notesPin,
                systemImage: note.isPinned ? "pin.slash" : "pin"
            )
        }
        .tint(Theme.accent)
    }

    private func deleteButton(_ note: VehicleNote) -> some View {
        Button(role: .destructive) {
            pendingDeletion = note
        } label: {
            Label(L10n.commonDelete, systemImage: "trash")
        }
    }

    private func addNote() {
        appState.present(.vehicleNote(VehicleNoteEditorRequest(target: .new(vehicle))))
    }

    private func open(_ note: VehicleNote) {
        appState.present(.vehicleNote(VehicleNoteEditorRequest(target: .edit(note))))
    }

    private func delete(_ note: VehicleNote) {
        HapticService.shared.warning()
        VehicleNoteService.delete(note, in: modelContext)
        try? modelContext.save()
        SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        pendingDeletion = nil
    }
}

/// One note in the list: title, first line, then date and attachments.
struct VehicleNoteRowContent: View {
    let note: VehicleNote
    var lineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityLabel(L10n.notesPinnedA11y)
                }
                Text(note.displayTitle.isEmpty ? L10n.notesUntitled : note.displayTitle)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(lineLimit)
            }

            if let preview = note.previewLine {
                Text(preview)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(lineLimit)
            }

            Text(metaLine)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var metaLine: String {
        let date = note.modifiedAt.formatted(date: .abbreviated, time: .omitted)
        let count = note.attachments?.count ?? 0
        return count == 0 ? date : L10n.notesMetaWithAttachments(date, L10n.attachmentCount(count))
    }
}
