//
//  DocumentIntentTests.swift
//  checkpointTests
//
//  Add Document (reading an image or PDF, typing it, saving it), Find
//  Document, a document entity handing over its file, and Export Service
//  History returning a PDF.
//

import AppIntents
import CoreTransferable
import XCTest
import SwiftData
import UIKit
import UniformTypeIdentifiers
@testable import checkpoint

extension AddDocumentIntent: StoreBackedIntent {}
extension FindDocumentIntent: StoreBackedIntent {}
extension ExportServiceHistoryIntent: StoreBackedIntent {}

final class DocumentIntentTests: IntentTestCase {

    private func pngData() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 40, height: 20)).pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        }
    }

    private func pdfData(text: String? = "POLICY NUMBER 123 INSURED") -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).pdfData { context in
            context.beginPage()
            text?.draw(at: CGPoint(x: 72, y: 72))
        }
    }

    @discardableResult
    private func addDocument(_ name: String, type: DocumentType, text: String? = nil, on vehicles: [Vehicle]? = nil, daysAgo: Int = 0) -> Document {
        let document = Document.fromPDF(pdfData(), fileName: name, documentType: type, vehicles: vehicles ?? [vehicle])
        document.extractedText = text
        document.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        context.insert(document)
        return document
    }

    // MARK: - Reading

    func test_read_imageIsReadWithVision_pdfWithItsOwnText() async {
        let image = await DocumentImport.read(.init(data: pngData(), fileName: "card.png"), recognizeText: { _ in "OCR TEXT" })
        XCTAssertFalse(image?.isPDF ?? true)
        XCTAssertEqual(image?.text, "OCR TEXT")

        let pdf = await DocumentImport.read(.init(data: pdfData(), fileName: "policy.pdf"), recognizeText: { _ in "unused" })
        XCTAssertTrue(pdf?.isPDF ?? false)
        XCTAssertTrue(pdf?.text?.contains("POLICY NUMBER") ?? false)
    }

    func test_read_scannedPDF_fallsBackToVision() async {
        let pdf = await DocumentImport.read(.init(data: pdfData(text: nil), fileName: "scan.pdf"), recognizeText: { _ in "FROM VISION" })
        XCTAssertEqual(pdf?.text, "FROM VISION")
    }

    func test_read_neitherImageNorPDF_isNil() async {
        let reading = await DocumentImport.read(.init(data: Data("hello".utf8), fileName: "notes.txt"), recognizeText: { _ in nil })
        XCTAssertNil(reading)
    }

    // MARK: - Add Document

    func test_save_insertsOnTheVehicle_withTextTypeAndNotes() async throws {
        let reading = await DocumentImport.read(.init(data: pdfData(), fileName: ""), recognizeText: { _ in nil })!

        let document = try AddDocumentIntent.save(reading, fileName: "", type: .insurance, notes: "  Renew in May ", on: vehicle, in: context)

        XCTAssertEqual(document.documentType, .insurance)
        XCTAssertEqual(document.mimeType, "application/pdf")
        XCTAssertTrue(document.fileName.hasSuffix(".pdf"), "A nameless file gets a name")
        XCTAssertEqual(document.notes, "  Renew in May ")
        XCTAssertEqual(document.vehicles?.map(\.id), [vehicle.id])
        XCTAssertNotNil(document.extractedText)
        XCTAssertFalse(context.hasChanges)
    }

    func test_perform_withAType_savesWithoutAsking() async throws {
        let intent = wired(AddDocumentIntent(vehicle: nil, type: .registration))
        intent.file = IntentFile(data: pngData(), filename: "reg.png", type: .png)

        let result = try await intent.perform()

        XCTAssertEqual(result.value?.type, .registration)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Document>()), 1)
    }

    func test_classifier_typesFromWhatTheDocumentSays() async {
        let reading = await DocumentImport.read(.init(data: pdfData(), fileName: "scan.pdf"), recognizeText: { _ in nil })!
        let type = await DocumentClassifier(session: nil).classify(text: reading.text, fileName: "scan.pdf")
        XCTAssertEqual(type, .insurance)
    }

    // MARK: - Find Document

    func test_find_newestOfTheType_onTheVehicleShowingFirst() throws {
        let other = Vehicle(name: "Other", make: "", model: "", year: 0)
        context.insert(other)
        addDocument("old_insurance.pdf", type: .insurance, daysAgo: 400)
        let current = addDocument("insurance.pdf", type: .insurance, daysAgo: 10)
        addDocument("other_insurance.pdf", type: .insurance, on: [other], daysAgo: 1)
        try context.save()

        XCTAssertEqual(try FindDocumentIntent.find(type: .insurance, text: nil, preferring: vehicle, in: context)?.id, current.id)
        XCTAssertNil(try FindDocumentIntent.find(type: .title, text: nil, preferring: vehicle, in: context))
    }

    func test_find_byText_andElsewhereWhenTheVehicleHasNone() throws {
        let other = Vehicle(name: "Other", make: "", model: "", year: 0)
        context.insert(other)
        let warranty = addDocument("contract.pdf", type: .warranty, text: "Extended plan 9981", on: [other])
        try context.save()

        let found = try FindDocumentIntent.find(type: nil, text: "9981", preferring: vehicle, in: context)
        XCTAssertEqual(found?.id, warranty.id)
        XCTAssertEqual(FindDocumentIntent.owner(of: warranty, preferring: vehicle).id, other.id)
    }

    func test_perform_returnsTheDocument() async throws {
        let card = addDocument("insurance.pdf", type: .insurance)
        try context.save()

        let result = try await wired(FindDocumentIntent(type: .insurance)).perform()

        XCTAssertEqual(result.value?.id, card.id)
    }

    func test_perform_noMatch_saysSo() async {
        do {
            _ = try await wired(FindDocumentIntent(type: .manual)).perform()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .noMatchingDocument)
        }
    }

    // MARK: - Export (Transferable)

    func test_entity_handsOverAPDFAsPDF_andAPhotoAsJPEG() async throws {
        let pdf = addDocument("policy.pdf", type: .insurance)
        let photo = Document.fromImage(UIImage(data: pngData())!, fileName: "card.jpg", documentType: .insurance, vehicles: [vehicle])!
        context.insert(photo)
        try context.save()

        let pdfEntity = DocumentEntity(model: pdf)
        XCTAssertEqual(pdfEntity.exportedContentTypes(), [.pdf])
        let pdfData = try await pdfEntity.exported(as: .pdf)
        XCTAssertEqual(pdfData, pdf.data)

        let photoEntity = DocumentEntity(model: photo)
        XCTAssertEqual(photoEntity.exportedContentTypes(), [.jpeg])
        let jpeg = try await photoEntity.exported(as: .jpeg)
        XCTAssertNotNil(UIImage(data: jpeg))
    }

    func test_export_deletedDocument_throws() {
        XCTAssertThrowsError(try DocumentExport.data(for: UUID(), as: .pdf, in: container)) {
            XCTAssertEqual($0 as? IntentError, .documentNotFound)
        }
    }

    // MARK: - Export Service History

    func test_exportHistory_returnsAPDF() async throws {
        let oil = addService()
        addLog(for: oil, daysAgo: 30, cost: 45)
        addLog(for: oil, daysAgo: 200, cost: 40)
        try context.save()

        let result = try await wired(ExportServiceHistoryIntent()).perform()

        let file = try XCTUnwrap(result.value)
        XCTAssertEqual(file.type, .pdf)
        XCTAssertTrue(file.data.starts(with: Data("%PDF".utf8)))
    }

    func test_exportHistory_withNoHistory_saysSo() async {
        do {
            _ = try await ExportServiceHistoryIntent.export(vehicle)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .nothingToExport)
        }
    }
}
