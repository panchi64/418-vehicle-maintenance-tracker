//
//  OdometerOCRService.swift
//  checkpoint
//
//  Vision framework-based OCR service for extracting mileage from odometer photos
//  All processing happens on-device for privacy
//

import UIKit
import Vision

/// Actor-based service for extracting mileage readings from odometer images
actor OdometerOCRService {

    // MARK: - Types

    /// Result of OCR mileage extraction
    struct OCRResult {
        /// Extracted mileage value
        let mileage: Int
        /// Confidence score from 0.0 to 1.0
        let confidence: Float
        /// Raw text that was recognized
        let rawText: String
        /// Detected distance unit from text (nil if no unit indicator found)
        let detectedUnit: DistanceUnit?

        /// Convenience initializer with optional detectedUnit (defaults to nil)
        init(mileage: Int, confidence: Float, rawText: String, detectedUnit: DistanceUnit? = nil) {
            self.mileage = mileage
            self.confidence = confidence
            self.rawText = rawText
            self.detectedUnit = detectedUnit
        }
    }

    /// Errors that can occur during OCR processing
    enum OCRError: Error, LocalizedError {
        case noTextFound
        case noValidMileageFound
        case imageProcessingFailed
        case invalidMileage(reason: String)

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return "No text could be recognized in the image"
            case .noValidMileageFound:
                return "No valid mileage number was found"
            case .imageProcessingFailed:
                return "Failed to process the image"
            case .invalidMileage(let reason):
                return "Invalid mileage: \(reason)"
            }
        }
    }

    // MARK: - Configuration

    /// Minimum reasonable mileage value
    private let minimumMileage = 0

    /// Maximum reasonable mileage (1 million miles)
    private let maximumMileage = 1_000_000

    /// Minimum confidence threshold for auto-acceptance
    static let highConfidenceThreshold: Float = 0.80

    /// Medium confidence threshold (suggest review)
    static let mediumConfidenceThreshold: Float = 0.50

    // MARK: - Shared Instance

    static let shared = OdometerOCRService()

    private init() {}

    // MARK: - Public API

    /// Recognizes mileage from an odometer image
    /// - Parameter image: UIImage of the odometer display
    /// - Returns: OCRResult containing the extracted mileage and confidence
    /// - Throws: OCRError if recognition fails
    func recognizeMileage(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        // Perform text recognition
        let observations = try await performTextRecognition(on: cgImage)

        guard !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        // Extract and validate mileage candidates
        let candidates = extractMileageCandidates(from: observations)

        guard let bestCandidate = selectBestCandidate(from: candidates) else {
            throw OCRError.noValidMileageFound
        }

        // Validate the mileage is reasonable
        try validateMileage(bestCandidate.mileage)

        return bestCandidate
    }

    // MARK: - Private Methods

    /// Performs Vision text recognition on the image
    private func performTextRecognition(on cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
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

            // Configure for accurate recognition (best for odometer readings)
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // Numbers don't need language correction
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Extracts potential mileage values from recognized text observations
    private func extractMileageCandidates(from observations: [VNRecognizedTextObservation]) -> [OCRResult] {
        var candidates: [OCRResult] = []

        // Collect all raw text for unit detection
        let allText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        let detectedUnit = detectUnit(from: allText)

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else {
                continue
            }

            let text = topCandidate.string
            let confidence = topCandidate.confidence

            // Extract numeric sequences from the text
            let numbers = extractNumericSequences(from: text)

            for number in numbers {
                // Filter out unreasonable values
                if number >= minimumMileage && number <= maximumMileage {
                    candidates.append(OCRResult(
                        mileage: number,
                        confidence: confidence,
                        rawText: text,
                        detectedUnit: detectedUnit
                    ))
                }
            }
        }

        return candidates
    }

    /// Detects distance unit from OCR text
    /// - Parameter text: Raw OCR text to scan for unit indicators
    /// - Returns: Detected DistanceUnit, or nil if no unit indicator found
    private func detectUnit(from text: String) -> DistanceUnit? {
        let lowercased = text.lowercased()

        // Check for kilometers indicators
        if lowercased.contains("km") || lowercased.contains("kilometer") {
            return .kilometers
        }

        // Check for miles indicators
        if lowercased.contains("mi") || lowercased.contains("mile") {
            return .miles
        }

        return nil
    }

    /// Extracts numeric sequences from text, handling common odometer formats
    private func extractNumericSequences(from text: String) -> [Int] {
        var numbers: [Int] = []

        // Remove common separators and clean the text
        let cleanedText = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0") // Common OCR mistake
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "l", with: "1") // Common OCR mistake
            .replacingOccurrences(of: "I", with: "1")

        // Pattern to match sequences of digits (3+ digits for mileage)
        let pattern = "[0-9]{3,}"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return numbers
        }

        let range = NSRange(cleanedText.startIndex..., in: cleanedText)
        let matches = regex.matches(in: cleanedText, range: range)

        for match in matches {
            if let range = Range(match.range, in: cleanedText) {
                let numberString = String(cleanedText[range])
                if let number = Int(numberString) {
                    numbers.append(number)
                }
            }
        }

        // Also try parsing the entire cleaned text as a number
        if let fullNumber = Int(cleanedText.filter { $0.isNumber }) {
            if !numbers.contains(fullNumber) {
                numbers.append(fullNumber)
            }
        }

        return numbers
    }

    /// Selects the best mileage candidate based on confidence and reasonableness
    private func selectBestCandidate(from candidates: [OCRResult]) -> OCRResult? {
        guard !candidates.isEmpty else { return nil }

        // Sort by confidence (highest first)
        let sorted = candidates.sorted { $0.confidence > $1.confidence }

        // Prefer candidates with typical mileage ranges (1000 - 500000)
        // but don't exclude others
        let preferred = sorted.filter { $0.mileage >= 1000 && $0.mileage <= 500_000 }

        return preferred.first ?? sorted.first
    }

    /// Validates that the mileage is within reasonable bounds
    private func validateMileage(_ mileage: Int) throws {
        if mileage < minimumMileage {
            throw OCRError.invalidMileage(reason: "Mileage cannot be negative")
        }

        if mileage > maximumMileage {
            throw OCRError.invalidMileage(reason: "Mileage exceeds maximum reasonable value")
        }
    }
}
