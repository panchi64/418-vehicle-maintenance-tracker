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

    /// Confidence boost for values found in multiple preprocessed images
    private let multiImageConfidenceBoost: Float = 0.15

    // MARK: - Shared Instance

    static let shared = OdometerOCRService()

    /// Image preprocessor for enhanced OCR
    private let preprocessor = OdometerImagePreprocessor()

    private init() {}

    // MARK: - Public API

    /// Recognizes mileage from an odometer image using multi-image preprocessing
    /// - Parameter image: UIImage of the odometer display
    /// - Returns: OCRResult containing the extracted mileage and confidence
    /// - Throws: OCRError if recognition fails
    func recognizeMileage(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        // Preprocess image to get multiple enhanced versions
        let preprocessedImages = preprocessor.preprocess(cgImage)

        // Collect candidates from all preprocessed images
        var allCandidates: [OCRResult] = []
        var hasAnyObservations = false

        for preprocessed in preprocessedImages {
            do {
                let observations = try await performTextRecognition(on: preprocessed.image)
                if !observations.isEmpty {
                    hasAnyObservations = true
                    let candidates = extractMileageCandidates(from: observations)
                    allCandidates.append(contentsOf: candidates)
                }
            } catch {
                // Continue with other preprocessed images if one fails
                continue
            }
        }

        guard hasAnyObservations else {
            throw OCRError.noTextFound
        }

        // Aggregate candidates: boost confidence for values found multiple times
        let aggregatedCandidates = aggregateCandidates(allCandidates)

        guard let bestCandidate = selectBestCandidate(from: aggregatedCandidates) else {
            throw OCRError.noValidMileageFound
        }

        // Validate the mileage is reasonable
        try validateMileage(bestCandidate.mileage)

        return bestCandidate
    }

    /// Aggregates candidates by boosting confidence for values found multiple times
    private func aggregateCandidates(_ candidates: [OCRResult]) -> [OCRResult] {
        // Count occurrences of each mileage value
        var mileageCounts: [Int: Int] = [:]
        var mileageToCandidate: [Int: OCRResult] = [:]

        for candidate in candidates {
            mileageCounts[candidate.mileage, default: 0] += 1
            // Keep the candidate with highest confidence for each mileage value
            if let existing = mileageToCandidate[candidate.mileage] {
                if candidate.confidence > existing.confidence {
                    mileageToCandidate[candidate.mileage] = candidate
                }
            } else {
                mileageToCandidate[candidate.mileage] = candidate
            }
        }

        // Create aggregated results with boosted confidence for repeated values
        return mileageToCandidate.map { mileage, candidate in
            let count = mileageCounts[mileage] ?? 1
            let boost = count > 1 ? multiImageConfidenceBoost * Float(count - 1) : 0
            let boostedConfidence = min(1.0, candidate.confidence + boost)

            return OCRResult(
                mileage: candidate.mileage,
                confidence: boostedConfidence,
                rawText: candidate.rawText,
                detectedUnit: candidate.detectedUnit
            )
        }
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

            // Filter out small text noise (minimum 2% of image height)
            request.minimumTextHeight = 0.02

            // Custom words to help recognize odometer-related text
            request.customWords = ["km", "mi", "miles", "KM", "MI", "ODO", "ODOMETER"]

            // Use latest revision for best accuracy (iOS 16+)
            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            }

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

        // Common OCR character misreads for digits
        // Each tuple: (misread character, correct digit)
        let corrections: [(String, String)] = [
            // Zero misreads
            ("O", "0"), ("o", "0"), ("Q", "0"), ("D", "0"),
            // One misreads
            ("l", "1"), ("I", "1"), ("i", "1"), ("|", "1"),
            // Two misreads
            ("Z", "2"), ("z", "2"),
            // Five misreads
            ("S", "5"), ("s", "5"),
            // Six misreads
            ("G", "6"), ("b", "6"),
            // Eight misreads
            ("B", "8"),
            // Nine misreads
            ("g", "9"), ("q", "9"),
        ]

        // Remove common separators and apply character corrections
        var cleanedText = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")

        for (misread, correct) in corrections {
            cleanedText = cleanedText.replacingOccurrences(of: misread, with: correct)
        }

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

    /// Scores a candidate using multi-factor analysis
    /// Weighs digit count (40%), range plausibility (25%), and OCR confidence (35%)
    private func scoreCandidate(_ candidate: OCRResult) -> Float {
        let digitCount = String(candidate.mileage).count

        // Digit count score (5-7 digits typical for odometers)
        let digitCountScore: Float = switch digitCount {
        case 6: 1.0   // Most common (100,000 - 999,999)
        case 5: 0.9   // Common (10,000 - 99,999)
        case 7: 0.8   // High mileage (1,000,000+)
        case 4: 0.5   // Low mileage (1,000 - 9,999)
        case 3: 0.2   // Very low (100 - 999)
        default: 0.1  // Unlikely (1-2 digits or 8+)
        }

        // Range score - typical odometer values
        let rangeScore: Float = switch candidate.mileage {
        case 10_000...300_000: 1.0    // Most common range
        case 1_000..<10_000: 0.7      // Low but valid
        case 300_001...500_000: 0.6   // High mileage
        case 500_001...999_999: 0.4   // Very high mileage
        case 100..<1_000: 0.3         // Very low
        default: 0.1                   // Unlikely
        }

        // Weighted combination: digit count matters most for filtering OCR errors
        return (digitCountScore * 0.40) + (rangeScore * 0.25) + (candidate.confidence * 0.35)
    }

    /// Selects the best mileage candidate using multi-factor scoring
    private func selectBestCandidate(from candidates: [OCRResult]) -> OCRResult? {
        guard !candidates.isEmpty else { return nil }

        // Score each candidate and sort by score (highest first)
        let scored = candidates
            .map { (candidate: $0, score: scoreCandidate($0)) }
            .sorted { $0.score > $1.score }

        return scored.first?.candidate
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
