//
//  AddDocumentIntent.swift
//  checkpoint
//
//  "Add this to my documents in Checkpoint." A photo or PDF — an insurance
//  card, the registration, a warranty — saved to a vehicle's Documents
//  library the way the library's picker saves one: its text read (so search
//  and Siri find it by what it says) and its type suggested from that text
//  (`DocumentClassifier`: the on-device model where available, else
//  keywords, else the file name). When nothing suggests a type, Siri asks.
//
//  Saving a document is additive and undoable in-app, so there is no
//  confirmation. Deleting one stays in-app.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

struct AddDocumentIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Document"
    static let description = IntentDescription("Save a photo or PDF to a vehicle's documents, such as an insurance card or registration. Checkpoint reads it and suggests its type.")

    @Dependency var container: ModelContainer

    @Parameter(
        title: "Document",
        description: "A photo or PDF",
        supportedContentTypes: [.image, .pdf],
        requestValueDialog: "Which document?"
    )
    var file: IntentFile

    /// Empty: suggested from what the document says.
    @Parameter(title: "Type", description: "Leave empty for Checkpoint to tell from the document.")
    var type: DocumentType?

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Notes")
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$file) to \(\.$vehicle)'s documents") {
            \.$type
            \.$notes
        }
    }

    init() {}

    init(vehicle: VehicleEntity?, type: DocumentType?) {
        self.vehicle = vehicle
        self.type = type
    }

    /// The classifier `perform()` types documents with. Tests substitute one
    /// without a language model.
    @MainActor static var makeClassifier: () -> DocumentClassifier = { DocumentClassifier() }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DocumentEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let fileName = file.filename
        guard let reading = await DocumentImport.read(DocumentImport.File(file)) else {
            throw IntentError.unsupportedDocument
        }

        var type = self.type ?? .other
        if self.type == nil {
            type = await Self.makeClassifier().classify(text: reading.text, fileName: fileName)
            if type == .other {
                type = try await $type.requestValue("What kind of document is it?")
            }
        }

        let document = try Self.save(reading, fileName: fileName, type: type, notes: notes, on: vehicle, in: context)
        return .result(
            value: DocumentEntity(model: document),
            dialog: IntentDialog(stringLiteral: L10n.siriDocumentSaved(type: document.documentType.displayName, vehicle: vehicle.displayName))
        )
    }

    /// The write.
    @MainActor
    static func save(
        _ reading: DocumentImport.Reading,
        fileName: String,
        type: DocumentType,
        notes: String?,
        on vehicle: Vehicle,
        in context: ModelContext
    ) throws -> Document {
        guard let document = DocumentImport.insert(reading, fileName: fileName, type: type, notes: notes, on: vehicle, in: context) else {
            throw IntentError.unsupportedDocument
        }
        try IntentStore.save(context)
        return document
    }
}
