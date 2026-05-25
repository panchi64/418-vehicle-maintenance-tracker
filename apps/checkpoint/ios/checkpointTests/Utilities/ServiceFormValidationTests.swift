//
//  ServiceFormValidationTests.swift
//  checkpointTests
//
//  Tests for the soft sanity-check heuristics used in the Record Service
//  flow. These warnings are advisory only — never blocking — so the tests
//  focus on when they should and should not fire.
//

import XCTest
@testable import checkpoint

final class ServiceFormValidationTests: XCTestCase {

    // MARK: - Mileage warnings

    func testMileageWarning_NilWhenMileageEmpty() {
        let result = ServiceFormValidation.mileageWarning(
            entered: nil,
            vehicleCurrentMileage: 30000,
            maxLoggedMileage: 25000,
            performedDate: Date()
        )
        XCTAssertNil(result)
    }

    func testMileageWarning_NilForPlausibleRecentEntry() {
        let result = ServiceFormValidation.mileageWarning(
            entered: 32500,
            vehicleCurrentMileage: 32000,
            maxLoggedMileage: 31000,
            performedDate: Date()
        )
        XCTAssertNil(result)
    }

    func testMileageWarning_FiresWhenRecentEntryIsLowerThanLastLogged() {
        // Recent entry (today) but mileage 28k when last log was 31k → likely typo
        let result = ServiceFormValidation.mileageWarning(
            entered: 28000,
            vehicleCurrentMileage: 32000,
            maxLoggedMileage: 31000,
            performedDate: Date()
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("Lower") ?? false)
    }

    func testMileageWarning_QuietForOldBackfillBelowLastLogged() {
        // Backfilling an old entry from years ago — expected to be below current,
        // shouldn't be flagged as a typo.
        let yearsAgo = Date(timeIntervalSinceNow: -365 * 24 * 60 * 60)
        let result = ServiceFormValidation.mileageWarning(
            entered: 15000,
            vehicleCurrentMileage: 32000,
            maxLoggedMileage: 31000,
            performedDate: yearsAgo
        )
        XCTAssertNil(result, "Backfill entries should not trigger the lower-than-last warning")
    }

    func testMileageWarning_FiresForImplausibleJumpEvenWhenBackfilling() {
        // Even on an old entry, 500,000 above current is almost certainly a typo.
        let yearsAgo = Date(timeIntervalSinceNow: -365 * 24 * 60 * 60)
        let result = ServiceFormValidation.mileageWarning(
            entered: 600_000,
            vehicleCurrentMileage: 32000,
            maxLoggedMileage: 31000,
            performedDate: yearsAgo
        )
        XCTAssertNotNil(result)
    }

    func testMileageWarning_NilWhenNoPriorLogsExist() {
        let result = ServiceFormValidation.mileageWarning(
            entered: 100,
            vehicleCurrentMileage: 32000,
            maxLoggedMileage: nil,
            performedDate: Date()
        )
        XCTAssertNil(result, "Without history we can't compare, so don't false-alarm")
    }

    // MARK: - Cost warnings

    func testCostWarning_NilWhenCostMissing() {
        XCTAssertNil(ServiceFormValidation.costWarning(
            enteredCost: nil,
            medianHistoricalCost: 50,
            serviceName: "Oil Change"
        ))
    }

    func testCostWarning_NilWhenNoHistory() {
        XCTAssertNil(ServiceFormValidation.costWarning(
            enteredCost: 9999,
            medianHistoricalCost: nil,
            serviceName: "Oil Change"
        ))
    }

    func testCostWarning_NilForCostInPlausibleRange() {
        XCTAssertNil(ServiceFormValidation.costWarning(
            enteredCost: 60,
            medianHistoricalCost: 50,
            serviceName: "Oil Change"
        ))
    }

    func testCostWarning_FiresForCostMoreThanFiveTimesMedian() {
        let result = ServiceFormValidation.costWarning(
            enteredCost: 500,
            medianHistoricalCost: 50,
            serviceName: "Oil Change"
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("higher") ?? false)
    }

    func testCostWarning_DoesNotFireAtExactlyFiveTimesMedian() {
        XCTAssertNil(ServiceFormValidation.costWarning(
            enteredCost: 250,
            medianHistoricalCost: 50,
            serviceName: "Oil Change"
        ))
    }

    func testCostWarning_NilWhenMedianIsZero() {
        XCTAssertNil(ServiceFormValidation.costWarning(
            enteredCost: 100,
            medianHistoricalCost: 0,
            serviceName: "Oil Change"
        ))
    }
}
