//
//  MileageCommitTests.swift
//  checkpointTests
//
//  Regression guard for F11 — the single mileage-commit path.
//
//  The bug this locks down was silent: `AddServiceView+Save` set
//  `currentMileage` directly without advancing `mileageUpdatedAt` or writing a
//  `MileageSnapshot`, and compared magnitude only with no date guard. So
//  backfilling an old high-mileage service overwrote a newer odometer, and
//  every adoption left the pace/estimate engine computing a delta over a stale
//  interval. Neither failure surfaced anywhere a user or a test would notice.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class MileageCommitTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeVehicle(
        currentMileage: Int,
        updatedAt: Date?
    ) -> Vehicle {
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: currentMileage
        )
        vehicle.mileageUpdatedAt = updatedAt
        modelContext.insert(vehicle)
        return vehicle
    }

    private func snapshots(for vehicle: Vehicle) -> [MileageSnapshot] {
        vehicle.mileageSnapshots ?? []
    }

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now)!
    }

    // MARK: - Adoption of a newer, higher reading

    func test_commitIfNewest_adoptsHigherReadingObservedAfterLastUpdate() {
        let vehicle = makeVehicle(currentMileage: 32_500, updatedAt: daysAgo(21))
        let observedAt = daysAgo(1)

        let outcome = MileageCommit.commitIfNewest(
            reading: 33_100,
            observedAt: observedAt,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertTrue(outcome.didAdopt)
        XCTAssertEqual(outcome.previousMileage, 32_500)
        XCTAssertEqual(vehicle.currentMileage, 33_100)
    }

    /// The core of the original bug: the number moved but the date didn't, so
    /// pace was computed over a 21-day-stale interval.
    func test_commitIfNewest_advancesMileageUpdatedAtToObservationDate() {
        let vehicle = makeVehicle(currentMileage: 32_500, updatedAt: daysAgo(21))
        let observedAt = daysAgo(1)

        MileageCommit.commitIfNewest(
            reading: 33_100,
            observedAt: observedAt,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertNotNil(vehicle.mileageUpdatedAt)
        XCTAssertEqual(
            vehicle.mileageUpdatedAt!.timeIntervalSince1970,
            observedAt.timeIntervalSince1970,
            accuracy: 1.0,
            "mileageUpdatedAt must reflect when the reading was observed, not when it was entered"
        )
    }

    func test_commitIfNewest_writesSnapshotOnAdoption() {
        let vehicle = makeVehicle(currentMileage: 32_500, updatedAt: daysAgo(21))

        MileageCommit.commitIfNewest(
            reading: 33_100,
            observedAt: daysAgo(1),
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        let written = snapshots(for: vehicle)
        XCTAssertEqual(written.count, 1)
        XCTAssertEqual(written.first?.mileage, 33_100)
        XCTAssertEqual(written.first?.source, .serviceCompletion)
    }

    // MARK: - Backfill must not overwrite a newer odometer

    /// The destructive case: reconstructing history on a vehicle whose odometer
    /// is already current. Magnitude alone would adopt 40,000 over 33,000.
    func test_commitIfNewest_doesNotAdoptOlderReadingEvenWhenHigher() {
        let vehicle = makeVehicle(currentMileage: 33_000, updatedAt: daysAgo(2))

        let outcome = MileageCommit.commitIfNewest(
            reading: 40_000,
            observedAt: daysAgo(900),
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertFalse(outcome.didAdopt)
        XCTAssertTrue(outcome.wasSupersededByNewerReading)
        XCTAssertEqual(vehicle.currentMileage, 33_000, "backfill must never move the current odometer")
    }

    func test_commitIfNewest_leavesUpdatedAtAndSnapshotsUntouchedOnBackfill() {
        let originalDate = daysAgo(2)
        let vehicle = makeVehicle(currentMileage: 33_000, updatedAt: originalDate)

        MileageCommit.commitIfNewest(
            reading: 40_000,
            observedAt: daysAgo(900),
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertEqual(
            vehicle.mileageUpdatedAt?.timeIntervalSince1970,
            originalDate.timeIntervalSince1970,
            "a rejected reading must not restamp the odometer date"
        )
        XCTAssertTrue(snapshots(for: vehicle).isEmpty)
    }

    // MARK: - Readings at or below current

    func test_commitIfNewest_doesNotAdoptLowerReading() {
        let vehicle = makeVehicle(currentMileage: 33_000, updatedAt: daysAgo(5))

        let outcome = MileageCommit.commitIfNewest(
            reading: 30_000,
            observedAt: .now,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertFalse(outcome.didAdopt)
        XCTAssertFalse(outcome.wasSupersededByNewerReading, "lower-than-current is not the same as superseded")
        XCTAssertEqual(vehicle.currentMileage, 33_000)
    }

    /// Previously the completion sheet wrote a snapshot unconditionally, so a
    /// below-current reading recorded a *lower* mileage at a *later* timestamp
    /// — showing the pace calculation a negative delta.
    func test_commitIfNewest_writesNoSnapshotForLowerReading() {
        let vehicle = makeVehicle(currentMileage: 33_000, updatedAt: daysAgo(5))

        MileageCommit.commitIfNewest(
            reading: 30_000,
            observedAt: .now,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertTrue(snapshots(for: vehicle).isEmpty)
    }

    func test_commitIfNewest_doesNotAdoptEqualReading() {
        let vehicle = makeVehicle(currentMileage: 33_000, updatedAt: daysAgo(5))

        let outcome = MileageCommit.commitIfNewest(
            reading: 33_000,
            observedAt: .now,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertFalse(outcome.didAdopt)
        XCTAssertTrue(snapshots(for: vehicle).isEmpty)
    }

    // MARK: - Vehicle with no reading on file

    /// With no prior reading there is nothing to supersede, so the observation
    /// is adopted and dated honestly — even if it is old. The estimate engine
    /// then projects forward from the real observation date.
    func test_commitIfNewest_adoptsOldReadingWhenNoPriorUpdateExists() throws {
        let vehicle = makeVehicle(currentMileage: 0, updatedAt: nil)
        let observedAt = daysAgo(400)

        let outcome = MileageCommit.commitIfNewest(
            reading: 28_000,
            observedAt: observedAt,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        XCTAssertTrue(outcome.didAdopt)
        XCTAssertEqual(vehicle.currentMileage, 28_000)
        let recordedAt = try XCTUnwrap(vehicle.mileageUpdatedAt)
        XCTAssertEqual(
            recordedAt.timeIntervalSince1970,
            observedAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    // MARK: - wouldAdopt agrees with commitIfNewest

    /// `wouldAdopt` drives the pre-save advisory. If it disagreed with the
    /// commit, the form would promise one thing and do another (F4's rationale
    /// applied to mileage).
    func test_wouldAdopt_matchesCommitOutcomeAcrossCases() {
        let cases: [(current: Int, updatedAt: Date?, reading: Int, observedAt: Date)] = [
            (32_500, daysAgo(21), 33_100, daysAgo(1)),
            (33_000, daysAgo(2), 40_000, daysAgo(900)),
            (33_000, daysAgo(5), 30_000, .now),
            (33_000, daysAgo(5), 33_000, .now),
            (0, nil, 28_000, daysAgo(400))
        ]

        for (index, testCase) in cases.enumerated() {
            let predictionVehicle = makeVehicle(
                currentMileage: testCase.current,
                updatedAt: testCase.updatedAt
            )
            let predicted = MileageCommit.wouldAdopt(
                reading: testCase.reading,
                observedAt: testCase.observedAt,
                for: predictionVehicle
            )

            let commitVehicle = makeVehicle(
                currentMileage: testCase.current,
                updatedAt: testCase.updatedAt
            )
            let actual = MileageCommit.commitIfNewest(
                reading: testCase.reading,
                observedAt: testCase.observedAt,
                source: .serviceCompletion,
                for: commitVehicle,
                in: modelContext
            ).didAdopt

            XCTAssertEqual(predicted, actual, "case \(index): preview disagreed with commit")
        }
    }

    // MARK: - Advisory copy

    func test_adoptionSummary_presentOnlyWhenAdopted() {
        let vehicle = makeVehicle(currentMileage: 32_500, updatedAt: daysAgo(21))

        let adopted = MileageCommit.commitIfNewest(
            reading: 33_100,
            observedAt: daysAgo(1),
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )
        XCTAssertNotNil(adopted.adoptionSummary)

        let rejected = MileageCommit.Outcome.notAdopted(previousMileage: 33_100, reading: 100)
        XCTAssertNil(rejected.adoptionSummary)
    }
}
