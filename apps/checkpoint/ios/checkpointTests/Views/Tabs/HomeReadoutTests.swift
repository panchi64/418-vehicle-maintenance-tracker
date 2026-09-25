//
//  HomeReadoutTests.swift
//  checkpointTests
//
//  Home's decisions: which trigger the Next Up hero shows, which single
//  suggestion takes the slot, and where "Mark Renewed" moves the marbete.
//

import XCTest
@testable import checkpoint

@MainActor
final class HomeReadoutTests: XCTestCase {

    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - NextUpReadout: closer trigger leads

    func test_service_mileageCloserThanDate_leadsWithDistance() {
        let now = date(2026, 9, 1)
        // 400 mi at 40 mi/day = 10 days; date is 60 days out.
        let service = Service(name: "Oil", dueDate: date(2026, 10, 31), dueMileage: 30_400)
        let readout = NextUpReadout.service(service, currentMileage: 30_000, dailyPace: 40, now: now)
        XCTAssertEqual(readout.figure, .distance(400))
        XCTAssertFalse(readout.isPast)
    }

    func test_service_dateCloserThanMileage_leadsWithDays() {
        let now = date(2026, 9, 1)
        // 2,000 mi at 40 mi/day = 50 days; date is 5 days out.
        let service = Service(name: "Oil", dueDate: date(2026, 9, 6), dueMileage: 32_000)
        let readout = NextUpReadout.service(service, currentMileage: 30_000, dailyPace: 40, now: now)
        XCTAssertEqual(readout.figure, .days(5))
    }

    func test_service_mileagePastDue_leadsWithNegativeDistance() {
        let now = date(2026, 9, 1)
        let service = Service(name: "Oil", dueDate: date(2026, 9, 20), dueMileage: 29_083)
        let readout = NextUpReadout.service(service, currentMileage: 30_000, dailyPace: 40, now: now)
        XCTAssertEqual(readout.figure, .distance(-917))
        XCTAssertTrue(readout.isPast)
    }

    func test_service_withoutPace_usesFallbackPace() {
        let now = date(2026, 9, 1)
        // At the 40 mi/day fallback, 800 mi = 20 days < 30 days.
        let service = Service(name: "Oil", dueDate: date(2026, 10, 1), dueMileage: 30_800)
        let readout = NextUpReadout.service(service, currentMileage: 30_000, dailyPace: nil, now: now)
        XCTAssertEqual(readout.figure, .distance(800))
    }

    func test_service_dateOnly_leadsWithDays() {
        let now = date(2026, 9, 1)
        let service = Service(name: "Wipers", dueDate: date(2026, 8, 29))
        let readout = NextUpReadout.service(service, currentMileage: 30_000, dailyPace: 40, now: now)
        XCTAssertEqual(readout.figure, .days(-3))
        XCTAssertTrue(readout.isPast)
    }

    func test_marbete_isAlwaysDays() {
        let readout = NextUpReadout.marbete(daysUntilExpiration: 1)
        XCTAssertEqual(readout.kind, .marbete)
        XCTAssertEqual(readout.figure, .days(1))
    }

    // MARK: - Due line

    func test_dueLine_bothTriggers_isOneLine() {
        let service = Service(name: "Oil", dueDate: date(2026, 7, 4), dueMileage: 32_500)
        let line = NextUpCard.dueLine(for: service)
        XCTAssertFalse(line.isEmpty)
        XCTAssertFalse(line.contains("\n"))
    }

    func test_dueLine_noTriggers_isEmpty() {
        XCTAssertEqual(NextUpCard.dueLine(for: Service(name: "Log only")), "")
    }

    // MARK: - Suggestion slot

    private func makeCluster() -> ServiceCluster {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30_000)
        let a = Service(name: "Oil", dueMileage: 30_500)
        let b = Service(name: "Rotation", dueMileage: 30_700)
        return ServiceCluster(services: [a, b], anchorService: a, vehicle: vehicle, mileageWindow: 1000, daysWindow: 30)
    }

    func test_suggestion_clusterBeatsSeasonal() {
        let cluster = makeCluster()
        let pick = HomeSuggestion.pick(
            cluster: cluster,
            dismissedClusterHashes: [],
            clusteringEnabled: true,
            seasonal: Array(SeasonalReminder.allReminders.prefix(1))
        )
        guard case .cluster = pick else { return XCTFail("Expected the cluster") }
    }

    func test_suggestion_dismissedCluster_fallsBackToSeasonal() {
        let cluster = makeCluster()
        let pick = HomeSuggestion.pick(
            cluster: cluster,
            dismissedClusterHashes: [cluster.contentHash],
            clusteringEnabled: true,
            seasonal: Array(SeasonalReminder.allReminders.prefix(2))
        )
        guard case .seasonal(let reminder) = pick else { return XCTFail("Expected a seasonal item") }
        XCTAssertEqual(reminder.id, SeasonalReminder.allReminders[0].id)
    }

    func test_suggestion_clusteringDisabled_ignoresCluster() {
        let pick = HomeSuggestion.pick(
            cluster: makeCluster(),
            dismissedClusterHashes: [],
            clusteringEnabled: false,
            seasonal: []
        )
        XCTAssertNil(pick)
    }

    // MARK: - Marbete renewal

    func test_renewal_movesOneYear() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        vehicle.marbeteExpirationMonth = 10
        vehicle.marbeteExpirationYear = 2026
        let renewed = vehicle.renewedMarbeteExpiration(now: date(2026, 9, 15))
        XCTAssertEqual(renewed, Vehicle.MarbeteExpiration(month: 10, year: 2027))
    }

    func test_renewal_longLapsed_landsInTheFuture() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        vehicle.marbeteExpirationMonth = 3
        vehicle.marbeteExpirationYear = 2023
        let renewed = vehicle.renewedMarbeteExpiration(now: date(2026, 9, 15))
        XCTAssertEqual(renewed, Vehicle.MarbeteExpiration(month: 3, year: 2027))
    }

    func test_renewal_withoutMarbete_isNil() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        XCTAssertNil(vehicle.renewedMarbeteExpiration())
    }

    func test_applyMarbeteExpiration_setsBothFields() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        vehicle.applyMarbeteExpiration(.init(month: 5, year: 2028))
        XCTAssertEqual(vehicle.marbeteExpirationMonth, 5)
        XCTAssertEqual(vehicle.marbeteExpirationYear, 2028)
    }
}
