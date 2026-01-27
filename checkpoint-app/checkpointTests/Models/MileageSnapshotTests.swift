//
//  MileageSnapshotTests.swift
//  checkpointTests
//
//  Unit tests for MileageSnapshot model and pace calculations
//

import XCTest
@testable import checkpoint

final class MileageSnapshotTests: XCTestCase {

    // MARK: - Basic Pace Calculation Tests

    func testCalculateDailyPaceReturnsNilForEmptySnapshots() {
        // Given
        let snapshots: [MileageSnapshot] = []

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: snapshots)

        // Then
        XCTAssertNil(pace, "Should return nil for empty snapshots array")
    }

    func testCalculateDailyPaceReturnsNilForSingleSnapshot() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let snapshot = MileageSnapshot(vehicle: vehicle, mileage: 10000, recordedAt: .now)

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: [snapshot])

        // Then
        XCTAssertNil(pace, "Should return nil for single snapshot")
    }

    func testCalculateDailyPaceReturnsNilForLessThan7Days() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -5, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10200,
            recordedAt: .now
        )

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: [snapshot1, snapshot2])

        // Then
        XCTAssertNil(pace, "Should return nil when less than 7 days of data")
    }

    func testCalculateDailyPaceReturnsValueFor7DaysOrMore() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -10, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10400,
            recordedAt: .now
        )

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: [snapshot1, snapshot2])

        // Then
        XCTAssertNotNil(pace, "Should return pace for 7+ days of data")
        XCTAssertEqual(pace!, 40.0, accuracy: 0.1, "400 miles over 10 days = 40 miles/day")
    }

    // MARK: - Recency Weighting Tests

    func testRecentSnapshotsHaveHigherInfluence() {
        // Given: Two scenarios with same overall average but different distributions
        // Scenario A: Higher pace recently (recent driving increased)
        // Scenario B: Higher pace long ago (recent driving decreased)
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current
        let now = Date.now

        // Scenario A: Low pace 60 days ago, high pace recently
        // Day -60: 10000 mi -> Day -30: 10300 mi (10 mi/day)
        // Day -30: 10300 mi -> Day 0: 11500 mi (40 mi/day)
        let scenarioASnapshots = [
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10000,
                recordedAt: calendar.date(byAdding: .day, value: -60, to: now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10300,
                recordedAt: calendar.date(byAdding: .day, value: -30, to: now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 11500,
                recordedAt: now
            )
        ]

        // Scenario B: High pace 60 days ago, low pace recently
        // Day -60: 10000 mi -> Day -30: 11200 mi (40 mi/day)
        // Day -30: 11200 mi -> Day 0: 11500 mi (10 mi/day)
        let scenarioBSnapshots = [
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10000,
                recordedAt: calendar.date(byAdding: .day, value: -60, to: now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 11200,
                recordedAt: calendar.date(byAdding: .day, value: -30, to: now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 11500,
                recordedAt: now
            )
        ]

        // When
        let paceA = MileageSnapshot.calculateDailyPace(from: scenarioASnapshots)!
        let paceB = MileageSnapshot.calculateDailyPace(from: scenarioBSnapshots)!

        // Then
        // Scenario A should have higher estimated pace because recent driving is higher
        // With recency weighting, recent intervals influence the result more
        XCTAssertGreaterThan(paceA, paceB, "Scenario A (high recent pace) should have higher estimated pace than Scenario B (high old pace)")

        // Both should be between 10 and 40 (the two paces)
        XCTAssertGreaterThan(paceA, 10.0, "Pace A should be > 10 (minimum interval pace)")
        XCTAssertLessThan(paceA, 40.0, "Pace A should be < 40 (maximum interval pace)")
        XCTAssertGreaterThan(paceB, 10.0, "Pace B should be > 10 (minimum interval pace)")
        XCTAssertLessThan(paceB, 40.0, "Pace B should be < 40 (maximum interval pace)")

        // Scenario A should be closer to 40, Scenario B closer to 10
        XCTAssertGreaterThan(paceA, 25.0, "Pace A should be > 25 (weighted toward recent 40 mi/day)")
        XCTAssertLessThan(paceB, 25.0, "Pace B should be < 25 (weighted toward recent 10 mi/day)")
    }

    func testRecencyWeightingWithManySnapshots() {
        // Given: Snapshots over 90 days with varying pace
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current
        let now = Date.now

        var snapshots: [MileageSnapshot] = []

        // Old period (90-60 days ago): 20 mi/day
        // Middle period (60-30 days ago): 30 mi/day
        // Recent period (30-0 days ago): 50 mi/day

        var mileage = 10000
        for dayOffset in stride(from: 90, through: 0, by: -15) {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            snapshots.append(MileageSnapshot(vehicle: vehicle, mileage: mileage, recordedAt: date))

            // Determine pace for next interval
            let milesForInterval: Int
            if dayOffset > 60 {
                milesForInterval = 20 * 15  // 20 mi/day for 15 days
            } else if dayOffset > 30 {
                milesForInterval = 30 * 15  // 30 mi/day for 15 days
            } else {
                milesForInterval = 50 * 15  // 50 mi/day for 15 days
            }
            mileage += milesForInterval
        }

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: snapshots)

        // Then
        XCTAssertNotNil(pace, "Should calculate pace from many snapshots")
        // With 30-day half-life, recent 50 mi/day should dominate
        // But middle and old periods still contribute
        XCTAssertGreaterThan(pace!, 35.0, "Pace should be weighted toward recent 50 mi/day")
        XCTAssertLessThan(pace!, 50.0, "Pace should be less than 50 due to older lower-pace periods")
    }

    func testRecencyWeightingWithExtremelyOldData() {
        // Given: One very old snapshot and one recent snapshot
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current
        let now = Date.now

        // 365 days ago: 10000 mi, now: 20000 mi
        // Simple average: 27.4 mi/day over 365 days
        let snapshots = [
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10000,
                recordedAt: calendar.date(byAdding: .day, value: -365, to: now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 20000,
                recordedAt: now
            )
        ]

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: snapshots)

        // Then
        XCTAssertNotNil(pace, "Should calculate pace with old data")
        // With only one interval, the pace should be close to the actual pace
        XCTAssertEqual(pace!, 27.4, accuracy: 1.0, "Single interval pace should be accurate")
    }

    // MARK: - Edge Cases

    func testCalculateDailyPaceWithZeroMilesDriven() {
        // Given: Same mileage at different dates
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -14, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,  // Same mileage
            recordedAt: .now
        )

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: [snapshot1, snapshot2])

        // Then
        // Should return nil because no valid pace pairs (0 miles driven)
        XCTAssertNil(pace, "Should return nil when no miles were driven")
    }

    func testCalculateDailyPaceHandlesUnorderedSnapshots() {
        // Given: Snapshots not in chronological order
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -14, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10700,
            recordedAt: calendar.date(byAdding: .day, value: -7, to: .now)!
        )
        let snapshot3 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 11200,
            recordedAt: .now
        )

        // Add in wrong order
        let unorderedSnapshots = [snapshot3, snapshot1, snapshot2]

        // When
        let pace = MileageSnapshot.calculateDailyPace(from: unorderedSnapshots)

        // Then
        XCTAssertNotNil(pace, "Should handle unordered snapshots")
        // Overall: 1200 miles over 14 days with recent weighting
        // The function should sort them correctly
    }

    // MARK: - Has Snapshot Today Tests

    func testHasSnapshotTodayReturnsTrue() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let snapshot = MileageSnapshot(vehicle: vehicle, mileage: 10000, recordedAt: .now)

        // When
        let hasToday = MileageSnapshot.hasSnapshotToday(snapshots: [snapshot])

        // Then
        XCTAssertTrue(hasToday, "Should return true when there's a snapshot from today")
    }

    func testHasSnapshotTodayReturnsFalse() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        let snapshot = MileageSnapshot(vehicle: vehicle, mileage: 10000, recordedAt: yesterday)

        // When
        let hasToday = MileageSnapshot.hasSnapshotToday(snapshots: [snapshot])

        // Then
        XCTAssertFalse(hasToday, "Should return false when no snapshot from today")
    }

    func testHasSnapshotTodayWithEmptyArray() {
        // When
        let hasToday = MileageSnapshot.hasSnapshotToday(snapshots: [])

        // Then
        XCTAssertFalse(hasToday, "Should return false for empty array")
    }

    // MARK: - Pace Result Tests

    func testCalculatePaceResult_InsufficientData_ReturnsNil() {
        // Given: Less than 2 snapshots
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let snapshot = MileageSnapshot(vehicle: vehicle, mileage: 10000, recordedAt: .now)

        // When
        let result = MileageSnapshot.calculatePaceResult(from: [snapshot])

        // Then
        XCTAssertNil(result, "Should return nil for insufficient data")
    }

    func testCalculatePaceResult_LessThan7Days_ReturnsNil() {
        // Given: Only 5 days of data
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -5, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10200,
            recordedAt: .now
        )

        // When
        let result = MileageSnapshot.calculatePaceResult(from: [snapshot1, snapshot2])

        // Then
        XCTAssertNil(result, "Should return nil for less than 7 days of data")
    }

    func testCalculatePaceResult_LowConfidence_7to14Days() {
        // Given: 10 days of data with 2 snapshots (minimum for low confidence)
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshot1 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10000,
            recordedAt: calendar.date(byAdding: .day, value: -10, to: .now)!
        )
        let snapshot2 = MileageSnapshot(
            vehicle: vehicle,
            mileage: 10400,
            recordedAt: .now
        )

        // When
        let result = MileageSnapshot.calculatePaceResult(from: [snapshot1, snapshot2])

        // Then
        XCTAssertNotNil(result, "Should return result for 10 days of data")
        XCTAssertEqual(result?.confidence, .low, "Should be low confidence with 7-14 days and 2 snapshots")
        XCTAssertEqual(result?.dataPointCount, 2)
        XCTAssertEqual(result?.milesPerDay ?? 0, 40.0, accuracy: 0.5)
    }

    func testCalculatePaceResult_MediumConfidence_14to30Days() {
        // Given: 20 days of data with 3+ snapshots
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshots = [
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10000,
                recordedAt: calendar.date(byAdding: .day, value: -20, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10400,
                recordedAt: calendar.date(byAdding: .day, value: -10, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10800,
                recordedAt: .now
            )
        ]

        // When
        let result = MileageSnapshot.calculatePaceResult(from: snapshots)

        // Then
        XCTAssertNotNil(result, "Should return result for 20 days of data")
        XCTAssertEqual(result?.confidence, .medium, "Should be medium confidence with 14-30 days and 3+ snapshots")
        XCTAssertEqual(result?.dataPointCount, 3)
    }

    func testCalculatePaceResult_HighConfidence_30PlusDays() {
        // Given: 45 days of data with 5+ snapshots
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current

        let snapshots = [
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10000,
                recordedAt: calendar.date(byAdding: .day, value: -45, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10400,
                recordedAt: calendar.date(byAdding: .day, value: -35, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 10800,
                recordedAt: calendar.date(byAdding: .day, value: -25, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 11200,
                recordedAt: calendar.date(byAdding: .day, value: -15, to: .now)!
            ),
            MileageSnapshot(
                vehicle: vehicle,
                mileage: 11600,
                recordedAt: .now
            )
        ]

        // When
        let result = MileageSnapshot.calculatePaceResult(from: snapshots)

        // Then
        XCTAssertNotNil(result, "Should return result for 45 days of data")
        XCTAssertEqual(result?.confidence, .high, "Should be high confidence with 30+ days and 5+ snapshots")
        XCTAssertEqual(result?.dataPointCount, 5)
    }

    func testCalculatePaceResult_IncludesDateRange() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -14, to: .now)!

        let snapshots = [
            MileageSnapshot(vehicle: vehicle, mileage: 10000, recordedAt: startDate),
            MileageSnapshot(vehicle: vehicle, mileage: 10560, recordedAt: .now)
        ]

        // When
        let result = MileageSnapshot.calculatePaceResult(from: snapshots)

        // Then
        XCTAssertNotNil(result?.dateRange)
        XCTAssertEqual(
            Calendar.current.isDate(result!.dateRange.start, inSameDayAs: startDate),
            true,
            "Date range should start at first snapshot"
        )
    }
}
