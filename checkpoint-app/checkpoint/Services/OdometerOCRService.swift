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

        // Phase 6: Detect text regions for focused recognition
        let regionOfInterest = await detectBestRegionOfInterest(in: cgImage)

        // Preprocess image to get multiple enhanced versions
        let preprocessedImages = preprocessor.preprocess(cgImage)

        // Collect candidates from all preprocessed images
        var allCandidates: [(OCRResult, ObservationMetadata?)] = []
        var hasAnyObservations = false

        for preprocessed in preprocessedImages {
            do {
                let observations = try await performTextRecognition(
                    on: preprocessed.image,
                    regionOfInterest: regionOfInterest
                )
                if !observations.isEmpty {
                    hasAnyObservations = true
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

        // Phase 3: Spatial filtering
        let spatiallyFiltered = Self.filterBySpatialPlausibility(allCandidates)

        // Aggregate candidates: boost confidence for values found multiple times
        let aggregatedCandidates = aggregateCandidates(spatiallyFiltered)

        // Phase 4: Trip meter discard
        let filteredCandidates = Self.discardTripMeterReadings(aggregatedCandidates)

        guard let bestCandidate = selectBestCandidate(
            from: filteredCandidates,
            currentMileage: currentMileage,
            hasAreaData: spatiallyFiltered.contains { $0.1 != nil }
        ) else {
            throw OCRError.noValidMileageFound
        }

        // Validate the mileage is reasonable
        try validateMileage(bestCandidate.mileage)

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

    // MARK: - Text Detection (Phase 6)

    /// Detects text regions in the image using VNDetectTextRectanglesRequest
    private func detectTextRegions(in cgImage: CGImage) async -> [CGRect] {
        await withCheckedContinuation { continuation in
            let request = VNDetectTextRectanglesRequest { request, _ in
                guard let results = request.results as? [VNTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let boxes = results.map { $0.boundingBox }
                    .sorted { ($0.width * $0.height) > ($1.width * $1.height) }
                continuation.resume(returning: boxes)
            }
            request.reportCharacterBoxes = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    /// Detects the best region of interest by finding the largest text region and expanding it
    private func detectBestRegionOfInterest(in cgImage: CGImage) async -> CGRect? {
        let regions = await detectTextRegions(in: cgImage)
        guard let largest = regions.first else { return nil }

        // Expand by 20% padding
        let padX = largest.width * 0.2
        let padY = largest.height * 0.2
        let expanded = CGRect(
            x: max(0, largest.origin.x - padX),
            y: max(0, largest.origin.y - padY),
            width: min(1.0, largest.width + padX * 2),
            height: min(1.0, largest.height + padY * 2)
        )
        // Clamp to normalized coordinates
        return CGRect(
            x: expanded.origin.x,
            y: expanded.origin.y,
            width: min(expanded.width, 1.0 - expanded.origin.x),
            height: min(expanded.height, 1.0 - expanded.origin.y)
        )
    }

    // MARK: - Private Methods

    /// Performs Vision text recognition on the image
    /// - Parameters:
    ///   - cgImage: The image to recognize text in
    ///   - regionOfInterest: Optional ROI in normalized coordinates (0-1). Falls back to full frame if nil.
    private func performTextRecognition(
        on cgImage: CGImage,
        regionOfInterest: CGRect? = nil
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

            // Phase 6: Apply region of interest if available
            if let roi = regionOfInterest {
                request.regionOfInterest = roi
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

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
            let topCandidatesList = observation.topCandidates(3)
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

    // MARK: - Spatial Filtering (Phase 3)

    /// Filters candidates by spatial plausibility based on bounding box data
    static func filterBySpatialPlausibility(
        _ candidates: [(OCRResult, ObservationMetadata?)]
    ) -> [(OCRResult, ObservationMetadata?)] {
        // Only filter if we have metadata
        let withMetadata = candidates.filter { $0.1 != nil }
        guard !withMetadata.isEmpty else { return candidates }

        // Discard observations with bounding box height < 3% of image
        let sizeFiltered = candidates.filter { entry in
            guard let meta = entry.1 else { return true } // Keep entries without metadata
            return meta.boundingBox.height >= 0.03
        }

        guard !sizeFiltered.isEmpty else { return candidates }

        // Cluster by centerY (tolerance 0.05), keep dominant band
        let withMeta = sizeFiltered.filter { $0.1 != nil }
        guard withMeta.count > 1 else { return sizeFiltered }

        // Group into Y-bands
        var bands: [[Int]] = []
        let sorted = withMeta.enumerated().sorted {
            ($0.element.1?.boundingBox.midY ?? 0) < ($1.element.1?.boundingBox.midY ?? 0)
        }

        for (idx, entry) in sorted {
            let centerY = entry.1?.boundingBox.midY ?? 0
            var placed = false
            for bandIdx in bands.indices {
                let bandCenterY = withMeta[bands[bandIdx][0]].1?.boundingBox.midY ?? 0
                if abs(centerY - bandCenterY) <= 0.05 {
                    bands[bandIdx].append(idx)
                    placed = true
                    break
                }
            }
            if !placed {
                bands.append([idx])
            }
        }

        // Find dominant band (most candidates)
        guard let dominantBand = bands.max(by: { $0.count < $1.count }) else {
            return sizeFiltered
        }
        let dominantIndices = Set(dominantBand)

        // Keep candidates from dominant band + those without metadata
        var result: [(OCRResult, ObservationMetadata?)] = []
        let sizeFilteredWithMeta = sizeFiltered.filter { $0.1 != nil }
        let sizeFilteredWithoutMeta = sizeFiltered.filter { $0.1 == nil }

        for (idx, entry) in sizeFilteredWithMeta.enumerated() {
            if dominantIndices.contains(idx) {
                result.append(entry)
            }
        }
        result.append(contentsOf: sizeFilteredWithoutMeta)

        return result.isEmpty ? sizeFiltered : result
    }

    // MARK: - Trip Meter Discard (Phase 4)

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

    // MARK: - Scoring (Phase 2 + Phase 3)

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
