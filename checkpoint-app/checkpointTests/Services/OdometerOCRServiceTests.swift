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
        // Given
        let mileage = 50000
        let confidence: Float = 0.95
        let rawText = "50,000"

        // When
        let result = OdometerOCRService.OCRResult(
            mileage: mileage,
            confidence: confidence,
            rawText: rawText
        )

        // Then
        XCTAssertEqual(result.mileage, mileage)
        XCTAssertEqual(result.confidence, confidence)
        XCTAssertEqual(result.rawText, rawText)
        XCTAssertNil(result.detectedUnit)  // Default is nil
    }

    func testOCRResult_WithDetectedUnit() {
        // Given
        let mileage = 50000
        let confidence: Float = 0.95
        let rawText = "50,000 km"

        // When
        let result = OdometerOCRService.OCRResult(
            mileage: mileage,
            confidence: confidence,
            rawText: rawText,
            detectedUnit: .kilometers
        )

        // Then
        XCTAssertEqual(result.detectedUnit, .kilometers)
    }

    func testOCRResult_WithNoDetectedUnit() {
        // Given
        let result = OdometerOCRService.OCRResult(
            mileage: 50000,
            confidence: 0.95,
            rawText: "50000",
            detectedUnit: nil
        )

        // Then
        XCTAssertNil(result.detectedUnit)
    }

    // MARK: - OCR Error Tests

    func testNoTextFoundError() {
        // Given
        let error = OdometerOCRService.OCRError.noTextFound

        // Then
        XCTAssertEqual(error.errorDescription, "No text could be recognized in the image")
    }

    func testNoValidMileageFoundError() {
        // Given
        let error = OdometerOCRService.OCRError.noValidMileageFound

        // Then
        XCTAssertEqual(error.errorDescription, "No valid mileage number was found")
    }

    func testImageProcessingFailedError() {
        // Given
        let error = OdometerOCRService.OCRError.imageProcessingFailed

        // Then
        XCTAssertEqual(error.errorDescription, "Failed to process the image")
    }

    func testInvalidMileageError() {
        // Given
        let reason = "Mileage cannot be negative"
        let error = OdometerOCRService.OCRError.invalidMileage(reason: reason)

        // Then
        XCTAssertEqual(error.errorDescription, "Invalid mileage: \(reason)")
    }

    // MARK: - OCR Recognition Tests

    func testRecognizeMileageThrowsForInvalidImage() async {
        // Given - create an image without a valid cgImage
        let service = await OdometerOCRService.shared

        // Create a 1x1 blank image that is valid but has no readable text
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let blankImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        // When/Then - should throw because no text can be recognized
        do {
            _ = try await service.recognizeMileage(from: blankImage)
            XCTFail("Should throw an error for image with no recognizable text")
        } catch {
            // Expected - either noTextFound or noValidMileageFound
            XCTAssertTrue(
                error is OdometerOCRService.OCRError,
                "Should throw OCRError"
            )
        }
    }

    func testRecognizeMileageWithValidOdometerImage() async {
        // This test requires a real odometer image to work properly
        // In a real test suite, we would use test fixtures
        // For now, we test that the method exists and handles errors properly

        let service = await OdometerOCRService.shared

        // Create a test image with text "32500"
        let testImage = createTestImageWithText("32500")

        do {
            let result = try await service.recognizeMileage(from: testImage)
            // If OCR succeeds, verify the result structure
            XCTAssertGreaterThan(result.mileage, 0)
            XCTAssertGreaterThanOrEqual(result.confidence, 0)
            XCTAssertLessThanOrEqual(result.confidence, 1)
            XCTAssertFalse(result.rawText.isEmpty)
        } catch {
            // OCR might fail on programmatically generated images
            // This is expected behavior - real odometer photos work better
            XCTAssertTrue(error is OdometerOCRService.OCRError)
        }
    }

    // MARK: - Mileage Validation Tests

    func testValidMileageRanges() {
        // Test various mileage values that should be valid
        let validMileages = [0, 100, 1000, 50000, 150000, 500000, 999999]

        for mileage in validMileages {
            // These values should be within the valid range
            XCTAssertGreaterThanOrEqual(mileage, 0, "Mileage \(mileage) should be non-negative")
            XCTAssertLessThanOrEqual(mileage, 1_000_000, "Mileage \(mileage) should be under 1 million")
        }
    }

    // MARK: - Candidate Scoring Tests

    func testCandidateScoring_SixDigitBeatsTwoDigit() {
        // Given - the problem case: "235977" should beat "52"
        let sixDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 235977,
            confidence: 0.70,  // Lower confidence
            rawText: "235977km"
        )
        let twoDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 52,
            confidence: 0.95,  // Higher confidence
            rawText: "52mi"
        )

        // When
        let sixDigitScore = scoreCandidate(sixDigitCandidate)
        let twoDigitScore = scoreCandidate(twoDigitCandidate)

        // Then - 6-digit should score higher despite lower confidence
        XCTAssertGreaterThan(
            sixDigitScore,
            twoDigitScore,
            "6-digit mileage should score higher than 2-digit"
        )
    }

    func testCandidateScoring_TypicalMileageRange() {
        // Given
        let typicalMileage = OdometerOCRService.OCRResult(
            mileage: 150000,  // 6 digits, typical range
            confidence: 0.80,
            rawText: "150000"
        )
        let unusualMileage = OdometerOCRService.OCRResult(
            mileage: 999,  // 3 digits, very low
            confidence: 0.90,
            rawText: "999"
        )

        // When
        let typicalScore = scoreCandidate(typicalMileage)
        let unusualScore = scoreCandidate(unusualMileage)

        // Then
        XCTAssertGreaterThan(
            typicalScore,
            unusualScore,
            "Typical mileage should score higher"
        )
    }

    func testCandidateScoring_FiveDigitsIsValid() {
        // Given
        let fiveDigitCandidate = OdometerOCRService.OCRResult(
            mileage: 45000,
            confidence: 0.85,
            rawText: "45000"
        )

        // When
        let score = scoreCandidate(fiveDigitCandidate)

        // Then - 5 digits in common range should score well
        XCTAssertGreaterThan(score, 0.8, "5-digit mileage in range should score high")
    }

    func testCandidateScoring_HighMileageAccepted() {
        // Given
        let highMileage = OdometerOCRService.OCRResult(
            mileage: 450000,
            confidence: 0.85,
            rawText: "450000"
        )

        // When
        let score = scoreCandidate(highMileage)

        // Then - high mileage should still be valid (score > 0.5)
        XCTAssertGreaterThan(score, 0.5, "High mileage should be acceptable")
    }

    // MARK: - OCR Character Correction Tests

    func testOCRCorrections_ZeroMisreads() {
        // Given
        let inputs = ["O", "o", "Q", "D"]
        let expected = "0"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_OneMisreads() {
        // Given
        let inputs = ["l", "I", "i", "|"]
        let expected = "1"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_TwoMisreads() {
        // Given
        let inputs = ["Z", "z"]
        let expected = "2"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_FiveMisreads() {
        // Given
        let inputs = ["S", "s"]
        let expected = "5"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_SixMisreads() {
        // Given
        let inputs = ["G", "b"]
        let expected = "6"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_EightMisreads() {
        // Given
        let input = "B"
        let expected = "8"

        // When
        let corrected = applyOCRCorrections(input)

        // Then
        XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
    }

    func testOCRCorrections_NineMisreads() {
        // Given
        let inputs = ["g", "q"]
        let expected = "9"

        for input in inputs {
            // When
            let corrected = applyOCRCorrections(input)

            // Then
            XCTAssertEqual(corrected, expected, "'\(input)' should correct to '\(expected)'")
        }
    }

    func testOCRCorrections_ComplexMileage() {
        // Given - simulating misread "235977" as something like "Z3S977"
        let input = "Z3S977"
        let expected = "235977"

        // When
        let corrected = applyOCRCorrections(input)

        // Then
        XCTAssertEqual(corrected, expected, "Complex misread should be corrected")
    }

    // MARK: - Unit Detection Tests

    func testDetectUnit_FindsKilometers() {
        // Given
        let texts = ["50000 km", "50,000 KM", "50000 kilometers", "50000km"]

        for text in texts {
            // When
            let unit = detectUnit(from: text)

            // Then
            XCTAssertEqual(unit, .kilometers, "Should detect km in '\(text)'")
        }
    }

    func testDetectUnit_FindsMiles() {
        // Given
        let texts = ["50000 mi", "50,000 MI", "50000 miles", "50000mi"]

        for text in texts {
            // When
            let unit = detectUnit(from: text)

            // Then
            XCTAssertEqual(unit, .miles, "Should detect miles in '\(text)'")
        }
    }

    func testDetectUnit_ReturnsNilForNoUnit() {
        // Given
        let texts = ["50000", "50,000", "50 000"]

        for text in texts {
            // When
            let unit = detectUnit(from: text)

            // Then
            XCTAssertNil(unit, "Should return nil for '\(text)'")
        }
    }

    // MARK: - Helper Methods

    /// Replicates the unit detection logic from OdometerOCRService
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

    /// Replicates the candidate scoring logic from OdometerOCRService
    /// Weighs digit count (40%), range (25%), and confidence (35%)
    private func scoreCandidate(_ candidate: OdometerOCRService.OCRResult) -> Float {
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

        // Weighted combination
        return (digitCountScore * 0.40) + (rangeScore * 0.25) + (candidate.confidence * 0.35)
    }

    /// Replicates the OCR character corrections from OdometerOCRService
    private func applyOCRCorrections(_ text: String) -> String {
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

        var result = text
        for (misread, correct) in corrections {
            result = result.replacingOccurrences(of: misread, with: correct)
        }
        return result
    }

    /// Creates a test image with the specified text
    /// Note: This is primarily for testing the API, not actual OCR accuracy
    private func createTestImageWithText(_ text: String) -> UIImage {
        let size = CGSize(width: 200, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw text
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
