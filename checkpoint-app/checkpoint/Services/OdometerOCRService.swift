//
//  OdometerOCRService.swift
//  checkpoint
//
//  Vision framework-based OCR service for extracting mileage from odometer photos
//  All processing happens on-device for privacy
//

import os
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

    /// Metadata from a Vision text observation's bounding box
    struct ObservationMetadata {
        let boundingBox: CGRect
        let area: CGFloat
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

    private let logger = Logger(subsystem: "com.checkpoint.ocr", category: "OdometerOCR")

    private init() {}

    // MARK: - Public API

    /// Recognizes mileage from an odometer image using multi-image preprocessing
    /// - Parameters:
    ///   - image: UIImage of the odometer display
    ///   - currentMileage: Current vehicle mileage for prior-based scoring (nil uses original weights)
    /// - Returns: OCRResult containing the extracted mileage and confidence
    /// - Throws: OCRError if recognition fails
    func recognizeMileage(from image: UIImage, currentMileage: Int? = nil) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        // Convert UIImage orientation to CGImagePropertyOrientation for Vision
        // Access UIImage properties on MainActor to satisfy Swift 6 concurrency requirements
        let cgOrientation = await MainActor.run {
            CGImagePropertyOrientation(image.imageOrientation)
        }
        let orientationRawValue = await MainActor.run { image.imageOrientation.rawValue }
        logger.debug("Starting OCR, image orientation: \(orientationRawValue) -> cgOrientation: \(cgOrientation.rawValue)")

        // Preprocess image to get multiple enhanced versions
        let preprocessedImages = preprocessor.preprocess(cgImage)
        logger.debug("Preprocessing produced \(preprocessedImages.count) images")

        // Collect candidates from all preprocessed images
        var allCandidates: [(OCRResult, ObservationMetadata?)] = []
        var hasAnyObservations = false

        for preprocessed in preprocessedImages {
            do {
                let observations = try await performTextRecognition(
                    on: preprocessed.image,
                    orientation: cgOrientation
                )
                if !observations.isEmpty {
                    hasAnyObservations = true

                    // Log raw text from each preprocessing method
                    for obs in observations {
                        if let top = obs.topCandidates(1).first {
                            logger.debug("[\(preprocessed.method.rawValue)] raw: '\(top.string)' conf=\(top.confidence)")
                        }
                    }

                    let candidates = extractMileageCandidates(from: observations)
                    allCandidates.append(contentsOf: candidates)
                }
            } catch {
                continue
            }
        }

        guard hasAnyObservations else {
            throw OCRError.noTextFound
        }

        // Aggregate candidates: boost confidence for values found multiple times
        let aggregatedCandidates = aggregateCandidates(allCandidates)

        for (result, _) in aggregatedCandidates {
            logger.debug("Aggregated candidate: \(result.mileage) conf=\(result.confidence) raw='\(result.rawText)'")
        }

        // Trip meter discard: remove likely trip meter readings
        let filteredCandidates = Self.discardTripMeterReadings(aggregatedCandidates)

        guard let bestCandidate = selectBestCandidate(
            from: filteredCandidates,
            currentMileage: currentMileage,
            hasAreaData: allCandidates.contains { $0.1 != nil }
        ) else {
            throw OCRError.noValidMileageFound
        }

        // Validate the mileage is reasonable
        try validateMileage(bestCandidate.mileage)

        logger.debug("Selected best candidate: \(bestCandidate.mileage) conf=\(bestCandidate.confidence)")
        return bestCandidate
    }

    /// Aggregates candidates by boosting confidence for values found multiple times
    private func aggregateCandidates(_ candidates: [(OCRResult, ObservationMetadata?)]) -> [(OCRResult, ObservationMetadata?)] {
        var mileageCounts: [Int: Int] = [:]
        var mileageToEntry: [Int: (OCRResult, ObservationMetadata?)] = [:]

        for entry in candidates {
            let mileage = entry.0.mileage
            mileageCounts[mileage, default: 0] += 1
            if let existing = mileageToEntry[mileage] {
                if entry.0.confidence > existing.0.confidence {
                    mileageToEntry[mileage] = entry
                }
            } else {
                mileageToEntry[mileage] = entry
            }
        }

        return mileageToEntry.map { mileage, entry in
            let count = mileageCounts[mileage] ?? 1
            let boost = count > 1 ? multiImageConfidenceBoost * Float(count - 1) : 0
            let boostedConfidence = min(1.0, entry.0.confidence + boost)

            let boostedResult = OCRResult(
                mileage: entry.0.mileage,
                confidence: boostedConfidence,
                rawText: entry.0.rawText,
                detectedUnit: entry.0.detectedUnit
            )
            return (boostedResult, entry.1)
        }
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

            // Configure for accurate recognition (best for odometer readings)
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            // Filter out small text noise (minimum 2% of image height)
            request.minimumTextHeight = 0.02

            // Custom words to help recognize odometer-related text
            request.customWords = ["km", "mi", "miles", "KM", "MI", "ODO", "ODOMETER"]

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

    /// Extracts potential mileage values from recognized text observations (Phase 2: topCandidates(3))
    private func extractMileageCandidates(from observations: [VNRecognizedTextObservation]) -> [(OCRResult, ObservationMetadata?)] {
        var candidates: [(OCRResult, ObservationMetadata?)] = []

        // Collect all raw text for unit detection (still use top 1 for unit detection)
        let allText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        let detectedUnit = detectUnit(from: allText)

        for observation in observations {
            let topCandidatesList = observation.topCandidates(1)
            let metadata = ObservationMetadata(
                boundingBox: observation.boundingBox,
                area: observation.boundingBox.width * observation.boundingBox.height
            )

            for candidate in topCandidatesList {
                let text = candidate.string
                let confidence = candidate.confidence

                let numbers = Self.extractNumericSequences(from: text)

                for number in numbers {
                    if number >= minimumMileage && number <= maximumMileage {
                        candidates.append((
                            OCRResult(
                                mileage: number,
                                confidence: confidence,
                                rawText: text,
                                detectedUnit: detectedUnit
                            ),
                            metadata
                        ))
                    }
                }
            }
        }

        return candidates
    }

    /// Detects distance unit from OCR text
    private func detectUnit(from text: String) -> DistanceUnit? {
        let lowercased = text.lowercased()

        if lowercased.contains("km") || lowercased.contains("kilometer") {
            return .kilometers
        }

        if lowercased.contains("mi") || lowercased.contains("mile") {
            return .miles
        }

        return nil
    }

    // MARK: - Character Corrections (Phase 1)

    /// OCR character correction map: misread character → correct digit
    static let ocrCorrections: [Character: Character] = [
        // Zero misreads
        "O": "0", "o": "0", "Q": "0", "D": "0",
        // One misreads
        "l": "1", "I": "1", "i": "1", "|": "1",
        // Two misreads
        "Z": "2", "z": "2",
        // Five misreads
        "S": "5", "s": "5",
        // Six misreads
        "G": "6", "b": "6",
        // Eight misreads
        "B": "8",
        // Nine misreads
        "g": "9", "q": "9",
    ]

    /// Applies context-aware OCR character corrections to text.
    /// Only corrects characters within clusters that contain at least one real digit,
    /// preventing words like "ODO" from being corrupted to "000".
    static func applyClusterCorrections(_ text: String) -> String {
        var result: [Character] = []
        var cluster: [Character] = []
        var clusterHasRealDigit = false

        func flushCluster() {
            if clusterHasRealDigit {
                // Apply corrections within this cluster
                for ch in cluster {
                    if ch.isNumber {
                        result.append(ch)
                    } else if let corrected = ocrCorrections[ch] {
                        result.append(corrected)
                    } else {
                        result.append(ch)
                    }
                }
            } else {
                // No real digit — leave cluster untouched
                result.append(contentsOf: cluster)
            }
            cluster.removeAll()
            clusterHasRealDigit = false
        }

        for ch in text {
            let isDigit = ch.isNumber
            let isCorrectable = ocrCorrections[ch] != nil

            if isDigit || isCorrectable {
                if isDigit { clusterHasRealDigit = true }
                cluster.append(ch)
            } else {
                flushCluster()
                result.append(ch)
            }
        }
        flushCluster()

        return String(result)
    }

    /// Extracts numeric sequences from text, handling common odometer formats
    static func extractNumericSequences(from text: String) -> [Int] {
        var numbers: [Int] = []

        // Remove common separators
        let stripped = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")

        // Apply context-aware cluster corrections
        let cleanedText = applyClusterCorrections(stripped)

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

    // MARK: - Trip Meter Discard

    /// Discards likely trip meter readings when values differ by 10x or more
    static func discardTripMeterReadings(
        _ candidates: [(OCRResult, ObservationMetadata?)]
    ) -> [(OCRResult, ObservationMetadata?)] {
        guard candidates.count > 1 else { return candidates }

        let maxMileage = candidates.map { $0.0.mileage }.max() ?? 0
        guard maxMileage > 0 else { return candidates }

        let threshold = Double(maxMileage) * 0.5

        // Check if there's a 10x difference between any candidates
        let mileages = candidates.map { $0.0.mileage }
        let hasLargeDifference = mileages.contains { mileage in
            mileages.contains { other in
                other >= mileage * 10
            }
        }

        guard hasLargeDifference else { return candidates }

        return candidates.filter { Double($0.0.mileage) >= threshold }
    }

    // MARK: - Scoring

    /// Scores a candidate using multi-factor analysis
    /// When currentMileage is provided: digit 30%, range 15%, confidence 30%, prior 25%
    /// When area data is available: digit 25%, range 10%, confidence 25%, prior 25%, area 15%
    /// When neither is available: digit 40%, range 25%, confidence 35%
    static func scoreCandidate(
        _ candidate: OCRResult,
        currentMileage: Int? = nil,
        metadata: ObservationMetadata? = nil,
        maxArea: CGFloat? = nil
    ) -> Float {
        let digitCount = String(candidate.mileage).count

        let digitCountScore: Float = switch digitCount {
        case 6: 1.0
        case 5: 0.9
        case 7: 0.8
        case 4: 0.5
        case 3: 0.2
        default: 0.1
        }

        let rangeScore: Float = switch candidate.mileage {
        case 10_000...300_000: 1.0
        case 1_000..<10_000: 0.7
        case 300_001...500_000: 0.6
        case 500_001...999_999: 0.4
        case 100..<1_000: 0.3
        default: 0.1
        }

        // Prior score based on current mileage
        let priorScore: Float? = {
            guard let current = currentMileage else { return nil }
            let diff = candidate.mileage - current
            if diff < 0 { return 0.05 }
            if diff <= 5_000 { return 1.0 }
            if diff <= 20_000 { return 0.8 }
            if diff <= 50_000 { return 0.5 }
            return 0.2
        }()

        // Area score
        let areaScore: Float? = {
            guard let meta = metadata, let maxA = maxArea, maxA > 0 else { return nil }
            return Float(meta.area / maxA)
        }()

        // Weight selection
        if let prior = priorScore, let area = areaScore {
            // All factors available: digit 25%, range 10%, confidence 25%, prior 25%, area 15%
            return (digitCountScore * 0.25) + (rangeScore * 0.10) + (candidate.confidence * 0.25) + (prior * 0.25) + (area * 0.15)
        } else if let prior = priorScore {
            // Prior available, no area: digit 30%, range 15%, confidence 30%, prior 25%
            return (digitCountScore * 0.30) + (rangeScore * 0.15) + (candidate.confidence * 0.30) + (prior * 0.25)
        } else if let area = areaScore {
            // Area available, no prior: digit 30%, range 15%, confidence 25%, area 30%
            return (digitCountScore * 0.30) + (rangeScore * 0.15) + (candidate.confidence * 0.25) + (area * 0.30)
        } else {
            // Original weights
            return (digitCountScore * 0.40) + (rangeScore * 0.25) + (candidate.confidence * 0.35)
        }
    }

    /// Selects the best mileage candidate using multi-factor scoring
    private func selectBestCandidate(
        from candidates: [(OCRResult, ObservationMetadata?)],
        currentMileage: Int?,
        hasAreaData: Bool
    ) -> OCRResult? {
        guard !candidates.isEmpty else { return nil }

        let maxArea: CGFloat? = hasAreaData
            ? candidates.compactMap { $0.1?.area }.max()
            : nil

        let scored = candidates
            .map { entry in
                (
                    candidate: entry.0,
                    score: Self.scoreCandidate(
                        entry.0,
                        currentMileage: currentMileage,
                        metadata: entry.1,
                        maxArea: maxArea
                    )
                )
            }
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

// MARK: - UIImage Orientation to CGImagePropertyOrientation

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
