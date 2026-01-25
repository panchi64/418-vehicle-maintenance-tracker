//
//  ServiceAttachment.swift
//  checkpoint
//
//  SwiftData model for service attachments (photos, PDFs)
//

import Foundation
import SwiftData
import UIKit

@Model
final class ServiceAttachment: Identifiable {
    var id: UUID = UUID()
    var serviceLog: ServiceLog?

    @Attribute(.externalStorage)
    var data: Data?

    var fileName: String
    var mimeType: String  // "image/jpeg", "image/png", "application/pdf"
    var createdAt: Date

    /// Computed property to check if this is an image
    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    /// Computed property to check if this is a PDF
    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    /// Get thumbnail image for display (for images only)
    var thumbnailImage: UIImage? {
        guard isImage, let data = data else { return nil }
        return UIImage(data: data)
    }

    /// Compressed image data (max 800x800)
    static func compressedImageData(from image: UIImage, maxSize: CGFloat = 800) -> Data? {
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

        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    init(
        serviceLog: ServiceLog? = nil,
        data: Data? = nil,
        fileName: String,
        mimeType: String,
        createdAt: Date = Date.now
    ) {
        self.serviceLog = serviceLog
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.createdAt = createdAt
    }

    /// Create from UIImage
    static func fromImage(_ image: UIImage, fileName: String = "photo.jpg", serviceLog: ServiceLog? = nil) -> ServiceAttachment? {
        guard let data = compressedImageData(from: image) else { return nil }
        return ServiceAttachment(
            serviceLog: serviceLog,
            data: data,
            fileName: fileName,
            mimeType: "image/jpeg"
        )
    }

    /// Create from PDF data
    static func fromPDF(_ data: Data, fileName: String = "document.pdf", serviceLog: ServiceLog? = nil) -> ServiceAttachment {
        return ServiceAttachment(
            serviceLog: serviceLog,
            data: data,
            fileName: fileName,
            mimeType: "application/pdf"
        )
    }
}
