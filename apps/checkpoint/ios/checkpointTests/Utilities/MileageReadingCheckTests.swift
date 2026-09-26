//
//  MileageReadingCheckTests.swift
//  checkpointTests
//
//  When a spoken odometer reading is saved without asking: never when it is
//  lower than the reading on file, never when it jumps further than the
//  vehicle could have driven, always for a vehicle's first reading.
//

import XCTest
@testable import checkpoint

@MainActor
final class MileageReadingCheckTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func daysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(-days * 86_400)
    }

    func test_evaluate_ordinaryIncrease_isPlausible() {
        let check = MileageReadingCheck.evaluate(
            reading: 45_600, current: 45_000, lastRecordedAt: daysAgo(10), dailyPace: 40, now: now
        )
        XCTAssertEqual(check, .plausible)
        XCTAssertFalse(check.needsConfirmation)
    }

    func test_evaluate_sameReading_isPlausible() {
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 45_000, current: 45_000, lastRecordedAt: daysAgo(1), dailyPace: nil, now: now),
            .plausible
        )
    }

    func test_evaluate_lowerReading_asks() {
        let check = MileageReadingCheck.evaluate(
            reading: 44_000, current: 45_000, lastRecordedAt: daysAgo(10), dailyPace: 40, now: now
        )
        XCTAssertEqual(check, .lowerThanCurrent(current: 45_000))
        XCTAssertTrue(check.needsConfirmation)
    }

    func test_evaluate_extraDigit_isUnusualJump() {
        // "45,200" heard as "452,000".
        let check = MileageReadingCheck.evaluate(
            reading: 452_000, current: 45_000, lastRecordedAt: daysAgo(14), dailyPace: 40, now: now
        )
        guard case .unusualJump(let current, let increase, let allowance) = check else {
            return XCTFail("Expected an unusual jump, got \(check)")
        }
        XCTAssertEqual(current, 45_000)
        XCTAssertEqual(increase, 407_000)
        XCTAssertEqual(allowance, 2_100, "14 days at the 150 mi/day floor")
    }

    func test_evaluate_sameDayIncrease_usesMinimumAllowance() {
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 45_900, current: 45_000, lastRecordedAt: daysAgo(0.1), dailyPace: 30, now: now),
            .plausible,
            "900 mi is under the 1,000 mi floor"
        )
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 46_500, current: 45_000, lastRecordedAt: daysAgo(0.1), dailyPace: 30, now: now),
            .unusualJump(current: 45_000, increase: 1_500, allowance: 1_000)
        )
    }

    func test_allowance_heavyPace_scalesPastTheFloor() {
        // 200 mi/day of history → 400 mi/day allowed, over 10 days.
        XCTAssertEqual(MileageReadingCheck.allowance(since: daysAgo(10), dailyPace: 200, now: now), 4_000)
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 48_900, current: 45_000, lastRecordedAt: daysAgo(10), dailyPace: 200, now: now),
            .plausible
        )
    }

    func test_evaluate_longGap_allowsMoreDriving() {
        // Three months since the last reading: 90 days × 150 = 13,500 mi.
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 57_000, current: 45_000, lastRecordedAt: daysAgo(90), dailyPace: nil, now: now),
            .plausible
        )
    }

    func test_evaluate_noReadingOnFile_isAlwaysPlausible() {
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 120_000, current: 45_000, lastRecordedAt: nil, dailyPace: nil, now: now),
            .plausible
        )
        XCTAssertEqual(
            MileageReadingCheck.evaluate(reading: 120_000, current: 0, lastRecordedAt: daysAgo(1), dailyPace: nil, now: now),
            .plausible
        )
    }
}
