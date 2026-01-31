//
//  ReceiptOCRService.swift
//  checkpoint
//
//  Vision framework-based OCR service for extracting text from receipts and invoices
//  All processing happens on-device for privacy
//

import os
import UIKit
import Vision

/// Actor-based service for extracting text from receipt and invoice images
actor ReceiptOCRService {

    // MARK: - Types

    /// Result of OCR text extraction
    struct OCRResult {
        /// All extracted text from the receipt
        let text: String
        /// Number of text blocks recognized
        let blockCount: Int
        /// Average confidence score across all recognized text
        let averageConfidence: Float
    }

    /// Errors that can occur during OCR processing
    enum OCRError: Error, LocalizedError {
        case noTextFound
        case imageProcessingFailed

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return "No text could be recognized in the image"
            case .imageProcessingFailed:
                return "Failed to process the image"
            }
        }
    }

    // MARK: - Shared Instance

    static let shared = ReceiptOCRService()

    private let logger = Logger(subsystem: "com.checkpoint.ocr", category: "ReceiptOCR")

    private init() {}

    // MARK: - Public API

    /// Extracts text from a receipt or invoice image
    /// - Parameter image: UIImage of the receipt/invoice
    /// - Returns: OCRResult containing the extracted text and metadata
    /// - Throws: OCRError if recognition fails
    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        // Convert UIImage orientation to CGImagePropertyOrientation for Vision
        let cgOrientation = await MainActor.run {
            CGImagePropertyOrientation(image.imageOrientation)
        }

        logger.debug("Starting receipt OCR")

        let observations = try await performTextRecognition(on: cgImage, orientation: cgOrientation)

        guard !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        // Sort observations by vertical position (top to bottom) for reading order
        let sortedObservations = observations.sorted { first, second in
            // VNRecognizedTextObservation uses normalized coordinates where (0,0) is bottom-left
            // So higher y values are at the top of the image
            first.boundingBox.origin.y > second.boundingBox.origin.y
        }

        // Extract text from each observation
        var textLines: [String] = []
        var totalConfidence: Float = 0
        var confidenceCount = 0

        for observation in sortedObservations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }

            textLines.append(topCandidate.string)
            totalConfidence += topCandidate.confidence
            confidenceCount += 1
        }

        guard !textLines.isEmpty else {
            throw OCRError.noTextFound
        }

        let averageConfidence = confidenceCount > 0 ? totalConfidence / Float(confidenceCount) : 0

        logger.debug("Extracted \(textLines.count) lines, avg confidence: \(averageConfidence)")

        return OCRResult(
            text: textLines.joined(separator: "\n"),
            blockCount: textLines.count,
            averageConfidence: averageConfidence
        )
    }

    // MARK: - Private Methods

    /// Performs Vision text recognition on the image
    private func performTextRecognition(
        on cgImage: CGImage,
        orientation: CGImagePropertyOrientation = .up
    ) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: observations)
            }

            // Configure for accurate recognition with language correction
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "es-ES"]

            // Use latest revision for best accuracy (iOS 16+)
            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
