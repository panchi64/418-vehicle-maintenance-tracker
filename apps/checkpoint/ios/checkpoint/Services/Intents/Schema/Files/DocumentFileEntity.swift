//
//  DocumentFileEntity.swift
//  checkpoint
//
//  Every document in the library — PDFs included — as a file in the Files
//  schema, with Open File. Files is a Shortcuts-only domain: Siri AI doesn't
//  act on it, but Shortcuts' file actions can take a Checkpoint document.
//
//  The Files schemas are iOS 18 in the SDK (unlike Reminders and Photos,
//  which are iOS 27), and these are new types, so they ship on iOS 26 with
//  no gate.
//
//  A file entity's ID must be a `FileEntityIdentifier`. Documents live in
//  the SwiftData store, not on disk, so each uses a draft identifier (for
//  documents "which aren't materialized on disk yet and don't have a file
//  URL") carrying the document's UUID.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

@AppEntity(schema: .files.file)
struct DocumentFileEntity: FileEntity {
    static let defaultQuery = DocumentFileEntityQuery()
    static var supportedContentTypes: [UTType] { [.pdf, .image] }

    let id: FileEntityIdentifier

    var creationDate: Date?
    var fileModificationDate: Date?

    let fileName: String
    let isPDF: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(fileName)", image: .init(systemName: isPDF ? "doc.richtext" : "photo"))
    }

    /// The document this file stands for.
    var documentID: UUID? { Self.documentID(from: id) }

    @MainActor
    init(model document: Document) {
        // Plain stored properties first: assigning a schema property goes
        // through the wrapper the macro adds, which needs `self` complete.
        id = .draft(identifier: document.id.uuidString)
        fileName = document.fileName
        isPDF = document.isPDF
        creationDate = document.createdAt
        fileModificationDate = nil
    }

    nonisolated static func documentID(from identifier: FileEntityIdentifier) -> UUID? {
        identifier.draftIdentifier.flatMap(UUID.init(uuidString:))
    }

    @MainActor
    static func entities(ids: [UUID]?, in context: ModelContext) throws -> [DocumentFileEntity] {
        try DocumentEntity.models(ids: ids, in: context).map(Self.init(model:))
    }
}

struct DocumentFileEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [DocumentFileEntity] {
        let ids = identifiers.compactMap(DocumentFileEntity.documentID(from:))
        return try await MainActor.run { [container] in
            try DocumentFileEntity.entities(ids: ids, in: container.mainContext)
        }
    }

    /// Matched as `DocumentEntity` matches: name, notes and scanned text.
    func entities(matching string: String) async throws -> [DocumentFileEntity] {
        try await MainActor.run { [container] in
            let ids = try DocumentEntity.entities(matching: string, in: container.mainContext).map(\.id)
            return try DocumentFileEntity.entities(ids: ids, in: container.mainContext)
        }
    }

    func suggestedEntities() async throws -> [DocumentFileEntity] {
        try await MainActor.run { [container] in
            try DocumentFileEntity.entities(ids: nil, in: container.mainContext)
        }
    }
}

@AppIntent(schema: .files.openFile)
struct OpenDocumentFileIntent: OpenIntent {
    @Dependency var container: ModelContainer

    var target: DocumentFileEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = target.documentID else { throw IntentError.documentNotFound }
        EntityRoutes.open(try EntityRoutes.document(id, in: container.mainContext))
        return .result()
    }
}
