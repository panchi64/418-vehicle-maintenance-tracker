//
//  DocumentEntity.swift
//  checkpoint
//
//  A document from the Documents library — insurance card, registration,
//  receipt. `Document` is the `ServiceAttachment` model (see Document.swift).
//  Its OCR text is indexed, so Spotlight and Siri find a receipt by what it
//  says, not only by its file name.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct DocumentEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Document", numericFormat: "\(placeholder: .int) documents")
    }

    static var defaultQuery: DocumentEntityQuery { DocumentEntityQuery() }

    let id: UUID

    @Property(title: "Name", indexingKey: \.displayName)
    var fileName: String

    @Property(title: "Type")
    var type: DocumentType

    @Property(title: "Vehicles")
    var vehicleNames: [String]

    @Property(title: "Added")
    var createdAt: Date

    @Property(title: "Notes", indexingKey: \.comment)
    var notes: String?

    /// Text read from the scan (receipts, invoices), when it was scanned.
    @Property(title: "Text", indexingKey: \.textContent)
    var extractedText: String?

    let vehicleIDs: [UUID]
    let isPDF: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(fileName)",
            subtitle: "\(vehicleNames.joined(separator: ", "))",
            image: .init(systemName: isPDF ? "doc.richtext" : "photo")
        )
    }

    var searchableText: [String] { [fileName, notes ?? "", extractedText ?? ""] }

    @MainActor
    init(model document: Document) {
        let vehicles = (document.vehicles ?? []).sorted { $0.displayName < $1.displayName }
        id = document.id
        vehicleIDs = vehicles.map(\.id)
        isPDF = document.isPDF
        fileName = document.fileName
        type = document.documentType
        vehicleNames = vehicles.map(\.displayName)
        createdAt = document.createdAt
        notes = document.notes
        extractedText = document.extractedText
    }

    /// Newest first.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Document] {
        let newestFirst = [SortDescriptor(\Document.createdAt, order: .reverse)]
        let descriptor: FetchDescriptor<Document>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) }, sortBy: newestFirst)
        } else {
            descriptor = FetchDescriptor(sortBy: newestFirst)
        }
        return try context.fetch(descriptor)
    }
}

struct DocumentEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [DocumentEntity] {
        try await EntityFetch.entities(DocumentEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [DocumentEntity] {
        try await EntityFetch.entities(DocumentEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [DocumentEntity] {
        try await EntityFetch.entities(DocumentEntity.self, in: container)
    }
}
