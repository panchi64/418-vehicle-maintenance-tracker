//
//  ReminderImpactCalculatorTests.swift
//  checkpointTests
//
//  Tests for the pure interval → deadline projection used by the reminder
//  impact preview (R6). Must mirror Service.deriveDueFromIntervals exactly.
//

import XCTest
@testable import checkpoint

final class ReminderImpactCalculatorTests: XCTestCase {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .now
    }

    // MARK: - projected

    func testProjected_IntervalOnly_SetsDueDateAndMileage() {
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: 6,
            intervalMiles: 5000,
            anchorDate: date(2026, 1, 1),
            anchorMileage: 30000,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
        XCTAssertEqual(schedule.dueDate, date(2026, 7, 1))
        XCTAssertEqual(schedule.dueMileage, 35000)
    }

    func testProjected_ExplicitOnly_UsesExplicitValues() {
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: nil,
            intervalMiles: nil,
            anchorDate: date(2026, 1, 1),
            anchorMileage: 30000,
            explicitDueDate: date(2026, 3, 15),
            explicitDueMileage: 32000
        )
        XCTAssertEqual(schedule.dueDate, date(2026, 3, 15))
        XCTAssertEqual(schedule.dueMileage, 32000)
    }

    func testProjected_ExplicitWinsOverInterval() {
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: 6,
            intervalMiles: 5000,
            anchorDate: date(2026, 1, 1),
            anchorMileage: 30000,
            explicitDueDate: date(2026, 3, 15),
            explicitDueMileage: 32000
        )
        XCTAssertEqual(schedule.dueDate, date(2026, 3, 15))
        XCTAssertEqual(schedule.dueMileage, 32000)
    }

    func testProjected_MixedIntervalAndExplicit() {
        // Explicit date wins, but mileage falls back to interval-derived.
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: nil,
            intervalMiles: 5000,
            anchorDate: date(2026, 1, 1),
            anchorMileage: 30000,
            explicitDueDate: date(2026, 3, 15),
            explicitDueMileage: nil
        )
        XCTAssertEqual(schedule.dueDate, date(2026, 3, 15))
        XCTAssertEqual(schedule.dueMileage, 35000)
    }

    func testProjected_NilOrZeroIntervalClearsDeadline() {
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: 0,
            intervalMiles: nil,
            anchorDate: date(2026, 1, 1),
            anchorMileage: 30000,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
        XCTAssertNil(schedule.dueDate)
        XCTAssertNil(schedule.dueMileage)
    }

    // MARK: - impact

    func testImpact_NilWhenSchedulesAreEqual() {
        let schedule = ReminderImpactCalculator.Schedule(dueDate: date(2026, 3, 15), dueMileage: 32000)
        XCTAssertNil(ReminderImpactCalculator.impact(current: schedule, proposed: schedule))
    }

    func testImpact_NonNilWhenSchedulesDiffer() {
        let current = ReminderImpactCalculator.Schedule(dueDate: date(2026, 3, 15), dueMileage: nil)
        let proposed = ReminderImpactCalculator.Schedule(dueDate: date(2026, 9, 15), dueMileage: nil)
        let impact = ReminderImpactCalculator.impact(current: current, proposed: proposed)
        XCTAssertEqual(impact?.before, current)
        XCTAssertEqual(impact?.after, proposed)
    }

    func testImpact_NonNilWhenClearingSchedule() {
        let current = ReminderImpactCalculator.Schedule(dueDate: date(2026, 3, 15), dueMileage: nil)
        let proposed = ReminderImpactCalculator.Schedule(dueDate: nil, dueMileage: nil)
        XCTAssertNotNil(ReminderImpactCalculator.impact(current: current, proposed: proposed))
    }
}
