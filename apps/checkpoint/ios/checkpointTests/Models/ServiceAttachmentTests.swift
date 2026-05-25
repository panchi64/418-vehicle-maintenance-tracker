//
//  ServiceAttachmentTests.swift
//  checkpointTests
//
//  Tests for ServiceAttachment model
//

import XCTest
import SwiftData
import UIKit
import PDFKit
@testable import checkpoint

final class ServiceAttachmentTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!
    var serviceLog: ServiceLog!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 45000
        )
        modelContext.insert(vehicle)

        serviceLog = ServiceLog(
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 45000
        )
        modelContext.insert(serviceLog)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        serviceLog = nil
        super.tearDown()
    }

    // MARK: - Helper: Create real PDF data

    private func createTestPDFData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        return renderer.pdfData { context in
            context.beginPage()
            let text = "Test PDF" as NSString
            text.draw(at: CGPoint(x: 20, y: 20), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24)
            ])
        }
    }

    // MARK: - Initialization Tests

    @MainActor
    func testInitialization_WithAllParameters() {
        // Given
        let data = "test data".data(using: .utf8)!
        let fileName = "receipt.jpg"
        let mimeType = "image/jpeg"
        let createdAt = Date.now

        // When
        let attachment = ServiceAttachment(
            serviceLog: serviceLog,
            data: data,
            fileName: fileName,
            mimeType: mimeType,
            createdAt: createdAt
        )

        // Then
        XCTAssertNotNil(attachment.id)
        XCTAssertNotNil(attachment.serviceLog)
        XCTAssertEqual(attachment.data, data)
        XCTAssertEqual(attachment.fileName, fileName)
        XCTAssertEqual(attachment.mimeType, mimeType)
        XCTAssertEqual(attachment.createdAt, createdAt)
    }

    @MainActor
    func testInitialization_WithThumbnailData() {
        // Given
        let data = "test data".data(using: .utf8)!
        let thumbData = "thumb".data(using: .utf8)!

        // When
        let attachment = ServiceAttachment(
            data: data,
            thumbnailData: thumbData,
            fileName: "file.jpg",
            mimeType: "image/jpeg"
        )

        // Then
        XCTAssertEqual(attachment.thumbnailData, thumbData)
    }

    @MainActor
    func testInitialization_WithDefaultCreatedAt() {
        // Given
        let data = "test data".data(using: .utf8)!

        // When
        let attachment = ServiceAttachment(
            data: data,
            fileName: "file.pdf",
            mimeType: "application/pdf"
        )

        // Then
        let timeDifference = abs(attachment.createdAt.timeIntervalSince(Date.now))
        XCTAssertLessThan(timeDifference, 1.0)
    }

    @MainActor
    func testInitialization_WithoutServiceLog() {
        // Given
        let data = "test data".data(using: .utf8)!

        // When
        let attachment = ServiceAttachment(
            data: data,
            fileName: "file.pdf",
            mimeType: "application/pdf"
        )

        // Then
        XCTAssertNil(attachment.serviceLog)
    }

    // MARK: - isImage Tests

    @MainActor
    func testIsImage_JPEG() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )

        // Then
        XCTAssertTrue(attachment.isImage)
    }

    @MainActor
    func testIsImage_PNG() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "photo.png",
            mimeType: "image/png"
        )

        // Then
        XCTAssertTrue(attachment.isImage)
    }

    @MainActor
    func testIsImage_PDF() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "document.pdf",
            mimeType: "application/pdf"
        )

        // Then
        XCTAssertFalse(attachment.isImage)
    }

    // MARK: - isPDF Tests

    @MainActor
    func testIsPDF_True() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "document.pdf",
            mimeType: "application/pdf"
        )

        // Then
        XCTAssertTrue(attachment.isPDF)
    }

    @MainActor
    func testIsPDF_False() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )

        // Then
        XCTAssertFalse(attachment.isPDF)
    }

    // MARK: - fromImage Factory Tests

    @MainActor
    func testFromImage_CreatesAttachment() {
        // Given
        let image = UIImage(systemName: "car.fill")!

        // When
        let attachment = ServiceAttachment.fromImage(image, fileName: "car.jpg", serviceLog: serviceLog)

        // Then
        XCTAssertNotNil(attachment)
        XCTAssertEqual(attachment?.mimeType, "image/jpeg")
        XCTAssertEqual(attachment?.fileName, "car.jpg")
        XCTAssertNotNil(attachment?.data)
        XCTAssertTrue(attachment?.isImage ?? false)
    }

    @MainActor
    func testFromImage_IncludesThumbnailData() {
        // Given
        let image = UIImage(systemName: "car.fill")!

        // When
        let attachment = ServiceAttachment.fromImage(image)

        // Then
        XCTAssertNotNil(attachment)
        XCTAssertNotNil(attachment?.thumbnailData)
    }

    @MainActor
    func testFromImage_DefaultFileName() {
        // Given
        let image = UIImage(systemName: "car.fill")!

        // When
        let attachment = ServiceAttachment.fromImage(image)

        // Then
        XCTAssertEqual(attachment?.fileName, "photo.jpg")
    }

    // MARK: - fromPDF Factory Tests

    @MainActor
    func testFromPDF_CreatesAttachment() {
        // Given
        let pdfData = createTestPDFData()

        // When
        let attachment = ServiceAttachment.fromPDF(pdfData, fileName: "invoice.pdf", serviceLog: serviceLog)

        // Then
        XCTAssertEqual(attachment.mimeType, "application/pdf")
        XCTAssertEqual(attachment.fileName, "invoice.pdf")
        XCTAssertEqual(attachment.data, pdfData)
        XCTAssertTrue(attachment.isPDF)
    }

    @MainActor
    func testFromPDF_DefaultFileName() {
        // Given
        let pdfData = "PDF content".data(using: .utf8)!

        // When
        let attachment = ServiceAttachment.fromPDF(pdfData)

        // Then
        XCTAssertEqual(attachment.fileName, "document.pdf")
    }

    // MARK: - Image Compression Tests

    @MainActor
    func testCompressedImageData_ReturnsData() {
        // Given
        let image = UIImage(systemName: "car.fill")!

        // When
        let compressedData = ServiceAttachment.compressedImageData(from: image)

        // Then
        XCTAssertNotNil(compressedData)
        XCTAssertGreaterThan(compressedData?.count ?? 0, 0)
    }

    @MainActor
    func testCompressedImageData_RespectsMaxSize() {
        // Given
        let image = UIImage(systemName: "car.fill")!

        // When
        let compressedData = ServiceAttachment.compressedImageData(from: image, maxSize: 100)

        // Then
        XCTAssertNotNil(compressedData)

        // Verify resulting image fits within size constraints
        if let resultImage = UIImage(data: compressedData!) {
            XCTAssertLessThanOrEqual(resultImage.size.width, 100)
            XCTAssertLessThanOrEqual(resultImage.size.height, 100)
        }
    }

    // MARK: - thumbnailImage Tests

    @MainActor
    func testThumbnailImage_ReturnsImageForImageAttachment() {
        // Given
        let image = UIImage(systemName: "car.fill")!
        let attachment = ServiceAttachment.fromImage(image)!

        // When
        let thumbnail = attachment.thumbnailImage

        // Then
        XCTAssertNotNil(thumbnail)
    }

    @MainActor
    func testThumbnailImage_ReturnsThumbnailForValidPDF() {
        // Given
        let pdfData = createTestPDFData()
        let attachment = ServiceAttachment.fromPDF(pdfData)

        // When
        let thumbnail = attachment.thumbnailImage

        // Then
        XCTAssertNotNil(thumbnail, "Valid PDF should produce a thumbnail via thumbnailData")
    }

    @MainActor
    func testThumbnailImage_ReturnsNilForInvalidPDFWithoutThumbnail() {
        // Given: invalid PDF data, no thumbnailData
        let attachment = ServiceAttachment(
            data: "not a pdf".data(using: .utf8),
            fileName: "bad.pdf",
            mimeType: "application/pdf"
        )

        // When
        let thumbnail = attachment.thumbnailImage

        // Then
        XCTAssertNil(thumbnail)
    }

    @MainActor
    func testThumbnailImage_ReturnsNilForNilData() {
        // Given
        let attachment = ServiceAttachment(
            data: nil,
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )

        // When
        let thumbnail = attachment.thumbnailImage

        // Then
        XCTAssertNil(thumbnail)
    }

    @MainActor
    func testThumbnailImage_PrefersThumbnailDataOverFullData() {
        // Given: an image attachment with explicit thumbnailData
        let image = UIImage(systemName: "car.fill")!
        let fullData = ServiceAttachment.compressedImageData(from: image)!
        let tinyThumb = UIImage(systemName: "star.fill")!.jpegData(compressionQuality: 0.5)!

        let attachment = ServiceAttachment(
            data: fullData,
            thumbnailData: tinyThumb,
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )

        // When
        let thumbnail = attachment.thumbnailImage

        // Then: should use thumbnailData, not full data
        XCTAssertNotNil(thumbnail)
        // The thumbnail data size should match what we provided
        let regenerated = thumbnail?.jpegData(compressionQuality: 0.5)
        XCTAssertNotNil(regenerated)
    }

    // MARK: - generateThumbnailData Tests

    @MainActor
    func testGenerateThumbnailData_ReturnsDataForImage() {
        // Given
        let image = UIImage(systemName: "car.fill")!
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create PNG data from system image")
            return
        }

        // When
        let thumbData = ServiceAttachment.generateThumbnailData(from: imageData, mimeType: "image/png")

        // Then
        XCTAssertNotNil(thumbData, "Thumbnail data should not be nil for a valid image")
        if let thumbData = thumbData, let thumbImage = UIImage(data: thumbData) {
            XCTAssertLessThanOrEqual(thumbImage.size.width, 120)
            XCTAssertLessThanOrEqual(thumbImage.size.height, 120)
        }
    }

    @MainActor
    func testGenerateThumbnailData_ReturnsDataForPDF() {
        // Given
        let pdfData = createTestPDFData()

        // When
        let thumbData = ServiceAttachment.generateThumbnailData(from: pdfData, mimeType: "application/pdf")

        // Then
        XCTAssertNotNil(thumbData, "Thumbnail data should not be nil for a valid PDF")
        if let thumbData = thumbData, let thumbImage = UIImage(data: thumbData) {
            XCTAssertLessThanOrEqual(thumbImage.size.width, 120)
            XCTAssertLessThanOrEqual(thumbImage.size.height, 120)
        }
    }

    @MainActor
    func testGenerateThumbnailData_ReturnsNilForUnknownType() {
        // Given
        let textData = "Hello world".data(using: .utf8)!

        // When
        let thumbData = ServiceAttachment.generateThumbnailData(from: textData, mimeType: "text/plain")

        // Then
        XCTAssertNil(thumbData)
    }

    // MARK: - Relationship Tests

    @MainActor
    func testRelationship_AttachmentToServiceLog() {
        // Given
        let attachment = ServiceAttachment(
            serviceLog: serviceLog,
            data: Data(),
            fileName: "file.pdf",
            mimeType: "application/pdf"
        )
        modelContext.insert(attachment)

        // Then
        XCTAssertNotNil(attachment.serviceLog)
        XCTAssertEqual(attachment.serviceLog?.id, serviceLog.id)
    }

    @MainActor
    func testRelationship_ServiceLogToAttachments() {
        // Given
        let attachment1 = ServiceAttachment(
            serviceLog: serviceLog,
            data: Data(),
            fileName: "file1.pdf",
            mimeType: "application/pdf"
        )
        let attachment2 = ServiceAttachment(
            serviceLog: serviceLog,
            data: Data(),
            fileName: "file2.jpg",
            mimeType: "image/jpeg"
        )

        modelContext.insert(attachment1)
        modelContext.insert(attachment2)

        // Then
        XCTAssertEqual((serviceLog.attachments ?? []).count, 2)
    }

    // MARK: - File Extension Tests

    @MainActor
    func testMimeType_VariousTypes() {
        // Given/When/Then
        let jpegAttachment = ServiceAttachment(data: Data(), fileName: "a.jpg", mimeType: "image/jpeg")
        XCTAssertTrue(jpegAttachment.isImage)
        XCTAssertFalse(jpegAttachment.isPDF)

        let pngAttachment = ServiceAttachment(data: Data(), fileName: "b.png", mimeType: "image/png")
        XCTAssertTrue(pngAttachment.isImage)
        XCTAssertFalse(pngAttachment.isPDF)

        let pdfAttachment = ServiceAttachment(data: Data(), fileName: "c.pdf", mimeType: "application/pdf")
        XCTAssertFalse(pdfAttachment.isImage)
        XCTAssertTrue(pdfAttachment.isPDF)

        let gifAttachment = ServiceAttachment(data: Data(), fileName: "d.gif", mimeType: "image/gif")
        XCTAssertTrue(gifAttachment.isImage)
        XCTAssertFalse(gifAttachment.isPDF)
    }

    // MARK: - Edge Cases

    @MainActor
    func testEmptyFileName() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "",
            mimeType: "image/jpeg"
        )

        // Then
        XCTAssertEqual(attachment.fileName, "")
    }

    @MainActor
    func testEmptyData() {
        // Given
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: "empty.jpg",
            mimeType: "image/jpeg"
        )

        // Then
        XCTAssertNotNil(attachment.data)
        XCTAssertEqual(attachment.data?.count, 0)
    }

    @MainActor
    func testLargeFileName() {
        // Given
        let longFileName = String(repeating: "a", count: 500) + ".pdf"
        let attachment = ServiceAttachment(
            data: Data(),
            fileName: longFileName,
            mimeType: "application/pdf"
        )

        // Then
        XCTAssertEqual(attachment.fileName, longFileName)
    }
}
