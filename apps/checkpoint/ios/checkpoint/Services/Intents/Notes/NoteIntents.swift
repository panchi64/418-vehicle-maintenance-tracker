//
//  NoteIntents.swift
//  checkpoint
//
//  Vehicle notes by voice (iOS 26, every tier):
//    "Add a note to the Civic in Checkpoint: brake pads at 40 percent"
//    "What's the paint code note in Checkpoint?"
//
//  Adding is additive and editable in-app, so it doesn't ask. There is no
//  note delete by voice (the delete policy keeps deletes to services and
//  logs). Writes go through `VehicleNoteService`, which also keeps the legacy
//  note mirrored for older app versions. On iOS 27 the Notes schema twins
//  (`Schema/Notes/`) reach the same functions.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

// MARK: - Add

struct AddVehicleNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Vehicle Note"
    static let description = IntentDescription("Save a note to a vehicle, such as a part number or what the shop recommended, with optional photos or PDFs.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Text", requestValueDialog: "What should the note say?")
    var text: String

    @Parameter(title: "Title", description: "Leave empty to use the first line.")
    var noteTitle: String?

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Pinned", default: false)
    var isPinned: Bool

    @Parameter(title: "Attachments", supportedContentTypes: [.image, .pdf])
    var files: [IntentFile]?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$text) to \(\.$vehicle)'s notes") {
            \.$noteTitle
            \.$isPinned
            \.$files
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleNoteEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        var readings: [(DocumentImport.Reading, String)] = []
        for file in files ?? [] {
            if let reading = await DocumentImport.read(DocumentImport.File(data: file.data, fileName: file.filename)) {
                readings.append((reading, file.filename))
            }
        }
        let note = try Self.add(
            VehicleNoteFields(title: noteTitle ?? "", body: text, isPinned: isPinned),
            files: readings,
            to: vehicle,
            in: context
        )
        let dialog = note.isPinned
            ? L10n.siriNotePinnedSaved(vehicle: vehicle.displayName)
            : L10n.siriNoteSaved(vehicle: vehicle.displayName)
        return .result(value: VehicleNoteEntity(model: note), dialog: IntentDialog(stringLiteral: dialog))
    }

    /// The write: the note, then each readable file as a document on it.
    @MainActor
    static func add(
        _ fields: VehicleNoteFields,
        files: [(DocumentImport.Reading, String)] = [],
        to vehicle: Vehicle,
        in context: ModelContext
    ) throws -> VehicleNote {
        guard fields.hasContent || !files.isEmpty else { throw IntentError.noteNeedsText }
        let note = VehicleNoteService.create(fields, on: vehicle, in: context)
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
        return note
    }
}

// MARK: - Find

struct FindNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Vehicle Note"
    static let description = IntentDescription("Find a vehicle note by what it says and read it back.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Search", requestValueDialog: "What's the note about?")
    var query: String

    @Parameter(title: "Vehicle", description: "Leave empty to search every vehicle, the one Checkpoint is showing first.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Find the \(\.$query) note") {
            \.$vehicle
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleNoteEntity> & ProvidesDialog {
        let context = container.mainContext
        let note = try Self.find(query, vehicleID: vehicle?.id, in: context)
        let entity = VehicleNoteEntity(model: note)
        let text = VehicleNote.firstLine(of: note.previewLine ?? "") ?? ""
        let dialog = text.isEmpty
            ? L10n.siriNoteFoundTitleOnly(title: entity.title, vehicle: entity.vehicleName)
            : L10n.siriNoteFound(title: entity.title, vehicle: entity.vehicleName, text: text)
        return .result(value: entity, dialog: IntentDialog(stringLiteral: dialog))
    }

    /// The best match: a note on the named vehicle — or, with none named,
    /// the showing vehicle's notes first — whose title or text contains the
    /// query; title matches beat text matches, pinned beat unpinned.
    @MainActor
    static func find(
        _ query: String,
        vehicleID: UUID?,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> VehicleNote {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var notes = try VehicleNoteEntity.models(ids: nil, in: context)
        if let vehicleID {
            notes = notes.filter { $0.vehicle?.id == vehicleID }
        }
        let matches = notes.filter { $0.matches(needle) }
        let showingID = defaults.string(forKey: AppGroupConstants.appSelectedVehicleIDKey)
        let best = matches.sorted { lhs, rhs in
            let lhsKey = rank(lhs, needle: needle, showingID: showingID)
            let rhsKey = rank(rhs, needle: needle, showingID: showingID)
            if lhsKey != rhsKey { return lhsKey < rhsKey }
            return VehicleNote.listOrder(lhs, rhs)
        }.first
        guard let best else { throw IntentError.noMatchingNote }
        return best
    }

    /// Lower ranks first: title match, then the showing vehicle.
    @MainActor
    private static func rank(_ note: VehicleNote, needle: String, showingID: String?) -> Int {
        let titleMatch = !needle.isEmpty && note.displayTitle.localizedStandardContains(needle)
        let onShowing = note.vehicle?.id.uuidString == showingID
        return (titleMatch ? 0 : 2) + (onShowing ? 0 : 1)
    }
}
