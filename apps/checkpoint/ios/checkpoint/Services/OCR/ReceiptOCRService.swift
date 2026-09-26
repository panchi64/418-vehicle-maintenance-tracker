//
//  ReceiptOCRService.swift
//  checkpoint
//
//  Vision reading of receipts, invoices and scanned documents. All
//  processing happens on-device for privacy.
//
//  `RecognizeDocumentsRequest` (iOS 26) reads the page as a document — text
//  in reading order, tables with their rows, and the amounts and dates
//  Vision's data detectors find — into a `ReceiptScan`. Receipt READING
//  (`ReceiptExtractionService`) first runs `DetectLensSmudgeRequest` and
//  turns away a smudged or blurred capture before trusting any number in
//  it; attaching a receipt never does, since a blurry photo is still worth
//  keeping.
//

import DataDetection
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
        /// The structured reading the text came from.
        var scan: ReceiptScan?
    }

    /// Errors that can occur during OCR processing
    enum OCRError: Error, LocalizedError {
        case noTextFound
        case imageProcessingFailed
        /// The lens was smudged or the photo blurred: numbers read from it
        /// can't be trusted.
        case tooBlurry

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return L10n.cameraReceiptNoText
            case .imageProcessingFailed:
                return L10n.cameraReceiptProcessingFailed
            case .tooBlurry:
                return L10n.receiptTooBlurry
            }
        }
    }

    // MARK: - Shared Instance

    static let shared = ReceiptOCRService()

    /// Apple's suggested cut-off (`DetectLensSmudgeRequest` documentation):
    /// at or above it, the capture is probably smudged.
    static let smudgeThreshold: Float = 0.9

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
        let orientation = await MainActor.run { CGImagePropertyOrientation(image.imageOrientation) }
        let (scan, confidences) = try await read(cgImage, orientation: orientation, rejectingSmudged: false)
        let average = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Float(confidences.count)
        logger.debug("Extracted \(scan.lines.count) lines, avg confidence: \(average)")
        return OCRResult(text: scan.transcript, blockCount: scan.lines.count, averageConfidence: average, scan: scan)
    }

    /// Reads a receipt for its values, turning away a smudged capture first.
    func scan(_ image: CGImage, orientation: CGImagePropertyOrientation = .up) async throws -> ReceiptScan {
        try await read(image, orientation: orientation, rejectingSmudged: true).scan
    }

    // MARK: - Reading

    private func read(
        _ image: CGImage,
        orientation: CGImagePropertyOrientation,
        rejectingSmudged: Bool
    ) async throws -> (scan: ReceiptScan, confidences: [Float]) {
        if rejectingSmudged, try await isSmudged(image, orientation: orientation) {
            throw OCRError.tooBlurry
        }

        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.recognitionLanguages = [Locale.Language(identifier: "en-US"), Locale.Language(identifier: "es-ES")]
        request.textRecognitionOptions.useLanguageCorrection = true

        let documents: [DocumentObservation]
        do {
            documents = try await request.perform(on: image, orientation: orientation)
        } catch {
            logger.error("Document recognition failed: \(error.localizedDescription)")
            throw OCRError.imageProcessingFailed
        }

        var lines: [String] = []
        var tableRows: [[String]] = []
        var detected: [ReceiptScan.DetectedValue] = []
        var confidences: [Float] = []

        for observation in documents {
            let text = observation.document.text
            let offset = lines.count
            let transcript = text.transcript
            lines += ReceiptScan(transcript: transcript).lines
            confidences += text.lines.map(\.confidence)

            for table in observation.document.tables {
                for row in table.rows {
                    let cells = row.map { $0.content.text.transcript.trimmingCharacters(in: .whitespacesAndNewlines) }
                    if cells.contains(where: { !$0.isEmpty }) { tableRows.append(cells) }
                }
            }

            for found in text.detectedData {
                let line = found.match.range
                    .flatMap { Self.lineIndex(of: $0.lowerBound, in: transcript) }
                    .map { offset + $0 }
                switch found.match.details {
                case .moneyAmount(let money):
                    detected.append(.money(money.amount, line: line))
                case .calendarEvent(let event):
                    if let start = event.startDate { detected.append(.date(start, line: line)) }
                default:
                    break
                }
            }
        }

        guard !lines.isEmpty else { throw OCRError.noTextFound }
        return (ReceiptScan(lines: lines, tableRows: tableRows, detected: detected), confidences)
    }

    /// Which non-blank line of `transcript` holds `index`, or nil when the
    /// index isn't inside it.
    private static func lineIndex(of index: String.Index, in transcript: String) -> Int? {
        guard index >= transcript.startIndex, index <= transcript.endIndex else { return nil }
        return transcript[..<index]
            .components(separatedBy: .newlines)
            .dropLast()
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .count
    }

    /// Whether the capture is probably smudged or blurred. Devices that
    /// can't run the check (it needs an A14 or later) pass.
    private func isSmudged(_ image: CGImage, orientation: CGImagePropertyOrientation) async throws -> Bool {
        do {
            let observation = try await DetectLensSmudgeRequest().perform(on: image, orientation: orientation)
            return observation.confidence >= Self.smudgeThreshold
        } catch {
            logger.debug("Smudge check unavailable: \(error.localizedDescription)")
            return false
        }
    }
}
