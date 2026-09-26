//
//  DocumentEntity+Transfer.swift
//  checkpoint
//
//  A document entity hands over its file, so Siri and Shortcuts can share
//  it: "share my insurance card", or Find Document chained into Mail or
//  Messages. A PDF goes as a PDF; a photo as a JPEG (the library stores
//  JPEG; an older PNG is re-encoded). Each representation is offered only
//  for its kind of document.
//
//  The entity is a light snapshot, so the bytes are read from the store
//  when the export is asked for — through the registered container
//  (`IntentDependencies.container`), as the system calls this outside any
//  intent's perform flow.
//

import CoreTransferable
import SwiftData
import UIKit
import UniformTypeIdentifiers

nonisolated extension DocumentEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { entity in
            try await DocumentExport.data(for: entity.id, as: .pdf)
        }
        .exportingCondition { $0.isPDF }
        .suggestedFileName { $0.fileName }

        DataRepresentation(exportedContentType: .jpeg) { entity in
            try await DocumentExport.data(for: entity.id, as: .jpeg)
        }
        .exportingCondition { !$0.isPDF }
        .suggestedFileName { $0.fileName }
    }
}

@MainActor
enum DocumentExport {

    /// The document's file as `type`. Throws `IntentError.documentNotFound`
    /// when it's gone or holds no data.
    static func data(for id: UUID, as type: UTType, in container: ModelContainer? = nil) throws -> Data {
        guard let container = container ?? IntentDependencies.container,
              let document = try DocumentEntity.models(ids: [id], in: container.mainContext).first,
              let data = document.data else { throw IntentError.documentNotFound }
        if type == .jpeg, document.mimeType != "image/jpeg" {
            guard let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.9) else { throw IntentError.documentNotFound }
            return jpeg
        }
        return data
    }
}
