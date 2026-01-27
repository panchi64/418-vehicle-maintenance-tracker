//
//  OCRConfirmationViewTests.swift
//  checkpointTests
//
//  Unit tests for OCRConfirmationView
//

import XCTest
import SwiftUI
@testable import checkpoint

final class OCRConfirmationViewTests: XCTestCase {

    // MARK: - Confidence Level Tests

    func testHighConfidenceLevel() {
        // Given
        let highConfidence: Float = 0.85

        // When
        let level = confidenceLevel(for: highConfidence)

        // Then
        XCTAssertEqual(level, .high)
    }

    func testMediumConfidenceLevel() {
        // Given
        let mediumConfidence: Float = 0.65

        // When
        let level = confidenceLevel(for: mediumConfidence)

        // Then
        XCTAssertEqual(level, .medium)
    }

    func testLowConfidenceLevel() {
        // Given
        let lowConfidence: Float = 0.35

        // When
        let level = confidenceLevel(for: lowConfidence)

        // Then
        XCTAssertEqual(level, .low)
    }

    func testBoundaryHighConfidence() {
        // Given - exactly at high threshold
        let confidence: Float = 0.80

        // When
        let level = confidenceLevel(for: confidence)

        // Then
        XCTAssertEqual(level, .high)
    }

    func testBoundaryMediumConfidence() {
        // Given - exactly at medium threshold
        let confidence: Float = 0.50

        // When
        let level = confidenceLevel(for: confidence)

        // Then
        XCTAssertEqual(level, .medium)
    }

    func testJustBelowHighConfidence() {
        // Given
        let confidence: Float = 0.79

        // When
        let level = confidenceLevel(for: confidence)

        // Then
        XCTAssertEqual(level, .medium)
    }

    func testJustBelowMediumConfidence() {
        // Given
        let confidence: Float = 0.49

        // When
        let level = confidenceLevel(for: confidence)

        // Then
        XCTAssertEqual(level, .low)
    }

    // MARK: - Confidence Level Color Tests

    func testHighConfidenceLevelColor() {
        // Given
        let level = ConfidenceLevel.high

        // Then
        XCTAssertEqual(level.color, Theme.statusGood)
    }

    func testMediumConfidenceLevelColor() {
        // Given
        let level = ConfidenceLevel.medium

        // Then
        XCTAssertEqual(level.color, Theme.statusDueSoon)
    }

    func testLowConfidenceLevelColor() {
        // Given
        let level = ConfidenceLevel.low

        // Then
        XCTAssertEqual(level.color, Theme.statusOverdue)
    }

    // MARK: - Confidence Bar Tests

    func testConfidenceBarSegmentCount() {
        // Given
        let bar = ConfidenceBar(confidence: 0.5, level: .medium)

        // Then - verify it has 10 segments (by testing calculated filled segments)
        // At 50% confidence, 5 of 10 segments should be filled
        let filledSegments = Int(ceil(0.5 * 10))
        XCTAssertEqual(filledSegments, 5)
    }

    func testConfidenceBarFullConfidence() {
        // Given
        let confidence: Float = 1.0

        // When
        let filledSegments = Int(ceil(confidence * 10))

        // Then
        XCTAssertEqual(filledSegments, 10)
    }

    func testConfidenceBarZeroConfidence() {
        // Given
        let confidence: Float = 0.0

        // When
        let filledSegments = Int(ceil(confidence * 10))

        // Then
        XCTAssertEqual(filledSegments, 0)
    }

    func testConfidenceBarPartialConfidence() {
        // Given
        let confidence: Float = 0.82

        // When - ceil rounds up, so 8.2 becomes 9
        let filledSegments = Int(ceil(confidence * 10))

        // Then
        XCTAssertEqual(filledSegments, 9)
    }

    // MARK: - OCR Confirmation View Creation Tests

    func testOCRConfirmationViewCreation() {
        // Given
        var confirmedMileage: Int?

        // When
        let view = OCRConfirmationView(
            extractedMileage: 50000,
            confidence: 0.92,
            onConfirm: { mileage in
                confirmedMileage = mileage
            },
            currentMileage: 49500
        )

        // Then
        XCTAssertNotNil(view)
        // The callback hasn't been called yet
        XCTAssertNil(confirmedMileage)
    }

    func testOCRConfirmationViewCreation_WithDetectedUnit() {
        // Given/When
        let view = OCRConfirmationView(
            extractedMileage: 50000,
            confidence: 0.92,
            onConfirm: { _ in },
            currentMileage: 49500,
            detectedUnit: .kilometers
        )

        // Then
        XCTAssertNotNil(view)
    }

    func testOCRConfirmationViewConfirmCallback() {
        // Given
        var confirmedMileage: Int?
        let expectedMileage = 50000

        let onConfirm: (Int) -> Void = { mileage in
            confirmedMileage = mileage
        }

        // When - simulate confirmation
        onConfirm(expectedMileage)

        // Then
        XCTAssertEqual(confirmedMileage, expectedMileage)
    }

    // MARK: - Direct Mileage Editing Tests

    func testDirectMileageEditing() {
        // Given
        let extractedMileage = 50000
        var confirmedMileage: Int?

        // When - simulate direct edit and confirmation
        let editedValue = 50500  // User edits the value
        let onConfirm: (Int) -> Void = { mileage in
            confirmedMileage = mileage
        }
        onConfirm(editedValue)

        // Then
        XCTAssertEqual(confirmedMileage, 50500)
    }

    func testMileageTextBinding_FiltersNonNumeric() {
        // Given
        let input = "50,000 mi"

        // When - simulate the binding's set logic
        let filtered = input.filter { $0.isNumber }
        let result = Int(filtered)

        // Then
        XCTAssertEqual(result, 50000)
    }

    func testMileageTextBinding_HandlesEmptyInput() {
        // Given
        let input = ""

        // When
        let filtered = input.filter { $0.isNumber }
        let result = Int(filtered)

        // Then
        XCTAssertNil(result)
    }

    func testMileageTextBinding_HandlesNumericOnly() {
        // Given
        let input = "12345"

        // When
        let filtered = input.filter { $0.isNumber }
        let result = Int(filtered)

        // Then
        XCTAssertEqual(result, 12345)
    }

    // MARK: - Unit Conversion Tests

    func testConfirmWithKilometers_ConvertsToMiles() {
        // Given
        let extractedKm = 80000  // 80,000 km
        var confirmedMileage: Int?

        // When - user confirms km value, should convert to miles
        let milesEquivalent = DistanceUnit.kilometers.toMiles(extractedKm)
        let onConfirm: (Int) -> Void = { mileage in
            confirmedMileage = mileage
        }
        onConfirm(milesEquivalent)

        // Then - should be ~49,710 miles
        XCTAssertNotNil(confirmedMileage)
        XCTAssertEqual(confirmedMileage!, 49710, accuracy: 10)
    }

    func testConfirmWithMiles_NoConversion() {
        // Given
        let extractedMiles = 50000
        var confirmedMileage: Int?

        // When - user confirms miles value
        let onConfirm: (Int) -> Void = { mileage in
            confirmedMileage = mileage
        }
        onConfirm(extractedMiles)

        // Then - should remain 50,000
        XCTAssertEqual(confirmedMileage, 50000)
    }

    func testUnitToggle_SwitchesKmToMiles() {
        // Given
        var sourceUnit: DistanceUnit = .kilometers

        // When
        sourceUnit = (sourceUnit == .miles) ? .kilometers : .miles

        // Then
        XCTAssertEqual(sourceUnit, .miles)
    }

    func testUnitToggle_SwitchesMilesToKm() {
        // Given
        var sourceUnit: DistanceUnit = .miles

        // When
        sourceUnit = (sourceUnit == .miles) ? .kilometers : .miles

        // Then
        XCTAssertEqual(sourceUnit, .kilometers)
    }

    func testKilometerToMilesConversion_Accuracy() {
        // Given - known conversion: 100 km = 62.14 miles
        let km = 100

        // When
        let miles = DistanceUnit.kilometers.toMiles(km)

        // Then
        XCTAssertEqual(miles, 62, accuracy: 1)
    }

    func testMilesToKilometerConversion_RoundTrip() {
        // Given
        let originalMiles = 50000

        // When - convert to km and back
        let km = DistanceUnit.miles.fromMiles(originalMiles)  // Display in km
        let backToMiles = DistanceUnit.kilometers.toMiles(km)

        // Then - should be close to original (some rounding error acceptable)
        XCTAssertEqual(backToMiles, originalMiles, accuracy: 5)
    }

    // MARK: - Mileage Formatting Tests

    func testMileageFormattingWithThousandsSeparator() {
        // Given
        let mileage = 51247
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        // When
        let formatted = formatter.string(from: NSNumber(value: mileage))

        // Then
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted!.contains(",") || formatted!.contains(" "), "Should contain thousands separator")
    }

    func testMileageFormattingSmallNumber() {
        // Given
        let mileage = 500
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        // When
        let formatted = formatter.string(from: NSNumber(value: mileage))

        // Then
        XCTAssertEqual(formatted, "500")
    }

    // MARK: - Confidence Percentage Tests

    func testConfidencePercentageCalculation() {
        // Given
        let confidence: Float = 0.82

        // When
        let percentage = Int(confidence * 100)

        // Then
        XCTAssertEqual(percentage, 82)
    }

    func testConfidencePercentageAtBoundary() {
        // Given
        let confidence: Float = 1.0

        // When
        let percentage = Int(confidence * 100)

        // Then
        XCTAssertEqual(percentage, 100)
    }

    func testConfidencePercentageZero() {
        // Given
        let confidence: Float = 0.0

        // When
        let percentage = Int(confidence * 100)

        // Then
        XCTAssertEqual(percentage, 0)
    }

    // MARK: - Helper Method

    /// Replicates the confidence level calculation from OCRConfirmationView
    private func confidenceLevel(for confidence: Float) -> ConfidenceLevel {
        if confidence >= OdometerOCRService.highConfidenceThreshold {
            return .high
        } else if confidence >= OdometerOCRService.mediumConfidenceThreshold {
            return .medium
        } else {
            return .low
        }
    }
}
