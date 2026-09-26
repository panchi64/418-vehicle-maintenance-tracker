//
//  NotesSchema.swift
//  checkpoint
//
//  The iOS 27 Notes schema over vehicle notes: a vehicle is a folder, a
//  `VehicleNote` is a note. "Add a note to the Civic: brake pads at 40%" and
//  "what did I note about the paint?" reach them through Apple Intelligence.
//
//  Separate `@available(iOS 27, *)` types over the same models as the iOS 26
//  `VehicleEntity` / `VehicleNoteEntity`, with the same UUIDs. Folders are
//  flat (no parent) and there are no accounts, but the metadata processor
//  needs the `.notes.account` type to exist; its query finds nothing.
//
//  `createNote` and `updateNote` overlap Add Vehicle Note and the note sheet;
//  create is `isAssistantOnly` so Shortcuts lists Add Vehicle Note once, and
//  update has no iOS 26 twin, so it shows. There is no delete: deleting a
//  note stays in-app.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

@available(iOS 27, *)
@AppEntity(schema: .notes.account)
struct NoNotesAccountEntity {
    static let defaultQuery = NoNotesAccountQuery()

    let id: UUID

    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 27, *)
struct NoNotesAccountQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoNotesAccountEntity] { [] }
    func entities(matching string: String) async throws -> [NoNotesAccountEntity] { [] }
}

@available(iOS 27, *)
@AppEntity(schema: .notes.folder)
struct VehicleFolderEntity: ModelSnapshotEntity {
    static let defaultQuery = VehicleFolderEntityQuery()

    let id: UUID

    var name: String
    /// Always nil: a vehicle's notes aren't nested.
    var parentFolder: VehicleFolderEntity?
    /// Always nil: notes live in the app's store, not an account.
    var account: NoNotesAccountEntity?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "car.fill"))
    }

    var searchableText: [String] { [name] }

    @MainActor
    init(model vehicle: Vehicle) {
        self.init(id: vehicle.id, name: vehicle.displayName)
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
        parentFolder = nil
        account = nil
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Vehicle] {
        try VehicleEntity.models(ids: ids, in: context)
    }
}

@available(iOS 27, *)
struct VehicleFolderEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleFolderEntity] {
        try await EntityFetch.entities(VehicleFolderEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleFolderEntity] {
        try await EntityFetch.entities(VehicleFolderEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleFolderEntity] {
        try await EntityFetch.entities(VehicleFolderEntity.self, in: container)
    }
}

@available(iOS 27, *)
@AppEntity(schema: .notes.note)
struct VehicleNoteSchemaEntity: ModelSnapshotEntity {
    static let defaultQuery = VehicleNoteSchemaEntityQuery()

    let id: UUID

    var name: AttributedString
    var content: AttributedString?
    /// Empty in the snapshot: the files are Documents, exported on their own
    /// (`DocumentEntity`). Reading every attachment's bytes to build a
    /// snapshot would load images for a list of names.
    var attachments: [IntentFile]
    var isPinned: Bool
    var creationDate: Date?
    var modificationDate: Date?
    var folder: VehicleFolderEntity?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(name.characters))",
            subtitle: "\(folder?.name ?? "")",
            image: .init(systemName: isPinned ? "pin.fill" : "note.text")
        )
    }

    var searchableText: [String] { [String(name.characters), content.map { String($0.characters) } ?? ""] }

    @MainActor
    init(model note: VehicleNote) {
        id = note.id
        name = AttributedString(note.displayTitle)
        content = note.body.isEmpty ? nil : AttributedString(note.body)
        attachments = []
        isPinned = note.isPinned
        creationDate = note.createdAt
        modificationDate = note.modifiedAt
        folder = note.vehicle.map(VehicleFolderEntity.init(model:))
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [VehicleNote] {
        try VehicleNoteEntity.models(ids: ids, in: context)
    }
}

@available(iOS 27, *)
struct VehicleNoteSchemaEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleNoteSchemaEntity] {
        try await EntityFetch.entities(VehicleNoteSchemaEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleNoteSchemaEntity] {
        try await EntityFetch.entities(VehicleNoteSchemaEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleNoteSchemaEntity] {
        try await EntityFetch.entities(VehicleNoteSchemaEntity.self, in: container)
    }
}

// MARK: - Intents

@available(iOS 27, *)
@AppIntent(schema: .notes.createNote)
struct CreateVehicleNoteIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var name: AttributedString
    var content: AttributedString?
    var attachments: [IntentFile]
    var isPinned: Bool
    var folder: VehicleFolderEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleNoteSchemaEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(id: folder?.id, in: context)
        let files = await NotesMapping.readings(attachments)
        let note = try AddVehicleNoteIntent.add(
            NotesMapping.fields(name: name, content: content, isPinned: isPinned),
            files: files,
            to: vehicle,
            in: context
        )
        let dialog = note.isPinned
            ? L10n.siriNotePinnedSaved(vehicle: vehicle.displayName)
            : L10n.siriNoteSaved(vehicle: vehicle.displayName)
        return .result(value: VehicleNoteSchemaEntity(model: note), dialog: IntentDialog(stringLiteral: dialog))
    }
}

@available(iOS 27, *)
@AppIntent(schema: .notes.updateNote)
struct UpdateVehicleNoteIntent {
    @Dependency var container: ModelContainer

    var target: VehicleNoteSchemaEntity
    var name: AttributedString?
    var attachments: [IntentFile]?
    var isPinned: Bool?
    var folder: VehicleFolderEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleNoteSchemaEntity> & ProvidesDialog {
        let context = container.mainContext
        let note = try IntentStore.note(id: target.id, in: context)
        guard let vehicle = note.vehicle else { throw IntentError.noteNotFound }
        if let folder, folder.id != vehicle.id { throw IntentError.noteCannotMove }
        let files = await NotesMapping.readings(attachments ?? [])
        try Self.apply(name: name.map { String($0.characters) }, isPinned: isPinned, files: files, to: note, in: context)
        return .result(
            value: VehicleNoteSchemaEntity(model: note),
            dialog: IntentDialog(stringLiteral: L10n.siriNoteSaved(vehicle: vehicle.displayName))
        )
    }

    /// The write: a new title, pin state and more files. The schema's update
    /// has no content field, so the text stays.
    @MainActor
    static func apply(
        name: String?,
        isPinned: Bool?,
        files: [(DocumentImport.Reading, String)],
        to note: VehicleNote,
        in context: ModelContext
    ) throws {
        guard let vehicle = note.vehicle else { throw IntentError.noteNotFound }
        var fields = VehicleNoteFields(note: note)
        if let name { fields.title = name }
        if let isPinned { fields.isPinned = isPinned }
        VehicleNoteService.update(note, with: fields, in: context)
        let documents = files.enumerated().compactMap { index, file in
            DocumentImport.insert(
                file.0,
                fileName: file.1,
                type: DocumentClassifier.keywordType(for: file.0.text ?? "", fileName: file.1),
                on: vehicle,
                in: context,
                index: index + 1
            )
        }
        VehicleNoteService.attach(documents, to: note)
        try IntentStore.save(context)
    }
}

@available(iOS 27, *)
enum NotesMapping {
    /// A schema note's name and content as note fields. The name is the
    /// title unless it only repeats the content's first line.
    nonisolated static func fields(name: AttributedString, content: AttributedString?, isPinned: Bool) -> VehicleNoteFields {
        let title = String(name.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        let body = content.map { String($0.characters) } ?? ""
        if body.isEmpty { return VehicleNoteFields(title: "", body: title, isPinned: isPinned) }
        let repeatsFirstLine = VehicleNote.firstLine(of: body) == title
        return VehicleNoteFields(title: repeatsFirstLine ? "" : title, body: body, isPinned: isPinned)
    }

    /// Siri's files, read the way Add Document reads one.
    @MainActor
    static func readings(_ files: [IntentFile]) async -> [(DocumentImport.Reading, String)] {
        var readings: [(DocumentImport.Reading, String)] = []
        for file in files {
            if let reading = await DocumentImport.read(DocumentImport.File(data: file.data, fileName: file.filename)) {
                readings.append((reading, file.filename))
            }
        }
        return readings
    }
}
