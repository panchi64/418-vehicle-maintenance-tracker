//
//  ServiceLogHistoryTests.swift
//  checkpointTests
//
//  Tests for Array+ServiceLogHistory helpers used by the Record Service
//  flow to anchor users in their own past entries.
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceLogHistoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!
    var otherVehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
        otherVehicle = Vehicle(name: "Project", make: "Mazda", model: "MX-5", year: 1999, currentMileage: 80000)
        modelContext.insert(vehicle)
        modelContext.insert(otherVehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        otherVehicle = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeLog(
        name: String,
        date: Date,
        mileage: Int,
        cost: Decimal? = nil,
        vehicle: Vehicle? = nil
    ) -> ServiceLog {
        let target = vehicle ?? self.vehicle!
        let service = Service(name: name)
        service.vehicle = target
        modelContext.insert(service)
        let log = ServiceLog(
            service: service,
            vehicle: target,
            performedDate: date,
            mileageAtService: mileage,
            cost: cost
        )
        modelContext.insert(log)
        return log
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents(); c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    // MARK: - mostRecent

    @MainActor
    func testMostRecent_ReturnsNilWhenNoMatch() {
        _ = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 45)
        let logs = [ServiceLog]()
        XCTAssertNil(logs.mostRecent(serviceName: "Oil Change", vehicle: vehicle))
    }

    @MainActor
    func testMostRecent_ReturnsNewestMatch() {
        let older = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 45)
        let newer = makeLog(name: "Oil Change", date: date(2025, 7, 1), mileage: 35000, cost: 50)
        let logs = [older, newer]
        XCTAssertEqual(logs.mostRecent(serviceName: "Oil Change", vehicle: vehicle)?.id, newer.id)
    }

    @MainActor
    func testMostRecent_IsCaseInsensitive() {
        let log = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 45)
        let logs = [log]
        XCTAssertNotNil(logs.mostRecent(serviceName: "oil change", vehicle: vehicle))
        XCTAssertNotNil(logs.mostRecent(serviceName: "OIL CHANGE", vehicle: vehicle))
    }

    @MainActor
    func testMostRecent_IgnoresOtherVehicles() {
        let mine = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 45)
        let theirs = makeLog(name: "Oil Change", date: date(2025, 7, 1), mileage: 35000, cost: 50, vehicle: otherVehicle)
        let logs = [mine, theirs]
        XCTAssertEqual(logs.mostRecent(serviceName: "Oil Change", vehicle: vehicle)?.id, mine.id)
    }

    @MainActor
    func testMostRecent_IgnoresEmptyServiceName() {
        let log = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 45)
        XCTAssertNil([log].mostRecent(serviceName: "", vehicle: vehicle))
        XCTAssertNil([log].mostRecent(serviceName: "   ", vehicle: vehicle))
    }

    // MARK: - medianCost

    @MainActor
    func testMedianCost_NilWhenNoMatchingLogs() {
        XCTAssertNil([ServiceLog]().medianCost(serviceName: "Oil Change", vehicle: vehicle))
    }

    @MainActor
    func testMedianCost_NilWhenNoCostsRecorded() {
        let log = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: nil)
        XCTAssertNil([log].medianCost(serviceName: "Oil Change", vehicle: vehicle))
    }

    @MainActor
    func testMedianCost_OddCount_ReturnsMiddle() {
        let l1 = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 40)
        let l2 = makeLog(name: "Oil Change", date: date(2025, 4, 1), mileage: 31000, cost: 50)
        let l3 = makeLog(name: "Oil Change", date: date(2025, 7, 1), mileage: 32000, cost: 60)
        XCTAssertEqual([l1, l2, l3].medianCost(serviceName: "Oil Change", vehicle: vehicle), 50)
    }

    @MainActor
    func testMedianCost_EvenCount_ReturnsAverageOfMiddleTwo() {
        let l1 = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000, cost: 40)
        let l2 = makeLog(name: "Oil Change", date: date(2025, 4, 1), mileage: 31000, cost: 60)
        XCTAssertEqual([l1, l2].medianCost(serviceName: "Oil Change", vehicle: vehicle), 50)
    }

    // MARK: - maxMileage

    @MainActor
    func testMaxMileage_NilWhenEmpty() {
        XCTAssertNil([ServiceLog]().maxMileage(vehicle: vehicle))
    }

    @MainActor
    func testMaxMileage_ReturnsHighestAcrossAllServiceTypes() {
        let l1 = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000)
        let l2 = makeLog(name: "Tire Rotation", date: date(2025, 4, 1), mileage: 31500)
        let l3 = makeLog(name: "Brake Service", date: date(2025, 7, 1), mileage: 31000)
        XCTAssertEqual([l1, l2, l3].maxMileage(vehicle: vehicle), 31500)
    }

    @MainActor
    func testMaxMileage_IgnoresOtherVehicles() {
        let mine = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000)
        let theirs = makeLog(name: "Oil Change", date: date(2025, 4, 1), mileage: 90000, vehicle: otherVehicle)
        XCTAssertEqual([mine, theirs].maxMileage(vehicle: vehicle), 30000)
    }

    // MARK: - topPresetChips

    private func presets(_ names: [String]) -> [PresetData] {
        names.map { PresetData(name: $0, category: "Engine", defaultIntervalMonths: nil, defaultIntervalMiles: nil) }
    }

    @MainActor
    func testTopPresetChips_FallsBackToStartersWithoutEnoughHistory() {
        let allPresets = presets(["Oil Change", "Tire Rotation", "Brake Service", "Inspection", "Wax"])
        // Only 2 logs — falls below the 3-log threshold.
        _ = makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000)
        _ = makeLog(name: "Oil Change", date: date(2025, 4, 1), mileage: 31000)

        let chips = [ServiceLog]().topPresetChips(for: vehicle, from: allPresets, limit: 4)

        XCTAssertEqual(chips.map(\.name), ["Oil Change", "Tire Rotation", "Brake Service", "Inspection"])
    }

    @MainActor
    func testTopPresetChips_RanksByFrequencyWithEnoughHistory() {
        let allPresets = presets(["Oil Change", "Tire Rotation", "Brake Service", "Inspection", "Wax"])
        let logs = [
            makeLog(name: "Tire Rotation", date: date(2025, 1, 1), mileage: 30000),
            makeLog(name: "Tire Rotation", date: date(2025, 4, 1), mileage: 31000),
            makeLog(name: "Oil Change", date: date(2025, 7, 1), mileage: 32000),
            makeLog(name: "Tire Rotation", date: date(2025, 10, 1), mileage: 33000),
        ]

        let chips = logs.topPresetChips(for: vehicle, from: allPresets, limit: 4)

        // Tire Rotation (3x) should rank above Oil Change (1x).
        XCTAssertEqual(chips.first?.name, "Tire Rotation")
        XCTAssertTrue(chips.map(\.name).contains("Oil Change"))
    }

    @MainActor
    func testTopPresetChips_PadsWithStartersWhenHistoryIsSparse() {
        let allPresets = presets(["Oil Change", "Tire Rotation", "Brake Service", "Inspection"])
        // 3 logs but all for the same custom-named service that doesn't match a preset.
        let logs = [
            makeLog(name: "Custom Detailing", date: date(2025, 1, 1), mileage: 30000),
            makeLog(name: "Custom Detailing", date: date(2025, 4, 1), mileage: 31000),
            makeLog(name: "Custom Detailing", date: date(2025, 7, 1), mileage: 32000),
        ]

        let chips = logs.topPresetChips(for: vehicle, from: allPresets, limit: 4)

        // No frequency matches → falls through entirely to starters.
        XCTAssertEqual(chips.map(\.name), ["Oil Change", "Tire Rotation", "Brake Service", "Inspection"])
    }

    @MainActor
    func testTopPresetChips_RespectsLimit() {
        let allPresets = presets(["Oil Change", "Tire Rotation", "Brake Service", "Inspection"])
        let chips = [ServiceLog]().topPresetChips(for: vehicle, from: allPresets, limit: 2)
        XCTAssertEqual(chips.count, 2)
    }

    @MainActor
    func testTopPresetChips_DeduplicatesBetweenFrequencyAndStarters() {
        let allPresets = presets(["Oil Change", "Tire Rotation", "Brake Service", "Inspection"])
        let logs = [
            makeLog(name: "Oil Change", date: date(2025, 1, 1), mileage: 30000),
            makeLog(name: "Oil Change", date: date(2025, 4, 1), mileage: 31000),
            makeLog(name: "Oil Change", date: date(2025, 7, 1), mileage: 32000),
        ]
        let chips = logs.topPresetChips(for: vehicle, from: allPresets, limit: 4)
        // Oil Change appears once, not twice.
        XCTAssertEqual(chips.filter { $0.name == "Oil Change" }.count, 1)
    }
}
