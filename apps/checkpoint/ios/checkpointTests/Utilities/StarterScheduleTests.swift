//
//  StarterScheduleTests.swift
//  checkpointTests
//
//  Due-date derivation for the starter schedule offered after a vehicle is
//  added: known last-done anchors its own dimension, unknown counts from now.
//

import XCTest
@testable import checkpoint

@MainActor
final class StarterScheduleTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_790_000_000)
    private let calendar = Calendar.current

    private func item(months: Int? = 6, miles: Int? = 5000, lastDone: StarterLastDone = .unknown) -> StarterScheduleItem {
        StarterScheduleItem(
            name: "Oil Change", category: "engine",
            intervalMonths: months, intervalMiles: miles,
            lastDone: lastDone
        )
    }

    private func months(_ value: Int, from date: Date) -> Date? {
        calendar.date(byAdding: .month, value: value, to: date)
    }

    // MARK: - Catalog

    func test_items_takesCommonPresetsInOrderWithCatalogIntervals() {
        let presets = [
            PresetData(name: "Tire Rotation", category: "tires", defaultIntervalMonths: 6, defaultIntervalMiles: 5000),
            PresetData(name: "Oil Change", category: "engine", defaultIntervalMonths: 6, defaultIntervalMiles: 5000),
            PresetData(name: "Spark Plugs", category: "engine", defaultIntervalMonths: 36, defaultIntervalMiles: 30000),
        ]
        let items = StarterSchedule.items(from: presets)
        XCTAssertEqual(items.map(\.name), ["Oil Change", "Tire Rotation"], "Only common services, in list order")
        XCTAssertTrue(items.allSatisfy(\.isIncluded), "Accepting the defaults must be one tap")
        XCTAssertTrue(items.allSatisfy { $0.lastDone == .unknown })
    }

    func test_items_skipsServicesTheVehicleAlreadyTracks() {
        let presets = [PresetData(name: "Oil Change", category: "engine", defaultIntervalMonths: 6, defaultIntervalMiles: 5000)]
        XCTAssertTrue(StarterSchedule.items(from: presets, excluding: ["oil change"]).isEmpty)
    }

    func test_items_skipsPresetsWithoutAnInterval() {
        let presets = [PresetData(name: "Wiper Blades", category: "body", defaultIntervalMonths: nil, defaultIntervalMiles: nil)]
        XCTAssertTrue(StarterSchedule.items(from: presets).isEmpty)
    }

    func test_items_realCatalog_offersBundledCommonServices() {
        let items = StarterSchedule.items(from: PresetDataService.shared.loadPresets())
        XCTAssertFalse(items.isEmpty)
        XCTAssertEqual(items.first?.name, "Oil Change")
    }

    // MARK: - Unknown: count from now

    func test_plan_unknown_anchorsBothDimensionsOnNow() {
        let plan = StarterSchedule.plan(for: item(), currentMileage: 60_000, now: now)
        XCTAssertEqual(plan.dueDate, months(6, from: now))
        XCTAssertEqual(plan.dueMileage, 65_000)
        XCTAssertNil(plan.lastPerformed)
        XCTAssertNil(plan.lastMileage)
    }

    // MARK: - Known date

    func test_plan_knownDate_anchorsDateOnIt_andMileageOnNow() {
        let lastDone = months(-4, from: now)!
        let plan = StarterSchedule.plan(for: item(lastDone: .date(lastDone)), currentMileage: 60_000, now: now)
        XCTAssertEqual(plan.dueDate, months(2, from: now), "6-month interval from 4 months ago")
        XCTAssertEqual(plan.dueMileage, 65_000, "A known date still gets a mileage backstop")
        XCTAssertEqual(plan.lastPerformed, lastDone)
        XCTAssertNil(plan.lastMileage)
    }

    func test_plan_knownDate_longAgo_isAlreadyOverdue() {
        let lastDone = months(-9, from: now)!
        let plan = StarterSchedule.plan(for: item(lastDone: .date(lastDone)), currentMileage: 60_000, now: now)
        XCTAssertLessThan(plan.dueDate!, now, "Truthful history can make a service overdue on day one")
    }

    func test_plan_futureDate_isClampedToNow() {
        let future = months(2, from: now)!
        let plan = StarterSchedule.plan(for: item(lastDone: .date(future)), currentMileage: 60_000, now: now)
        XCTAssertEqual(plan.lastPerformed, now)
        XCTAssertEqual(plan.dueDate, months(6, from: now))
    }

    // MARK: - Known mileage

    func test_plan_knownMileage_anchorsMileageOnIt_andDateOnNow() {
        let plan = StarterSchedule.plan(for: item(lastDone: .mileage(58_000)), currentMileage: 60_000, now: now)
        XCTAssertEqual(plan.dueMileage, 63_000)
        XCTAssertEqual(plan.dueDate, months(6, from: now))
        XCTAssertEqual(plan.lastMileage, 58_000)
        XCTAssertNil(plan.lastPerformed)
    }

    func test_plan_mileageAboveOdometer_isClampedToCurrent() {
        let plan = StarterSchedule.plan(for: item(lastDone: .mileage(90_000)), currentMileage: 60_000, now: now)
        XCTAssertEqual(plan.lastMileage, 60_000)
        XCTAssertEqual(plan.dueMileage, 65_000)
    }

    func test_plan_mileageForDateOnlyService_isIgnored() {
        let plan = StarterSchedule.plan(for: item(miles: nil, lastDone: .mileage(58_000)), currentMileage: 60_000, now: now)
        XCTAssertNil(plan.lastMileage)
        XCTAssertNil(plan.dueMileage)
        XCTAssertEqual(plan.dueDate, months(6, from: now))
    }

    // MARK: - Selection

    func test_plans_onlyIncludedItems() {
        var excluded = item()
        excluded.isIncluded = false
        let kept = StarterScheduleItem(name: "Tire Rotation", category: "tires", intervalMonths: 6, intervalMiles: 5000)
        let plans = StarterSchedule.plans(for: [excluded, kept], currentMileage: 1000, now: now)
        XCTAssertEqual(plans.map(\.name), ["Tire Rotation"])
    }
}
