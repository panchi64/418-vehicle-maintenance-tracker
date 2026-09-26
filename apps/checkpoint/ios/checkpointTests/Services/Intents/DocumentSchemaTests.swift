//
//  DocumentSchemaTests.swift
//  checkpointTests
//
//  Documents as Photos-schema assets (images only, iOS 27) and Files-schema
//  files (everything), saving photos handed to Checkpoint, and where opening
//  one lands.
//

import XCTest
import AppIntents
import SwiftData
import UIKit
@testable import checkpoint

final class DocumentSchemaTests: IntentTestCase {

    private func pngData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        return renderer.pngData { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    @discardableResult
    private func addDocument(_ name: String, mimeType: String, vehicles: [Vehicle]? = nil) -> Document {
        let document = Document(
            data: Data([0x1]),
            fileName: name,
            mimeType: mimeType,
            documentType: .receipt,
            vehicles: vehicles ?? [vehicle]
        )
        context.insert(document)
        return document
    }

    // MARK: - Photos: filtering by type

    func test_photoAssets_areImageDocumentsOnly() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Photos asset schema is iOS 27") }
        let jpeg = addDocument("receipt.jpg", mimeType: "image/jpeg")
        let png = addDocument("card.png", mimeType: "image/png")
        addDocument("manual.pdf", mimeType: "application/pdf")
        try context.save()

        let photos = try DocumentPhotoEntity.entities(in: context)
        XCTAssertEqual(Set(photos.map(\.id)), [jpeg.id, png.id])
        XCTAssertTrue(photos.allSatisfy { $0.assetType == .photo && $0.location == nil && !$0.isFavorite })

        let albums = try VehicleAlbumEntity.entities(in: context)
        XCTAssertEqual(albums.map(\.id), [vehicle.id])
        XCTAssertEqual(albums.first?.albumType, .custom)
    }

    // MARK: - Files: every document

    func test_fileEntities_coverEveryDocument_andRoundTripTheirID() throws {
        let jpeg = addDocument("receipt.jpg", mimeType: "image/jpeg")
        let pdf = addDocument("manual.pdf", mimeType: "application/pdf")
        try context.save()

        let files = try DocumentFileEntity.entities(ids: nil, in: context)
        XCTAssertEqual(Set(files.compactMap(\.documentID)), [jpeg.id, pdf.id])
        XCTAssertTrue(files.allSatisfy(\.id.isDraft), "Stored in SwiftData, not on disk")
        XCTAssertEqual(files.first { $0.documentID == pdf.id }?.isPDF, true)

        let identifier = FileEntityIdentifier.draft(identifier: pdf.id.uuidString)
        XCTAssertEqual(DocumentFileEntity.documentID(from: identifier), pdf.id)
        XCTAssertNil(DocumentFileEntity.documentID(from: .draft(identifier: "not-a-uuid")))
    }

    func test_openFile_routesToTheDocument() async throws {
        let pdf = addDocument("manual.pdf", mimeType: "application/pdf")
        try context.save()
        PendingRouteStore.shared.route = nil
        let intent = wired(OpenDocumentFileIntent())
        intent.target = DocumentFileEntity(model: pdf)

        _ = try await intent.perform()

        XCTAssertEqual(PendingRouteStore.shared.take(), .document(vehicleID: vehicle.id, documentID: pdf.id))
    }

    // MARK: - Saving photos

    func test_importImages_savesImagesAsDocuments_withTheirText() async throws {
        let documents = await PhotoImport.importImages(
            [
                PhotoImport.File(data: pngData(), fileName: "insurance_card.png"),
                PhotoImport.File(data: Data("not an image".utf8), fileName: "notes.txt"),
                PhotoImport.File(data: pngData(), fileName: "")
            ],
            to: vehicle,
            in: context,
            recognizeText: { _ in "SYNTHETIC TEXT" }
        )

        XCTAssertEqual(documents.count, 2, "Only files that decode as images")
        XCTAssertEqual(documents[0].documentType, .insurance, "Typed from the name, as the picker does")
        XCTAssertEqual(documents[0].mimeType, "image/jpeg")
        XCTAssertEqual(documents[0].vehicles?.map(\.id), [vehicle.id])
        XCTAssertEqual(documents[0].extractedText, "SYNTHETIC TEXT")
        XCTAssertFalse(documents[1].fileName.isEmpty, "A nameless file gets one")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Document>()), 2)
    }

    // MARK: - Routes

    func test_documentRoute_prefersTheSelectedVehicle() throws {
        let other = Vehicle(name: "Other", make: "", model: "", year: 0, currentMileage: 0)
        context.insert(other)
        let shared = addDocument("policy.pdf", mimeType: "application/pdf", vehicles: [other, vehicle])
        let elsewhere = addDocument("title.pdf", mimeType: "application/pdf", vehicles: [other])
        try context.save()

        XCTAssertEqual(try EntityRoutes.document(shared.id, in: context), .document(vehicleID: vehicle.id, documentID: shared.id))
        XCTAssertEqual(try EntityRoutes.document(elsewhere.id, in: context), .document(vehicleID: other.id, documentID: elsewhere.id))
        XCTAssertThrowsError(try EntityRoutes.document(UUID(), in: context)) {
            XCTAssertEqual($0 as? IntentError, .documentNotFound)
        }
    }
}
