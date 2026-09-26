//
//  DocumentImport.swift
//  checkpoint
//
//  A file handed to Checkpoint from outside (Siri, Shortcuts, the Share
//  Sheet through Shortcuts) becoming a document in a vehicle's library:
//  read its text (Vision for a photo, the PDF's own text or else its first
//  page through Vision), type it from that text (`DocumentClassifier`: the
//  on-device model, else keywords, else the name — as the Documents picker
//  types one), and insert it through the library's own constructors
//  (`Document.fromImage` / `.fromPDF`).
//
//  Add Document and Save Photos (the iOS 27 Photos schema) both go through
//  here. Nothing here saves; the intent commits.
//

import PDFKit
import SwiftData
import UIKit

@MainActor
enum DocumentImport {

    struct File {
        let data: Data
        let fileName: String
    }

    /// A file Checkpoint can keep, with the text read from it.
    struct Reading {
        enum Content {
            case image(UIImage)
            case pdf(Data)
        }

        let content: Content
        let text: String?

        var isPDF: Bool {
            if case .pdf = content { return true }
            return false
        }
    }

    /// Reads text from an image. The receipt scanner's OCR by default; tests
    /// pass a stub.
    typealias TextReader = @MainActor (UIImage) async -> String?

    /// What `file` is and says. Nil when it is neither an image nor a PDF.
    static func read(_ file: File, recognizeText: TextReader = DocumentImport.recognizeText(in:)) async -> Reading? {
        if let image = UIImage(data: file.data) {
            return Reading(content: .image(image), text: await recognizeText(image))
        }
        guard let pdf = PDFDocument(data: file.data), pdf.pageCount > 0 else { return nil }
        var text = pdf.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        if text?.isEmpty ?? true, let page = image(from: file.data) {
            // A scanned PDF has no text layer; read its first page.
            text = await recognizeText(page)
        }
        return Reading(content: .pdf(file.data), text: text)
    }

    /// Insert `reading` as a document on `vehicle`. A nameless file gets a
    /// dated name with the right extension.
    @discardableResult
    static func insert(
        _ reading: Reading,
        fileName: String,
        type: DocumentType,
        notes: String? = nil,
        on vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now,
        index: Int = 1
    ) -> Document? {
        let name = fileName.isEmpty ? defaultFileName(isPDF: reading.isPDF, now: now, index: index) : fileName
        let notes = notes.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        let document: Document?
        switch reading.content {
        case .image(let image):
            document = Document.fromImage(image, fileName: name, documentType: type, notes: notes, vehicles: [vehicle])
        case .pdf(let data):
            document = Document.fromPDF(data, fileName: name, documentType: type, notes: notes, vehicles: [vehicle])
        }
        guard let document else { return nil }
        document.extractedText = reading.text
        context.insert(document)
        return document
    }

    /// The receipt scanner's OCR. A file with no readable text is still
    /// saved, just without any.
    static func recognizeText(in image: UIImage) async -> String? {
        try? await ReceiptOCRService.shared.extractText(from: image).text
    }

    /// The file as an image: a photo as is, a PDF's first page rendered at
    /// reading resolution.
    nonisolated static func image(from data: Data) -> UIImage? {
        if let image = UIImage(data: data) { return image }
        guard let page = PDFDocument(data: data)?.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let scale = 2_000 / max(bounds.width, bounds.height, 1)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        return page.thumbnail(of: size, for: .mediaBox)
    }

    private static func defaultFileName(isPDF: Bool, now: Date, index: Int) -> String {
        let stamp = Int(now.timeIntervalSince1970)
        return isPDF ? "document_\(stamp)_\(index).pdf" : "photo_\(stamp)_\(index).jpg"
    }
}
