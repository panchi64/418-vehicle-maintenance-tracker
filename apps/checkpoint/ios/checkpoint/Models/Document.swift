//
//  Document.swift
//  checkpoint
//
//  Type alias and convenience helpers for the unified document model.
//
//  The underlying SwiftData model is named `ServiceAttachment` because that's
//  the existing CloudKit record type — renaming the class would orphan every
//  receipt currently stored in iCloud. We expose `Document` as the forward-
//  looking name so new code reads naturally.
//

import Foundation
import SwiftData
import UIKit
import os

private let documentLogger = Logger(category: "Documents")

typealias Document = ServiceAttachment

extension Document {

    /// Vehicle-library import path: creates a Document of arbitrary type with
    /// optional notes and one-or-more vehicle links. No service log attached.
    static func fromImage(
        _ image: UIImage,
        fileName: String = "photo.jpg",
        documentType: DocumentType,
        notes: String? = nil,
        vehicles: [Vehicle]
    ) -> Document? {
        guard let data = compressedImageData(from: image) else { return nil }
        let thumbnail = generateThumbnailData(from: data, mimeType: "image/jpeg")
        let doc = Document(
            serviceLog: nil,
            data: data,
            thumbnailData: thumbnail,
            fileName: fileName,
            mimeType: "image/jpeg"
        )
        doc.documentType = documentType
        doc.notes = notes
        doc.vehicles = vehicles
        return doc
    }

    /// Vehicle-library import path: creates a PDF Document.
    static func fromPDF(
        _ data: Data,
        fileName: String = "document.pdf",
        documentType: DocumentType,
        notes: String? = nil,
        vehicles: [Vehicle]
    ) -> Document {
        let thumbnail = generateThumbnailData(from: data, mimeType: "application/pdf")
        let doc = Document(
            serviceLog: nil,
            data: data,
            thumbnailData: thumbnail,
            fileName: fileName,
            mimeType: "application/pdf"
        )
        doc.documentType = documentType
        doc.notes = notes
        doc.vehicles = vehicles
        return doc
    }

    /// Sweep documents that no longer belong anywhere. Called after a vehicle
    /// is deleted or after the last vehicle link is removed in the UI. A doc
    /// is orphaned when it has no vehicles AND no service log.
    @MainActor
    static func purgeOrphans(in context: ModelContext) {
        do {
            let candidates = try context.fetch(FetchDescriptor<Document>())
            for doc in candidates where (doc.vehicles?.isEmpty ?? true) && doc.serviceLog == nil {
                context.delete(doc)
            }
            try context.save()
        } catch {
            documentLogger.error("purgeOrphans failed: \(error.localizedDescription)")
        }
    }
}
