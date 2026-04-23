//
//  TappableCardModifierTests.swift
//  checkpointTests
//
//  Tests for TappableCardModifier tap vs swipe distance threshold logic
//

import XCTest
@testable import checkpoint

final class TappableCardModifierTests: XCTestCase {

    // MARK: - Distance Calculation Tests

    /// The max tap distance threshold used by TappableCardModifier
    private let maxTapDistance: CGFloat = 10

    /// Helper to calculate distance from translation
    private func calculateDistance(width: CGFloat, height: CGFloat) -> CGFloat {
        sqrt(pow(width, 2) + pow(height, 2))
    }

    // MARK: - Tap Detection (Should Trigger Action)

    func testDistance_NoMovement_IsTap() {
        // Given
        let distance = calculateDistance(width: 0, height: 0)

        // Then - no movement should be considered a tap
        XCTAssertLessThan(distance, maxTapDistance, "Zero movement should be a tap")
    }

    func testDistance_SmallHorizontalMovement_IsTap() {
        // Given
        let distance = calculateDistance(width: 5, height: 0)

        // Then - small horizontal movement should be a tap
        XCTAssertLessThan(distance, maxTapDistance, "5pt horizontal movement should be a tap")
    }

    func testDistance_SmallVerticalMovement_IsTap() {
        // Given
        let distance = calculateDistance(width: 0, height: 5)

        // Then - small vertical movement should be a tap
        XCTAssertLessThan(distance, maxTapDistance, "5pt vertical movement should be a tap")
    }

    func testDistance_SmallDiagonalMovement_IsTap() {
        // Given - diagonal movement within threshold (7pt each direction = ~9.9pt)
        let distance = calculateDistance(width: 7, height: 7)

        // Then - small diagonal movement should be a tap
        XCTAssertLessThan(distance, maxTapDistance, "Small diagonal movement should be a tap")
    }

    func testDistance_JustBelowThreshold_IsTap() {
        // Given - movement just under 10pt
        let distance = calculateDistance(width: 7, height: 6)

        // Then - should be a tap (distance = ~9.2pt)
        XCTAssertLessThan(distance, maxTapDistance, "Movement just below threshold should be a tap")
    }

    // MARK: - Swipe Detection (Should NOT Trigger Action)

    func testDistance_LargeHorizontalMovement_IsSwipe() {
        // Given
        let distance = calculateDistance(width: 50, height: 0)

        // Then - large horizontal movement should be a swipe
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "50pt horizontal movement should be a swipe")
    }

    func testDistance_LargeVerticalMovement_IsSwipe() {
        // Given
        let distance = calculateDistance(width: 0, height: 50)

        // Then - large vertical movement should be a swipe
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "50pt vertical movement should be a swipe")
    }

    func testDistance_LargeDiagonalMovement_IsSwipe() {
        // Given
        let distance = calculateDistance(width: 30, height: 30)

        // Then - large diagonal movement should be a swipe
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Large diagonal movement should be a swipe")
    }

    func testDistance_JustAboveThreshold_IsSwipe() {
        // Given - movement just over 10pt
        let distance = calculateDistance(width: 8, height: 8)

        // Then - should be a swipe (distance = ~11.3pt)
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Movement just above threshold should be a swipe")
    }

    func testDistance_AtExactThreshold_IsSwipe() {
        // Given - exactly 10pt movement
        let distance = calculateDistance(width: 10, height: 0)

        // Then - exactly at threshold should NOT trigger (< not <=)
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Exactly 10pt should be considered a swipe")
    }

    func testDistance_NegativeMovement_CalculatesAbsolute() {
        // Given - negative (leftward/upward) movement
        let distance = calculateDistance(width: -50, height: -30)

        // Then - negative values should calculate as positive distance
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Negative movement should be a swipe")
    }

    // MARK: - Edge Cases

    func testDistance_MixedPositiveNegative_CalculatesCorrectly() {
        // Given - right and up movement
        let distance = calculateDistance(width: 30, height: -40)

        // Then - should calculate correctly (30^2 + 40^2 = 2500, sqrt = 50)
        XCTAssertEqual(distance, 50, accuracy: 0.001, "Mixed direction movement should calculate correctly")
    }

    func testDistance_VerySmallMovement_IsTap() {
        // Given - sub-pixel movement
        let distance = calculateDistance(width: 0.5, height: 0.5)

        // Then - very small movement should be a tap
        XCTAssertLessThan(distance, maxTapDistance, "Sub-pixel movement should be a tap")
    }

    func testDistance_TabSwitchingSwipe_IsSwipe() {
        // Given - typical horizontal swipe for tab switching (~100pt)
        let distance = calculateDistance(width: 100, height: 5)

        // Then - should clearly be a swipe
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Tab switching swipe should be detected")
    }

    func testDistance_ScrollGesture_IsSwipe() {
        // Given - typical vertical scroll (~200pt)
        let distance = calculateDistance(width: 2, height: 200)

        // Then - should clearly be a swipe
        XCTAssertGreaterThanOrEqual(distance, maxTapDistance, "Scroll gesture should be detected")
    }
}
