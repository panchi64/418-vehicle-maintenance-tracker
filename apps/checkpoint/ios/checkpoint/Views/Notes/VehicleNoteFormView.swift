//
//  VehicleNoteFormView.swift
//  checkpoint
//
//  Add or edit one vehicle note — a Decision surface. Resolved in
//  tools/sketchpad (screens/VehicleNotes.tsx, note sheet).
//
//  DEFAULT PATH: Title → Text → Attachments → Pinned. Attachments are on the
//  default path, not under Details: photographing the shop's quote or a
//  scratch *is* the note for a lot of them. Pinned is a toggle, off by
//  default.
//
//  TAP BUDGET — a pinned note with a photo, from the Notes list: + → title
//  (type) → Photo → pick → Pinned → Save: 5 taps.
//
//  A note needs a title or some text (or a file): Save stays dim and tappable
//  (F2) and says so at the title. Dismiss-protected (F3). Delete Note is last
//  in the scroll, confirmed, edit only. Removing an attachment detaches it —
//  the file stays in the vehicle's Documents library.
//

import SwiftUI
import SwiftData

struct VehicleNoteFormView: View {
    let request: VehicleNoteEditorRequest

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var fields: VehicleNoteFields
    @State private var baseline: VehicleNoteFields
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []
    @State private var detached: Set<UUID> = []
    @State private var showBlocker = false
    @State private var showDeleteConfirmation = false
    @State private var attachmentForDetail: Document?

    private var vehicle: Vehicle? {
        switch request.target {
        case .new(let vehicle): vehicle
        case .edit(let note): note.vehicle
        }
    }

    private var editing: VehicleNote? {
        if case .edit(let note) = request.target { return note }
        return nil
    }

    init(request: VehicleNoteEditorRequest) {
        self.request = request
        let initial: VehicleNoteFields
        switch request.target {
        case .new: initial = VehicleNoteFields()
        case .edit(let note): initial = VehicleNoteFields(note: note)
        }
        _fields = State(initialValue: initial)
        _baseline = State(initialValue: initial)
    }

    private var existingAttachments: [Document] {
        (editing?.attachments ?? [])
            .filter { !detached.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var canSave: Bool {
        fields.hasContent || !pendingAttachments.isEmpty || !existingAttachments.isEmpty
    }

    private var isDirty: Bool {
        fields != baseline || !pendingAttachments.isEmpty || !detached.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            textSection.id("text")
                            attachmentsSection
                            pinSection
                            if editing != nil {
                                deleteButton
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                        .readableContentWidth()
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: editing == nil ? L10n.noteFormTitleNew : L10n.noteFormTitleEdit,
                    subtitle: vehicle?.displayName,
                    canSave: canSave,
                    isDirty: isDirty,
                    onSave: save,
                    onBlocked: {
                        showBlocker = true
                        withAnimation { proxy.scrollTo("text", anchor: .center) }
                    }
                )
                .trackScreen(.vehicleNoteForm)
                .sheet(item: $attachmentForDetail) { document in
                    NavigationStack {
                        DocumentDetailView(document: document)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var textSection: some View {
        FormSection(title: L10n.noteFormNote) {
            InstrumentTextField(
                label: L10n.noteFormTitleField,
                text: $fields.title,
                placeholder: L10n.noteFormTitlePlaceholder,
                autocapitalization: .sentences
            )

            if showBlocker, !canSave {
                FormAdvisory.blocking(L10n.noteFormNeedsText)
            }

            InstrumentTextEditor(
                label: L10n.noteFormText,
                text: $fields.body,
                placeholder: L10n.noteFormTextPlaceholder,
                minHeight: 140
            )
        }
    }

    private var attachmentsSection: some View {
        FormSection(title: L10n.formAttachments, trailing: L10n.formOptionalTag) {
            if !existingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(existingAttachments, id: \.id) { document in
                            Button {
                                attachmentForDetail = document
                            } label: {
                                AttachmentThumbnail(attachment: document)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(document.fileName)
                            // Two doors (F14): this button and the long-press menu.
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    detached.insert(document.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Theme.textPrimary, Theme.backgroundPrimary)
                                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum, alignment: .topTrailing)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L10n.noteFormRemoveAttachment)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    detached.insert(document.id)
                                } label: {
                                    Label(L10n.noteFormRemoveAttachment, systemImage: "minus.circle")
                                }
                            }
                        }
                    }
                }
                Text(L10n.noteFormAttachmentsHint)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }
            AttachmentPicker(attachments: $pendingAttachments)
        }
    }

    private var pinSection: some View {
        LabeledInstrumentToggle(
            label: L10n.noteFormPinned,
            accessibilityLabel: L10n.noteFormPinnedA11y,
            isOn: $fields.isPinned
        )
    }

    /// Destructive, so last in the scroll and never beside Save (F1).
    private var deleteButton: some View {
        DestructiveFormButton(title: L10n.noteFormDelete) {
            showDeleteConfirmation = true
        }
        .alert(L10n.notesDeleteConfirmTitle, isPresented: $showDeleteConfirmation) {
            Button(L10n.commonDelete, role: .destructive, action: deleteNote)
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.notesDeleteConfirmMessage)
        }
    }

    // MARK: - Actions

    private func save() {
        guard let vehicle else { return dismiss() }
        HapticService.shared.success()
        var fields = self.fields
        // Files alone: name the note after the first one, so the list has
        // something to show.
        if !fields.hasContent, let first = pendingAttachments.first {
            fields.title = first.fileName
        }
        let files = pendingAttachments.map { NoteAttachmentFile($0) }
        if let editing {
            for document in (editing.attachments ?? []) where detached.contains(document.id) {
                VehicleNoteService.detach(document, from: editing)
            }
            VehicleNoteService.update(editing, with: fields, adding: files, in: modelContext)
        } else {
            VehicleNoteService.create(fields, attachments: files, on: vehicle, in: modelContext)
            IntentDonations.addedNote(to: vehicle)
        }
        try? modelContext.save()
        SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        dismiss()
    }

    private func deleteNote() {
        guard let editing else { return }
        HapticService.shared.warning()
        VehicleNoteService.delete(editing, in: modelContext)
        try? modelContext.save()
        SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        dismiss()
    }
}
