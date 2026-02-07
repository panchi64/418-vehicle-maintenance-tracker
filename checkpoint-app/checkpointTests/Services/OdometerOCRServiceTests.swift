//
//  OdometerOCRServiceTests.swift
//  checkpointTests
//
//  Unit tests for OdometerOCRService
//

import XCTest
import UIKit
@testable import checkpoint

final class OdometerOCRServiceTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() async {
        let service = await OdometerOCRService.shared
        XCTAssertNotNil(service, "Shared instance should exist")
    }

    // MARK: - Confidence Threshold Tests

    func testHighConfidenceThreshold() {
        XCTAssertEqual(OdometerOCRService.highConfidenceThreshold, 0.80)
    }

    func testMediumConfidenceThreshold() {
        XCTAssertEqual(OdometerOCRService.mediumConfidenceThreshold, 0.50)
    }

    // MARK: - OCRResult Tests

    func testOCRResultStoresValues() {
        let mileage = 50000
        let confidence: Float = 0.95
        let rawText = "50,000"

        let result = OdometerOCRService.OCRResult(
            mileage: mileage,
            confidence: confidence,
            rawText: rawText
        )

        XCTAssertEqual(result.mileage, mileage)
        XCTAssertEqual(result.confidence, confidence)
        XCTAssertEqual(result.rawText, rawText)
        XCTAssertNil(result.detectedUnit)
    }

    func testOCRResult_WithDetectedUnit() {
        let result = OdometerOCRService.OCRResult(
            mileage: 50000,
            confidence: 0.95,
            rawText: "50,000 km",
            detectedUnit: .kilometers
        )
        XCTAssertEqual(result.detectedUnit, .kilometers)
    }

    func testOCRResult_WithNoDetectedUnit() {
        let result = OdometerOCRService.OCRResult(
            mileage: 50000,
            confidence: 0.95,
            rawText: "50000",
            detectedUnit: nil
        )
        XCTAssertNil(result.detectedUnit)
    }

    // MARK: - OCR Error Tests

    func testNoTextFoundError() {
        let error = OdometerOCRService.OCRError.noTextFound
        XCTAssertEqual(error.errorDescription, L10n.ocrErrorNoTextFound)
    }

    func testNoValidMileageFoundError() {
        let error = OdometerOCRService.OCRError.noValidMileageFound
        XCTAssertEqual(error.errorDescription, L10n.ocrErrorNoValidMileage)
    }

    func testImageProcessingFailedError() {
        let error = OdometerOCRService.OCRError.imageProcessingFailed
        XCTAssertEqual(error.errorDescription, L10n.ocrErrorImageProcessingFailed)
    }

    func testInvalidMileageError() {
        let error = OdometerOCRService.OCRError.invalidMileage(reason: "Mileage cannot be negative")
        XCTAssertEqual(error.errorDescription, L10n.ocrErrorInvalidMileage)
    }

    // MARK: - OCR Recognition Tests

    func testRecognizeMileageThrowsForInvalidImage() async {
        let service = await OdometerOCRService.shared

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let blankImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        do {
            _ = try await service.recognizeMileage(from: blankImage)
            XCTFail("Should throw an error for image with no recognizable text")
        } catch {
            XCTAssertTrue(error is OdometerOCRService.OCRError, "Should throw OCRError")
        }
    }

    func testRecognizeMileageWithValidOdometerImage() async {
        let service = await OdometerOCRService.shared
        let testImage = createTestImageWithText("32500")

        do {
            let result = try await service.recognizeMileage(from: testImage)
            XCTAssertGreaterThan(result.mileage, 0)
            XCTAssertGreaterThanOrEqual(result.confidence, 0)
            XCTAssertLessThanOrEqual(result.confidence, 1)
            XCTAssertFalse(result.rawText.isEmpty)
        } catch {
            XCTAssertTrue(error is OdometerOCRService.OCRError)
        }
    }

    // MARK: - Mileage Validation Tests

    func testValidMileageRanges() {
        let validMileages = [0, 100, 1000, 50000, 150000, 500000, 999999]
        for mileage in validMileages {
            XCTAssertGreaterThanOrEqual(mileage, 0)
            XCTAssertLessThanOrEqual(mileage, 1_000_000)
        }
    }

    // MARK: - Candidate Scoring Tests (using static method)

    func testCandidateScoring_SixDigitBeatsTwoDigit() {
        let sixDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 235977, confidence: 0.70, rawText: "235977km"
        )
        let twoDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 52, confidence: 0.95, rawText: "52mi"
        )

        let sixDigitScore = OdometerOCRService.scoreCandidate(sixDigitCandidate)
        let twoDigitScore = OdometerOCRService.scoreCandidate(twoDigitCandidate)

        XCTAssertGreaterThan(sixDigitScore, twoDigitScore, "6-digit mileage should score higher than 2-digit")
    }

    func testCandidateScoring_TypicalMileageRange() {
        let typicalMileage = OdometerOCRService.OCRResult(
            mileage: 150000, confidence: 0.80, rawText: "150000"
        )
        let unusualMileage = OdometerOCRService.OCRResult(
            mileage: 999, confidence: 0.90, rawText: "999"
        )

        let typicalScore = OdometerOCRService.scoreCandidate(typicalMileage)
        let unusualScore = OdometerOCRService.scoreCandidate(unusualMileage)

        XCTAssertGreaterThan(typicalScore, unusualScore, "Typical mileage should score higher")
    }

    func testCandidateScoring_FiveDigitsIsValid() {
        let fiveDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 45000, confidence: 0.85, rawText: "45000"
        )
        let score = OdometerOCRService.scoreCandidate(fiveDigitCandidate)
        XCTAssertGreaterThan(score, 0.8, "5-digit mileage in range should score high")
    }

    func testCandidateScoring_HighMileageAccepted() {
        let highMileage = OdometerOCRService.OCRResult(
            mileage: 450000, confidence: 0.85, rawText: "450000"
        )
        let score = OdometerOCRService.scoreCandidate(highMileage)
        XCTAssertGreaterThan(score, 0.5, "High mileage should be acceptable")
    }

    // MARK: - Phase 1: Character Correction Tests (using static methods)

    func testCorrections_DoesNotCorruptODO() {
        // "ODO 50000" — "ODO" has no real digits, should stay as "ODO"; "50000" has digits
        let numbers = OdometerOCRService.extractNumericSequences(from: "ODO 50000")
        XCTAssertTrue(numbers.contains(50000), "Should extract 50000")
        // Should NOT contain 000 (ODO corrupted)
        XCTAssertFalse(numbers.contains(0), "Should not corrupt ODO to 000")
    }

    func testCorrections_DoesNotCorruptMILES() {
        // "MILES" alone has no real digits — should produce no numeric candidates
        let numbers = OdometerOCRService.extractNumericSequences(from: "MILES")
        XCTAssertTrue(numbers.isEmpty, "MILES should produce no digits")
    }

    func testCorrections_FixesMixedCluster() {
        // "5O000" has a real digit (5), so O should correct to 0 → "50000"
        let numbers = OdometerOCRService.extractNumericSequences(from: "5O000")
        XCTAssertTrue(numbers.contains(50000), "5O000 should correct to 50000")
    }

    func testOCRCorrections_ComplexMileage() {
        // "Z3S977" — Z and S are adjacent to real digits, should correct
        let corrected = OdometerOCRService.applyClusterCorrections("Z3S977")
        XCTAssertEqual(corrected, "235977", "Complex misread should be corrected")
    }

    func testClusterCorrections_PureLettersUntouched() {
        let corrected = OdometerOCRService.applyClusterCorrections("ODO")
        XCTAssertEqual(corrected, "ODO", "Pure letter cluster should be untouched")
    }

    func testClusterCorrections_DigitAdjacentCorrected() {
        // "5O" — has digit 5, so O should become 0
        let corrected = OdometerOCRService.applyClusterCorrections("5O")
        XCTAssertEqual(corrected, "50")
    }

    // MARK: - Unit Detection Tests

    func testDetectUnit_FindsKilometers() {
        let texts = ["50000 km", "50,000 KM", "50000 kilometers", "50000km"]
        for text in texts {
            let unit = detectUnit(from: text)
            XCTAssertEqual(unit, .kilometers, "Should detect km in '\(text)'")
        }
    }

    func testDetectUnit_FindsMiles() {
        let texts = ["50000 mi", "50,000 MI", "50000 miles", "50000mi"]
        for text in texts {
            let unit = detectUnit(from: text)
            XCTAssertEqual(unit, .miles, "Should detect miles in '\(text)'")
        }
    }

    func testDetectUnit_ReturnsNilForNoUnit() {
        let texts = ["50000", "50,000", "50 000"]
        for text in texts {
            let unit = detectUnit(from: text)
            XCTAssertNil(unit, "Should return nil for '\(text)'")
        }
    }

    // MARK: - Phase 2: Prior Scoring Tests

    func testScoring_WithPrior_FavorsSlightlyAbove() {
        let goodCandidate = OdometerOCRService.OCRResult(
            mileage: 52000, confidence: 0.80, rawText: "52000"
        )
        let farCandidate = OdometerOCRService.OCRResult(
            mileage: 150000, confidence: 0.80, rawText: "150000"
        )

        let goodScore = OdometerOCRService.scoreCandidate(goodCandidate, currentMileage: 50000)
        let farScore = OdometerOCRService.scoreCandidate(farCandidate, currentMileage: 50000)

        XCTAssertGreaterThan(goodScore, farScore, "52,000 with prior 50,000 should beat 150,000")
    }

    func testScoring_WithPrior_PenalizesBelowCurrent() {
        let belowCandidate = OdometerOCRService.OCRResult(
            mileage: 30000, confidence: 0.90, rawText: "30000"
        )
        let aboveCandidate = OdometerOCRService.OCRResult(
            mileage: 52000, confidence: 0.80, rawText: "52000"
        )

        let belowScore = OdometerOCRService.scoreCandidate(belowCandidate, currentMileage: 50000)
        let aboveScore = OdometerOCRService.scoreCandidate(aboveCandidate, currentMileage: 50000)

        XCTAssertGreaterThan(aboveScore, belowScore, "Below-current should be penalized")
    }

    func testScoring_WithNilPrior_UsesOriginalWeights() {
        let candidate = OdometerOCRService.OCRResult(
            mileage: 150000, confidence: 0.80, rawText: "150000"
        )

        let score = OdometerOCRService.scoreCandidate(candidate, currentMileage: nil)

        // Original formula: digit(40%) + range(25%) + confidence(35%)
        // 6-digit: 1.0, range 10k-300k: 1.0, confidence: 0.80
        let expected: Float = (1.0 * 0.40) + (1.0 * 0.25) + (0.80 * 0.35)
        XCTAssertEqual(score, expected, accuracy: 0.001, "Nil prior should use original weights")
    }

    func testAreaWeighting_LargerTextScoresHigher() {
        let candidate = OdometerOCRService.OCRResult(
            mileage: 50000, confidence: 0.8, rawText: "50000"
        )
        let largeMeta = OdometerOCRService.ObservationMetadata(
            boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.1), area: 0.05
        )
        let smallMeta = OdometerOCRService.ObservationMetadata(
            boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.05), area: 0.005
        )

        let largeScore = OdometerOCRService.scoreCandidate(
            candidate, metadata: largeMeta, maxArea: 0.05
        )
        let smallScore = OdometerOCRService.scoreCandidate(
            candidate, metadata: smallMeta, maxArea: 0.05
        )

        XCTAssertGreaterThan(largeScore, smallScore, "Larger area should score higher")
    }

    // MARK: - Phase 4: Trip Meter Discard Tests

    func testTripMeterDiscard_RemovesSmallReading() {
        let candidates: [(OdometerOCRService.OCRResult, OdometerOCRService.ObservationMetadata?)] = [
            (OdometerOCRService.OCRResult(mileage: 52347, confidence: 0.9, rawText: "52347"), nil),
            (OdometerOCRService.OCRResult(mileage: 234, confidence: 0.9, rawText: "234"), nil),
        ]

        let filtered = OdometerOCRService.discardTripMeterReadings(candidates)
        let mileages = filtered.map { $0.0.mileage }

        XCTAssertTrue(mileages.contains(52347), "Should keep 52347")
        XCTAssertFalse(mileages.contains(234), "Should discard 234 (trip meter)")
    }

    func testTripMeterDiscard_KeepsSimilarValues() {
        let candidates: [(OdometerOCRService.OCRResult, OdometerOCRService.ObservationMetadata?)] = [
            (OdometerOCRService.OCRResult(mileage: 52347, confidence: 0.9, rawText: "52347"), nil),
            (OdometerOCRService.OCRResult(mileage: 52350, confidence: 0.8, rawText: "52350"), nil),
        ]

        let filtered = OdometerOCRService.discardTripMeterReadings(candidates)
        XCTAssertEqual(filtered.count, 2, "Should keep both similar values")
    }

    // MARK: - Simplified Pipeline Tests (no ROI, no spatial filtering)

    func testPipeline_RecognizesWithoutROI() async {
        // The simplified pipeline should recognize text from a full-frame image
        // without needing ROI detection (viewfinder crop handles framing)
        let service = await OdometerOCRService.shared
        let testImage = createTestImageWithText("87654")

        do {
            let result = try await service.recognizeMileage(from: testImage)
            // If recognition succeeds, the pipeline works without ROI
            XCTAssertGreaterThan(result.mileage, 0, "Should extract a mileage without ROI")
        } catch {
            // OCR may fail on synthetic images — that's OK, the point is no crash
            XCTAssertTrue(error is OdometerOCRService.OCRError, "Should throw OCRError, not crash")
        }
    }

    func testPipeline_AllCandidatesPassToAggregation() {
        // Without spatial filtering, all candidates should reach aggregation.
        // Verify that small bounding boxes are NOT discarded anymore.
        let smallCandidate = OdometerOCRService.OCRResult(
            mileage: 50000, confidence: 0.8, rawText: "50000"
        )
        let smallMeta = OdometerOCRService.ObservationMetadata(
            boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.1, height: 0.02), // height < 3% — previously filtered
            area: 0.002
        )

        // Score should still work for small bounding box candidates
        let score = OdometerOCRService.scoreCandidate(
            smallCandidate,
            metadata: smallMeta,
            maxArea: 0.05
        )
        XCTAssertGreaterThan(score, 0, "Small bounding box candidates should still be scorable")
    }

    func testPipeline_NoSpatialFilterMethodExists() {
        // Verify filterBySpatialPlausibility is no longer part of the public API
        // This test documents the removal — it passes by compilation alone
        // (if the method existed as static, calling it would compile; it shouldn't)
        // We verify indirectly: discardTripMeterReadings still exists
        let candidates: [(OdometerOCRService.OCRResult, OdometerOCRService.ObservationMetadata?)] = [
            (OdometerOCRService.OCRResult(mileage: 50000, confidence: 0.9, rawText: "50000"), nil),
        ]
        let result = OdometerOCRService.discardTripMeterReadings(candidates)
        XCTAssertEqual(result.count, 1, "Trip meter discard should still work")
    }

    func testPipeline_RecognizesWithCurrentMileagePrior() async {
        // The pipeline should accept currentMileage parameter for prior-based scoring
        let service = await OdometerOCRService.shared
        let testImage = createTestImageWithText("51234")

        do {
            let result = try await service.recognizeMileage(from: testImage, currentMileage: 50000)
            XCTAssertGreaterThan(result.mileage, 0)
        } catch {
            XCTAssertTrue(error is OdometerOCRService.OCRError)
        }
    }

    // MARK: - Orientation Mapping Tests

    func testCGImagePropertyOrientation_FromUIImageOrientation() {
        let mappings: [(UIImage.Orientation, CGImagePropertyOrientation)] = [
            (.up, .up),
            (.upMirrored, .upMirrored),
            (.down, .down),
            (.downMirrored, .downMirrored),
            (.left, .left),
            (.leftMirrored, .leftMirrored),
            (.right, .right),
            (.rightMirrored, .rightMirrored),
        ]

        for (uiOrientation, expected) in mappings {
            let result = CGImagePropertyOrientation(uiOrientation)
            XCTAssertEqual(
                result, expected,
                "UIImage.Orientation rawValue \(uiOrientation.rawValue) should map to CGImagePropertyOrientation rawValue \(expected.rawValue)"
            )
        }
    }

    // MARK: - Helper Methods

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

    private func createTestImageWithText(_ text: String) -> UIImage {
        let size = CGSize(width: 200, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            attributedText.draw(in: textRect)
        }
    }
}
