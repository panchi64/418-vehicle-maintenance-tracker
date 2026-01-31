//
//  ServiceAttachment.swift
//  checkpoint
//
//  SwiftData model for service attachments (photos, PDFs)
//

import Foundation
import SwiftData
import UIKit
import PDFKit

@Model
final class ServiceAttachment: Identifiable {
    var id: UUID = UUID()
    var serviceLog: ServiceLog?

    @Attribute(.externalStorage)
    var data: Data?

    @Attribute(.externalStorage)
    var thumbnailData: Data?

    var fileName: String = ""
    var mimeType: String = "image/jpeg"  // "image/jpeg", "image/png", "application/pdf"
    var createdAt: Date = Date.now

    /// OCR-extracted text from receipt/invoice (nil if not scanned)
    var extractedText: String?

    /// Computed property to check if this is an image
    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    /// Computed property to check if this is a PDF
    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    /// Get thumbnail image for display (images and PDFs)
    var thumbnailImage: UIImage? {
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        }
        // Backward compat: derive from full data for images without cached thumbnail
        guard isImage, let data = data else { return nil }
        return UIImage(data: data)
    }

    /// Generate a 120x120 JPEG thumbnail from image data or PDF first page
    static func generateThumbnailData(from data: Data, mimeType: String, maxSize: CGFloat = 120) -> Data? {
        if mimeType.hasPrefix("image/") {
            guard let image = UIImage(data: data) else { return nil }
            return thumbnailImageData(from: image, maxSize: maxSize)
        } else if mimeType == "application/pdf" {
            guard let pdfImage = renderPDFFirstPage(from: data, size: CGSize(width: maxSize, height: maxSize)) else { return nil }
            return pdfImage.jpegData(compressionQuality: 0.7)
        }
        return nil
    }

    /// Create a thumbnail from an image at scale 1.0 (pixel-accurate sizing)
    private static func thumbnailImageData(from image: UIImage, maxSize: CGFloat) -> Data? {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: min(size.width, maxSize), height: min(size.width, maxSize) / aspectRatio)
        } else {
            newSize = CGSize(width: min(size.height, maxSize) * aspectRatio, height: min(size.height, maxSize))
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.7)
    }

    /// Render the first page of a PDF as a UIImage
    private static func renderPDFFirstPage(from data: Data, size: CGSize) -> UIImage? {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return nil }

        let pageBounds = page.bounds(for: .mediaBox)
        let aspectRatio = pageBounds.width / pageBounds.height

        var renderSize: CGSize
        if aspectRatio > 1 {
            renderSize = CGSize(width: size.width, height: size.width / aspectRatio)
        } else {
            renderSize = CGSize(width: size.height * aspectRatio, height: size.height)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))

            ctx.cgContext.translateBy(x: 0, y: renderSize.height)
            ctx.cgContext.scaleBy(x: renderSize.width / pageBounds.width,
                                 y: -renderSize.height / pageBounds.height)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }

    /// Compressed image data (max 800x800)
    static func compressedImageData(from image: UIImage, maxSize: CGFloat = 800, quality: CGFloat = 0.8) -> Data? {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: min(size.width, maxSize), height: min(size.width, maxSize) / aspectRatio)
        } else {
            newSize = CGSize(width: min(size.height, maxSize) * aspectRatio, height: min(size.height, maxSize))
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: quality)
    }

    init(
        serviceLog: ServiceLog? = nil,
        data: Data? = nil,
        thumbnailData: Data? = nil,
        fileName: String,
        mimeType: String,
        createdAt: Date = Date.now,
        extractedText: String? = nil
    ) {
        self.serviceLog = serviceLog
        self.data = data
        self.thumbnailData = thumbnailData
        self.fileName = fileName
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.extractedText = extractedText
    }

    /// Create from UIImage
    static func fromImage(_ image: UIImage, fileName: String = "photo.jpg", serviceLog: ServiceLog? = nil) -> ServiceAttachment? {
        guard let data = compressedImageData(from: image) else { return nil }
        let thumbnail = generateThumbnailData(from: data, mimeType: "image/jpeg")
        return ServiceAttachment(
            serviceLog: serviceLog,
            data: data,
            thumbnailData: thumbnail,
            fileName: fileName,
            mimeType: "image/jpeg"
        )
    }

    /// Create from PDF data
    static func fromPDF(_ data: Data, fileName: String = "document.pdf", serviceLog: ServiceLog? = nil) -> ServiceAttachment {
        let thumbnail = generateThumbnailData(from: data, mimeType: "application/pdf")
        return ServiceAttachment(
            serviceLog: serviceLog,
            data: data,
            thumbnailData: thumbnail,
            fileName: fileName,
            mimeType: "application/pdf"
        )
    }
}
