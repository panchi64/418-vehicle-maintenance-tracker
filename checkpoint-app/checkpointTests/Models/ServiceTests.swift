//
//  ServiceTests.swift
//  checkpointTests
//
//  Unit tests for Service model, including predictive due dates and urgency scores
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceTests: XCTestCase {

    // MARK: - Predicted Due Date Tests

    func testPredictedDueDate_WithPace_CalculatesCorrectly() {
        // Given: Service with due mileage 1000 miles away
        let service = Service(
            name: "Oil Change",
            dueMileage: 51000
        )
        let currentMileage = 50000
        let dailyPace = 40.0  // 40 miles per day

        // When
        let predictedDate = service.predictedDueDate(currentMileage: currentMileage, dailyPace: dailyPace)

        // Then
        // 1000 miles / 40 mi/day = 25 days
        XCTAssertNotNil(predictedDate)
        let daysUntilPredicted = Calendar.current.dateComponents([.day], from: .now, to: predictedDate!).day!
        XCTAssertEqual(daysUntilPredicted, 25, accuracy: 1, "Should predict 25 days until due")
    }

    func testPredictedDueDate_NoPace_ReturnsNil() {
        // Given
        let service = Service(name: "Oil Change", dueMileage: 51000)

        // When
        let predictedDate = service.predictedDueDate(currentMileage: 50000, dailyPace: nil)

        // Then
        XCTAssertNil(predictedDate, "Should return nil when no pace data")
    }

    func testPredictedDueDate_ZeroPace_ReturnsNil() {
        // Given
        let service = Service(name: "Oil Change", dueMileage: 51000)

        // When
        let predictedDate = service.predictedDueDate(currentMileage: 50000, dailyPace: 0.0)

        // Then
        XCTAssertNil(predictedDate, "Should return nil when pace is zero")
    }

    func testPredictedDueDate_NoDueMileage_ReturnsNil() {
        // Given: Service with only due date, no mileage
        let service = Service(
            name: "Battery Check",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)
        )

        // When
        let predictedDate = service.predictedDueDate(currentMileage: 50000, dailyPace: 40.0)

        // Then
        XCTAssertNil(predictedDate, "Should return nil when no due mileage set")
    }

    func testPredictedDueDate_AlreadyPastDue_ReturnsNil() {
        // Given: Due mileage already exceeded
        let service = Service(name: "Oil Change", dueMileage: 49000)
        let currentMileage = 50000

        // When
        let predictedDate = service.predictedDueDate(currentMileage: currentMileage, dailyPace: 40.0)

        // Then
        XCTAssertNil(predictedDate, "Should return nil when already past due mileage")
    }

    // MARK: - Effective Due Date Tests

    func testEffectiveDueDate_ReturnsEarlierDate() {
        // Given: Service with due date in 30 days but mileage reached in 10 days
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 30, to: .now)!
        let service = Service(
            name: "Oil Change",
            dueDate: dueDate,
            dueMileage: 50400  // 400 miles at 40/day = 10 days
        )
        let currentMileage = 50000
        let dailyPace = 40.0

        // When
        let effectiveDate = service.effectiveDueDate(currentMileage: currentMileage, dailyPace: dailyPace)

        // Then
        XCTAssertNotNil(effectiveDate)
        let daysUntilEffective = calendar.dateComponents([.day], from: .now, to: effectiveDate!).day!
        XCTAssertEqual(daysUntilEffective, 10, accuracy: 1, "Should use predicted mileage date (10 days)")
    }

    func testEffectiveDueDate_OnlyDueDate_ReturnsDate() {
        // Given: Service with only due date
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 20, to: .now)!
        let service = Service(name: "Battery Check", dueDate: dueDate)

        // When
        let effectiveDate = service.effectiveDueDate(currentMileage: 50000, dailyPace: nil)

        // Then
        XCTAssertNotNil(effectiveDate)
        XCTAssertEqual(effectiveDate, dueDate)
    }

    func testEffectiveDueDate_NeitherSet_ReturnsNil() {
        // Given: Service with no due date or mileage
        let service = Service(name: "General Check")

        // When
        let effectiveDate = service.effectiveDueDate(currentMileage: 50000, dailyPace: 40.0)

        // Then
        XCTAssertNil(effectiveDate)
    }

    // MARK: - Urgency Score Tests

    func testUrgencyScore_UsesActualPace() {
        // Given: Service with due mileage
        let service = Service(name: "Oil Change", dueMileage: 50800)
        let currentMileage = 50000

        // When: Using different paces
        let scoreWithFastPace = service.urgencyScore(currentMileage: currentMileage, dailyPace: 80.0)  // 10 days
        let scoreWithSlowPace = service.urgencyScore(currentMileage: currentMileage, dailyPace: 20.0)  // 40 days

        // Then
        XCTAssertLessThan(scoreWithFastPace, scoreWithSlowPace, "Faster pace should have lower (more urgent) score")
    }

    func testUrgencyScore_NoPace_UsesDefault40() {
        // Given
        let service = Service(name: "Oil Change", dueMileage: 50800)
        let currentMileage = 50000

        // When: Using nil pace (should fall back to 40 mi/day default)
        let scoreNoPace = service.urgencyScore(currentMileage: currentMileage, dailyPace: nil)
        let scoreWith40Pace = service.urgencyScore(currentMileage: currentMileage, dailyPace: 40.0)

        // Then
        XCTAssertEqual(scoreNoPace, scoreWith40Pace, "Nil pace should use 40 mi/day default")
    }

    func testUrgencyScore_CombinesDateAndMileage() {
        // Given: Service with both date and mileage
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 30, to: .now)!
        let service = Service(
            name: "Oil Change",
            dueDate: dueDate,
            dueMileage: 50400  // 400 miles at 40/day = 10 days
        )

        // When
        let score = service.urgencyScore(currentMileage: 50000, dailyPace: 40.0)

        // Then: Should use lower (more urgent) of the two = 10 days
        XCTAssertEqual(score, 10, accuracy: 1, "Should use lower urgency from mileage")
    }

    func testUrgencyScore_DateOnly_UsesDateDays() {
        // Given: Service with only due date
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 15, to: .now)!
        let service = Service(name: "Battery Check", dueDate: dueDate)

        // When
        let score = service.urgencyScore(currentMileage: 50000)

        // Then
        XCTAssertEqual(score, 15, accuracy: 1)
    }

    func testUrgencyScore_Overdue_ReturnsNegative() {
        // Given: Service past due
        let calendar = Calendar.current
        let pastDue = calendar.date(byAdding: .day, value: -5, to: .now)!
        let service = Service(name: "Oil Change", dueDate: pastDue)

        // When
        let score = service.urgencyScore(currentMileage: 50000)

        // Then
        XCTAssertLessThan(score, 0, "Overdue services should have negative score")
    }
}
