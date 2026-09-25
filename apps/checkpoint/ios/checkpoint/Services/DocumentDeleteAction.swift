//
//  DocumentDeleteAction.swift
//  checkpoint
//
//  The one way the UI deletes documents: the delete, and the Undo that puts
//  them back. The sibling of `ServiceLogDeleteAction`.
//
//  A single document (swipe, long-press menu, the detail's menu) is deleted
//  at once and offered Undo — reversible beats a confirmation on every
//  delete. A multi-select delete is confirmed first by the caller, the same
//  way Services' Select mode confirms, and still offered Undo. Toasts render
//  above sheets, so the Undo is visible from any door.
//

import Foundation
import SwiftData
import os

private let documentDeleteLogger = Logger(category: "Documents")

/// Everything needed to rebuild a deleted document, captured before delete.
struct DocumentSnapshot {
    let id: UUID
    let serviceLog: ServiceLog?
    let data: Data?
    let thumbnailData: Data?
    let fileName: String
    let mimeType: String
    let createdAt: Date
    let extractedText: String?
    let documentTypeRaw: String
    let notes: String?
    let vehicles: [Vehicle]

    init(_ document: Document) {
        id = document.id
        serviceLog = document.serviceLog
        data = document.data
        thumbnailData = document.thumbnailData
        fileName = document.fileName
        mimeType = document.mimeType
        createdAt = document.createdAt
        extractedText = document.extractedText
        documentTypeRaw = document.documentTypeRaw
        notes = document.notes
        vehicles = document.vehicles ?? []
    }

    /// Re-inserts the document with its identity, links and payload.
    func restore(in context: ModelContext) {
        let document = Document(
            serviceLog: serviceLog,
            data: data,
            thumbnailData: thumbnailData,
            fileName: fileName,
            mimeType: mimeType,
            createdAt: createdAt,
            extractedText: extractedText,
            notes: notes,
            vehicles: vehicles
        )
        document.id = id
        document.documentTypeRaw = documentTypeRaw
        context.insert(document)
    }
}

enum DocumentDeleteAction {

    /// Deletes the documents now and offers Undo.
    static func perform(_ documents: [Document], in context: ModelContext) {
        guard !documents.isEmpty else { return }
        let snapshots = documents.map(DocumentSnapshot.init)
        for document in documents {
            context.delete(document)
        }
        HapticService.shared.warning()
        guard save(context) else { return }

        let message = documents.count == 1
            ? L10n.documentsToastDeleted
            : L10n.documentsToastDeletedCount(documents.count)
        ToastService.shared.show(
            message,
            icon: "trash",
            style: .info,
            action: ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                for snapshot in snapshots {
                    snapshot.restore(in: context)
                }
                _ = save(context)
                HapticService.shared.selectionChanged()
            }
        )
    }

    /// Persist a user-initiated change. On failure, log it and say so rather
    /// than swallowing the error — the row would otherwise reappear on the
    /// next fetch with no explanation.
    @discardableResult
    private static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            documentDeleteLogger.error("Document delete save failed: \(error.localizedDescription)")
            ToastService.shared.show(L10n.documentsDeleteError, icon: "exclamationmark.triangle", style: .error)
            return false
        }
    }
}
