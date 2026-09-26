//
//  VehicleNoteService.swift
//  checkpoint
//
//  The one write path for vehicle notes: the note sheet, Siri, and the iOS 27
//  Notes schema all go through here, so each save stamps `modifiedAt` and
//  mirrors the legacy note into `Vehicle.notes` for older app versions
//  (`VehicleNoteMigration`).
//
//  Attachments are Documents: linked to the note and to its vehicle, so they
//  show in the vehicle's library too and deleting the note leaves them there.
//  Deleting a note is in-app only (no voice or schema delete).
//

import Foundation
import SwiftData

/// Every value a user can write to a note, as plain values.
nonisolated struct VehicleNoteFields: Equatable, Sendable {
    var title = ""
    var body = ""
    var isPinned = false

    init(title: String = "", body: String = "", isPinned: Bool = false) {
        self.title = title
        self.body = body
        self.isPinned = isPinned
    }

    @MainActor
    init(note: VehicleNote) {
        self.init(title: note.title, body: note.body, isPinned: note.isPinned)
    }

    /// A note needs a title or some text; attachments alone get a title from
    /// the caller.
    var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// A file to attach, as the pickers and Siri hand it over.
struct NoteAttachmentFile {
    let data: Data
    let fileName: String
    let mimeType: String
    var extractedText: String?

    init(data: Data, fileName: String, mimeType: String, extractedText: String? = nil) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.extractedText = extractedText
    }

    init(_ picked: AttachmentPicker.AttachmentData) {
        self.init(
            data: picked.data,
            fileName: picked.fileName,
            mimeType: picked.mimeType,
            extractedText: picked.extractedText
        )
    }
}

@MainActor
enum VehicleNoteService {

    @discardableResult
    static func create(
        _ fields: VehicleNoteFields,
        attachments: [NoteAttachmentFile] = [],
        on vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now
    ) -> VehicleNote {
        let note = VehicleNote(vehicle: vehicle, title: "", createdAt: now)
        context.insert(note)
        apply(fields, to: note)
        attach(attachments, to: note, in: context)
        note.modifiedAt = now
        VehicleNoteMigration.mirror(note)
        return note
    }

    static func update(
        _ note: VehicleNote,
        with fields: VehicleNoteFields,
        adding attachments: [NoteAttachmentFile] = [],
        in context: ModelContext,
        now: Date = .now
    ) {
        apply(fields, to: note)
        attach(attachments, to: note, in: context)
        note.modifiedAt = now
        VehicleNoteMigration.mirror(note)
    }

    /// Attach documents already in the library (Siri's files, read by
    /// `DocumentImport`) to the note.
    static func attach(_ documents: [Document], to note: VehicleNote, now: Date = .now) {
        guard !documents.isEmpty else { return }
        for document in documents { document.vehicleNote = note }
        note.modifiedAt = now
    }

    static func setPinned(_ isPinned: Bool, on note: VehicleNote, now: Date = .now) {
        guard note.isPinned != isPinned else { return }
        note.isPinned = isPinned
        note.modifiedAt = now
    }

    /// Detach one file from the note. It stays in the vehicle's library.
    static func detach(_ attachment: ServiceAttachment, from note: VehicleNote, now: Date = .now) {
        attachment.vehicleNote = nil
        note.modifiedAt = now
    }

    /// Delete a note (in-app only). Its files stay in the library.
    static func delete(_ note: VehicleNote, in context: ModelContext) {
        VehicleNoteMigration.noteWillBeDeleted(note)
        context.delete(note)
    }

    private static func apply(_ fields: VehicleNoteFields, to note: VehicleNote) {
        note.title = fields.title.trimmingCharacters(in: .whitespacesAndNewlines)
        note.body = fields.body
        note.isPinned = fields.isPinned
    }

    private static func attach(_ files: [NoteAttachmentFile], to note: VehicleNote, in context: ModelContext) {
        let vehicles = note.vehicle.map { [$0] } ?? []
        for file in files {
            let document = Document(
                data: file.data,
                thumbnailData: Document.generateThumbnailData(from: file.data, mimeType: file.mimeType),
                fileName: file.fileName,
                mimeType: file.mimeType,
                extractedText: file.extractedText,
                documentType: DocumentClassifier.keywordType(for: file.extractedText ?? "", fileName: file.fileName),
                vehicles: vehicles
            )
            document.vehicleNote = note
            context.insert(document)
        }
    }
}
