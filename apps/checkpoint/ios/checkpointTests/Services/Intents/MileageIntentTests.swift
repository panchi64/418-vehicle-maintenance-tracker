//
//  MileageIntentTests.swift
//  checkpointTests
//
//  Update Mileage records directly, through the registered container, and
//  asks only for a misheard-looking number; Get Mileage answers from the
//  reading or the pace estimate.
//

import XCTest
import AppIntents
import SwiftData
@testable import checkpoint

final class MileageIntentTests: IntentTestCase {

    // MARK: - Update Mileage

    func test_updateMileage_plausibleReading_recordsWithoutOpeningTheApp() async throws {
        let intent = UpdateMileageIntent()
        intent.mileage = 45_600

        _ = try await wired(intent).perform()

        XCTAssertEqual(vehicle.currentMileage, 45_600)
        XCTAssertEqual(vehicle.mileageSnapshots?.last?.mileage, 45_600)
        XCTAssertEqual(vehicle.mileageSnapshots?.last?.source, .manual)
        XCTAssertNil(PendingRouteStore.shared.route, "No app-open route: the reading is saved in place")
        XCTAssertFalse(context.hasChanges, "The intent saves before returning")
    }

    func test_updateMileage_namedVehicle_updatesThatVehicle() async throws {
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019, currentMileage: 20_000)
        context.insert(other)
        try context.save()

        let intent = UpdateMileageIntent()
        intent.vehicle = VehicleEntity(model: other)
        intent.mileage = 20_300
        _ = try await wired(intent).perform()

        XCTAssertEqual(other.currentMileage, 20_300)
        XCTAssertEqual(vehicle.currentMileage, 45_000)
    }

    func test_updateMileage_kilometers_storesMiles() async throws {
        DistanceSettings.shared.unit = .kilometers
        let intent = UpdateMileageIntent()
        intent.mileage = 73_000  // ≈ 45,360 mi

        _ = try await wired(intent).perform()

        XCTAssertEqual(vehicle.currentMileage, DistanceUnit.kilometers.toMiles(73_000))
    }

    func test_confirmation_plausible_isNil() {
        XCTAssertNil(UpdateMileageIntent.confirmation(for: .plausible, reading: 45_600, vehicle: vehicle))
    }

    func test_confirmation_lowerOrJump_asksWithBothNumbers() throws {
        let lower = try XCTUnwrap(UpdateMileageIntent.confirmation(
            for: .lowerThanCurrent(current: 45_000), reading: 44_000, vehicle: vehicle
        ))
        XCTAssertTrue(lower.contains("45,000") && lower.contains("44,000"), lower)

        let jump = try XCTUnwrap(UpdateMileageIntent.confirmation(
            for: .unusualJump(current: 45_000, increase: 407_000, allowance: 2_100), reading: 452_000, vehicle: vehicle
        ))
        XCTAssertTrue(jump.contains("452,000") && jump.contains("407,000"), jump)
    }

    func test_updateMileage_lowerReading_neverSavesWithoutAnAnswer() async throws {
        let intent = UpdateMileageIntent()
        intent.mileage = 44_000

        await runUnanswered { _ = try await self.wired(intent).perform() }

        XCTAssertEqual(vehicle.currentMileage, 45_000, "A lower reading is saved only after a yes")
    }

    // MARK: - Get Mileage

    func test_getMileage_recordedReading_saysWhen() {
        let answer = GetMileageIntent.answer(for: vehicle, estimate: vehicle.mileageEstimate)
        XCTAssertTrue(answer.contains("45,000"), answer)
        XCTAssertTrue(answer.contains(SpokenValue.date(vehicle.mileageUpdatedAt!)), answer)
    }

    func test_getMileage_withEstimate_saysEstimateAndPace() {
        let estimate = MileageEstimate(pace: 42.4, effective: 45_130, isEstimated: true)
        let answer = GetMileageIntent.answer(for: vehicle, estimate: estimate)
        XCTAssertTrue(answer.contains("45,130"), answer)
        XCTAssertTrue(answer.contains("42 mi"), answer)
        XCTAssertTrue(answer.contains("45,000"), "The reading the estimate is built on is named too")
    }

    func test_getMileage_noReading_saysSo() {
        let empty = Vehicle(name: "New", make: "Kia", model: "Soul", year: 2024)
        XCTAssertEqual(
            GetMileageIntent.answer(for: empty, estimate: empty.mileageEstimate),
            L10n.siriMileageNone(vehicle: "New")
        )
    }

    func test_getMileage_perform_returnsEffectiveMileageInUserUnit() async throws {
        let result = try await wired(GetMileageIntent()).perform()
        XCTAssertEqual(result.value, 45_000)
    }
}
