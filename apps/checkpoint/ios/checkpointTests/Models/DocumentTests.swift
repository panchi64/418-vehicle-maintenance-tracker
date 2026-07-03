//
//  DocumentTests.swift
//  checkpointTests
//
//  Tests for the unified Document (ServiceAttachment) behavior:
//  cross-vehicle linking, auto vehicle linking from a service log,
//  and the orphan sweep.
//

import XCTest
import SwiftData
import UIKit
@testable import checkpoint

final class DocumentTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Defaults

    @MainActor
    func testDocumentType_DefaultsToReceipt() {
        let doc = Document(
            data: Data(),
            fileName: "x.jpg",
            mimeType: "image/jpeg"
        )
        XCTAssertEqual(doc.documentType, .receipt)
    }

    @MainActor
    func testNotes_DefaultsToNil() {
        let doc = Document(
            data: Data(),
            fileName: "x.jpg",
            mimeType: "image/jpeg"
        )
        XCTAssertNil(doc.notes)
    }

    // MARK: - Auto-link from service log

    @MainActor
    func testInit_AutoLinksVehicleFromServiceLog() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        modelContext.insert(vehicle)

        let log = ServiceLog(vehicle: vehicle, performedDate: .now, mileageAtService: 10_000)
        modelContext.insert(log)

        let doc = Document(
            serviceLog: log,
            data: Data(),
            fileName: "receipt.jpg",
            mimeType: "image/jpeg"
        )
        modelContext.insert(doc)

        XCTAssertEqual(doc.vehicles?.count, 1)
        XCTAssertEqual(doc.vehicles?.first?.id, vehicle.id)
    }

    @MainActor
    func testInit_ExplicitVehiclesOverrideAutoLink() {
        let vehicleA = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let vehicleB = Vehicle(make: "Mazda", model: "MX-5", year: 2020)
        modelContext.insert(vehicleA)
        modelContext.insert(vehicleB)

        let log = ServiceLog(vehicle: vehicleA, performedDate: .now, mileageAtService: 10_000)
        modelContext.insert(log)

        let doc = Document(
            serviceLog: log,
            data: Data(),
            fileName: "shared.pdf",
            mimeType: "application/pdf",
            vehicles: [vehicleA, vehicleB]
        )
        modelContext.insert(doc)

        XCTAssertEqual(doc.vehicles?.count, 2)
    }

    @MainActor
    func testInit_NoServiceLogNoVehicles() {
        let doc = Document(
            data: Data(),
            fileName: "x.jpg",
            mimeType: "image/jpeg"
        )
        XCTAssertNil(doc.vehicles)
    }

    // MARK: - Vehicle.documents inverse

    @MainActor
    func testVehicleDocuments_ReflectsLinkedDocuments() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        modelContext.insert(vehicle)

        let doc = Document(
            data: Data(),
            fileName: "registration.pdf",
            mimeType: "application/pdf",
            documentType: .registration,
            vehicles: [vehicle]
        )
        modelContext.insert(doc)

        XCTAssertEqual(vehicle.documents?.count, 1)
        XCTAssertEqual(vehicle.documents?.first?.id, doc.id)
    }

    @MainActor
    func testVehicleDocuments_CrossVehicleLinking() {
        // One file, two vehicles, no duplicate data payload.
        let vehicleA = Vehicle(make: "Ford", model: "F-150", year: 2021)
        let vehicleB = Vehicle(make: "Ford", model: "F-250", year: 2022)
        modelContext.insert(vehicleA)
        modelContext.insert(vehicleB)

        let payload = Data(repeating: 0xAB, count: 4096)
        let doc = Document(
            data: payload,
            fileName: "business-insurance.pdf",
            mimeType: "application/pdf",
            documentType: .insurance,
            notes: "Fleet policy — covers both trucks",
            vehicles: [vehicleA, vehicleB]
        )
        modelContext.insert(doc)

        XCTAssertEqual(vehicleA.documents?.count, 1)
        XCTAssertEqual(vehicleB.documents?.count, 1)
        XCTAssertEqual(vehicleA.documents?.first?.id, vehicleB.documents?.first?.id)
        XCTAssertEqual(doc.vehicles?.count, 2)
        XCTAssertEqual(doc.notes, "Fleet policy — covers both trucks")
    }

    // MARK: - purgeOrphans

    @MainActor
    func testPurgeOrphans_RemovesDocsWithNoVehiclesAndNoServiceLog() throws {
        let vehicle = Vehicle(make: "Honda", model: "Civic", year: 2020)
        modelContext.insert(vehicle)

        let kept = Document(
            data: Data(),
            fileName: "kept.pdf",
            mimeType: "application/pdf",
            vehicles: [vehicle]
        )
        modelContext.insert(kept)

        let orphan = Document(
            data: Data(),
            fileName: "orphan.pdf",
            mimeType: "application/pdf"
        )
        // Explicitly clear vehicles to simulate "last vehicle removed".
        orphan.vehicles = []
        modelContext.insert(orphan)

        try modelContext.save()

        Document.purgeOrphans(in: modelContext)

        let remaining = try modelContext.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.fileName, "kept.pdf")
    }

    @MainActor
    func testPurgeOrphans_PreservesDocLinkedToServiceLogEvenWithoutVehicles() throws {
        let vehicle = Vehicle(make: "Honda", model: "Civic", year: 2020)
        modelContext.insert(vehicle)
        let log = ServiceLog(vehicle: vehicle, performedDate: .now, mileageAtService: 50_000)
        modelContext.insert(log)

        let doc = Document(
            serviceLog: log,
            data: Data(),
            fileName: "receipt.jpg",
            mimeType: "image/jpeg"
        )
        // Strip vehicles but keep service-log link.
        doc.vehicles = []
        modelContext.insert(doc)

        try modelContext.save()

        Document.purgeOrphans(in: modelContext)

        let remaining = try modelContext.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertNotNil(remaining.first?.serviceLog)
    }

    // MARK: - Delete-rule semantics

    /// Deleting a ServiceLog must not hard-delete its attachments. The
    /// `ServiceLog.attachments` rule is `.nullify`, so the document survives
    /// in the Documents library with its log link cleared but vehicle intact.
    @MainActor
    func testDeleteServiceLog_PreservesAttachmentAndVehicleLink() throws {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        modelContext.insert(vehicle)

        let log = ServiceLog(vehicle: vehicle, performedDate: .now, mileageAtService: 30_000)
        modelContext.insert(log)

        let doc = Document(
            serviceLog: log,
            data: Data(),
            fileName: "receipt.jpg",
            mimeType: "image/jpeg"
        )
        modelContext.insert(doc)
        try modelContext.save()

        modelContext.delete(log)
        try modelContext.save()

        let remaining = try modelContext.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(remaining.count, 1, "Attachment should survive its log's deletion")
        XCTAssertNil(remaining.first?.serviceLog, "Log link should be nullified")
        XCTAssertEqual(remaining.first?.vehicles?.first?.id, vehicle.id, "Vehicle link should remain")
    }

    /// Deleting a vehicle removes documents that were linked only to it: the
    /// `.nullify` on `Vehicle.documents` clears the link and the orphan sweep
    /// (run on the production vehicle-delete path) reclaims the now-ownerless
    /// document. Mirrors `EditVehicleView.deleteVehicle`.
    @MainActor
    func testDeleteVehicle_RemovesItsExclusiveDocuments() throws {
        let vehicle = Vehicle(make: "Honda", model: "Civic", year: 2021)
        modelContext.insert(vehicle)

        let doc = Document(
            data: Data(),
            fileName: "registration.pdf",
            mimeType: "application/pdf",
            documentType: .registration,
            vehicles: [vehicle]
        )
        modelContext.insert(doc)
        try modelContext.save()

        modelContext.delete(vehicle)
        try modelContext.save()
        Document.purgeOrphans(in: modelContext)

        let remaining = try modelContext.fetch(FetchDescriptor<Document>())
        XCTAssertTrue(remaining.isEmpty, "Document linked only to the deleted vehicle should be purged")
    }

    /// A document shared across two vehicles survives deletion of one of them —
    /// it still belongs to the other, so the orphan sweep must not reclaim it.
    @MainActor
    func testDeleteVehicle_KeepsDocumentStillLinkedToAnotherVehicle() throws {
        let vehicleA = Vehicle(make: "Ford", model: "F-150", year: 2021)
        let vehicleB = Vehicle(make: "Ford", model: "F-250", year: 2022)
        modelContext.insert(vehicleA)
        modelContext.insert(vehicleB)

        let doc = Document(
            data: Data(),
            fileName: "fleet-insurance.pdf",
            mimeType: "application/pdf",
            documentType: .insurance,
            vehicles: [vehicleA, vehicleB]
        )
        modelContext.insert(doc)
        try modelContext.save()

        modelContext.delete(vehicleA)
        try modelContext.save()
        Document.purgeOrphans(in: modelContext)

        let remaining = try modelContext.fetch(FetchDescriptor<Document>())
        XCTAssertEqual(remaining.count, 1, "Shared document must outlive one of its vehicles")
        XCTAssertEqual(remaining.first?.vehicles?.map(\.id), [vehicleB.id])
    }
}
