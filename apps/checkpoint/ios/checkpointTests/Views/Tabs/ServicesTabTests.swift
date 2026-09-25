//
//  ServicesTabTests.swift
//  checkpointTests
//
//  The Services list's grouping and search (`ServicesTabContent`), its
//  selection state, and Stop Tracking.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServicesTabTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    private var mileage: MileageEstimate {
        MileageEstimate(pace: nil, effective: 30_000, isEstimated: false)
    }

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30_000)
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        vehicle = nil
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    private func service(_ name: String, dueMileage: Int?) -> Service {
        let service = Service(name: name, dueMileage: dueMileage)
        service.vehicle = vehicle
        modelContext.insert(service)
        return service
    }

    @MainActor
    private func log(_ service: Service?, on date: Date, notes: String? = nil) -> ServiceLog {
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: date, mileageAtService: 29_000)
        log.notes = notes
        modelContext.insert(log)
        return log
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - Status groups

    @MainActor
    func testStatusGroups_OrderedOverdueDueSoonOnTrack() {
        let good = service("Tire Rotation", dueMileage: 45_000)
        let overdue = service("Oil Change", dueMileage: 29_000)
        let dueSoon = service("Air Filter", dueMileage: 30_050)

        let content = ServicesTabContent.make(
            services: [good, overdue, dueSoon], logs: [], mileage: mileage, searchText: ""
        )

        XCTAssertEqual(content.statusGroups.map(\.status), [.overdue, .dueSoon, .good])
        XCTAssertEqual(content.statusGroups.map { $0.services.map(\.name) }, [["Oil Change"], ["Air Filter"], ["Tire Rotation"]])
    }

    @MainActor
    func testStatusGroups_EmptyGroupsOmitted() {
        let good = service("Tire Rotation", dueMileage: 45_000)

        let content = ServicesTabContent.make(services: [good], logs: [], mileage: mileage, searchText: "")

        XCTAssertEqual(content.statusGroups.map(\.status), [.good])
    }

    @MainActor
    func testStatusGroups_ExcludeUntrackedServices() {
        let logOnly = service("Wiper Blades", dueMileage: nil)

        let content = ServicesTabContent.make(services: [logOnly], logs: [], mileage: mileage, searchText: "")

        XCTAssertTrue(content.statusGroups.isEmpty)
        XCTAssertTrue(content.isEmpty)
    }

    // MARK: - History months

    @MainActor
    func testMonthGroups_KeepNewestFirstOrderAndSplitByMonth() {
        let oil = service("Oil Change", dueMileage: 35_000)
        let a = log(oil, on: date(2026, 7, 20))
        let b = log(oil, on: date(2026, 7, 2))
        let c = log(oil, on: date(2026, 5, 14))

        let content = ServicesTabContent.make(services: [], logs: [a, b, c], mileage: mileage, searchText: "")

        XCTAssertEqual(content.months.count, 2)
        XCTAssertEqual(content.months[0].logs.map(\.id), [a.id, b.id])
        XCTAssertEqual(content.months[1].logs.map(\.id), [c.id])
        XCTAssertEqual(
            content.months[0].month,
            Calendar.current.dateInterval(of: .month, for: date(2026, 7, 20))?.start
        )
    }

    // MARK: - Search

    @MainActor
    func testSearch_NarrowsServicesAndHistory() {
        let oil = service("Oil Change", dueMileage: 35_000)
        let tires = service("Tire Rotation", dueMileage: 36_000)
        let oilLog = log(oil, on: date(2026, 6, 1))
        let tireLog = log(tires, on: date(2026, 6, 2))

        let content = ServicesTabContent.make(
            services: [oil, tires], logs: [tireLog, oilLog], mileage: mileage, searchText: "OIL"
        )

        XCTAssertEqual(content.services.map(\.name), ["Oil Change"])
        XCTAssertEqual(content.logs.map(\.id), [oilLog.id])
    }

    @MainActor
    func testSearch_MatchesLogNotes() {
        let tires = service("Tire Rotation", dueMileage: 36_000)
        let noted = log(tires, on: date(2026, 6, 2), notes: "Costco, balanced all four")

        let content = ServicesTabContent.make(
            services: [], logs: [noted], mileage: mileage, searchText: "costco"
        )

        XCTAssertEqual(content.logs.map(\.id), [noted.id])
    }

    @MainActor
    func testSearch_NoMatchIsEmpty() {
        let oil = service("Oil Change", dueMileage: 35_000)

        let content = ServicesTabContent.make(services: [oil], logs: [], mileage: mileage, searchText: "brakes")

        XCTAssertTrue(content.isEmpty)
    }

    // MARK: - Selection state

    func testSetSelecting_ClearsSelection() {
        var state = ServicesTabState()
        state.setSelecting(true)
        state.selection = [.service(UUID()), .log(UUID())]

        state.setSelecting(false)

        XCTAssertFalse(state.isSelecting)
        XCTAssertTrue(state.selection.isEmpty)
    }

    // MARK: - Stop tracking

    @MainActor
    func testStopTracking_ClearsScheduleWithoutWritingALog() {
        let oil = Service(name: "Oil Change", dueDate: date(2025, 1, 1), dueMileage: 29_000,
                          intervalMonths: 6, intervalMiles: 5_000, isRecurring: true)
        oil.vehicle = vehicle
        modelContext.insert(oil)

        oil.stopTracking()

        XCTAssertFalse(oil.hasDueTracking)
        XCTAssertFalse(oil.isRecurring)
        XCTAssertTrue((oil.logs ?? []).isEmpty)
        // The policy survives, so the service can be re-armed from it.
        XCTAssertEqual(oil.intervalMonths, 6)
        XCTAssertEqual(oil.intervalMiles, 5_000)
        // And it leaves the status groups.
        let content = ServicesTabContent.make(services: [oil], logs: [], mileage: mileage, searchText: "")
        XCTAssertTrue(content.statusGroups.isEmpty)
    }

    @MainActor
    func testStopTracking_RestoreUndoesIt() {
        let due = date(2025, 1, 1)
        let oil = Service(name: "Oil Change", dueDate: due, dueMileage: 29_000, isRecurring: true)
        modelContext.insert(oil)

        let snapshot = oil.stopTracking()
        oil.restoreTracking(snapshot)

        XCTAssertEqual(oil.dueDate, due)
        XCTAssertEqual(oil.dueMileage, 29_000)
        XCTAssertTrue(oil.isRecurring)
    }
}
