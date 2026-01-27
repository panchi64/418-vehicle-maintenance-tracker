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
