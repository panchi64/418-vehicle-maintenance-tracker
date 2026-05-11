//
//  ServiceVisitBackfillTests.swift
//  checkpointTests
//
//  Tests for the one-time backfill that converts legacy "divide cluster
//  total by N" data into Service Visits.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceVisitBackfillTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
                ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self,
                ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        ServiceVisitBackfill.resetForTests()
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        ServiceVisitBackfill.resetForTests()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeVehicle() -> Vehicle {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        modelContext.insert(vehicle)
        return vehicle
    }

    private func makeService(name: String, vehicle: Vehicle) -> Service {
        let service = Service(name: name)
        service.vehicle = vehicle
        modelContext.insert(service)
        return service
    }

    private func makeLog(
        service: Service,
        vehicle: Vehicle,
        date: Date,
        mileage: Int,
        cost: Decimal?,
        category: CostCategory? = nil
    ) -> ServiceLog {
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: date,
            mileageAtService: mileage,
            cost: cost,
            costCategory: category,
            notes: nil
        )
        modelContext.insert(log)
        return log
    }

    private func fetchVisits() -> [ServiceVisit] {
        (try? modelContext.fetch(FetchDescriptor<ServiceVisit>())) ?? []
    }

    private func fetchLogs() -> [ServiceLog] {
        (try? modelContext.fetch(FetchDescriptor<ServiceLog>())) ?? []
    }

    // MARK: - Tests

    func test_backfill_singletonGroup_isLeftAlone() throws {
        let vehicle = makeVehicle()
        let service = makeService(name: "Oil Change", vehicle: vehicle)
        _ = makeLog(service: service, vehicle: vehicle, date: .now, mileage: 32000, cost: 50)

        try ServiceVisitBackfill.perform(context: modelContext)

        XCTAssertEqual(fetchVisits().count, 0)
        XCTAssertEqual(fetchLogs().first?.cost, 50)
    }

    func test_backfill_clusteredGroup_groupsAndRecoversTotal() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Tire Rotation", vehicle: vehicle)
        let s3 = makeService(name: "Air Filter", vehicle: vehicle)
        let date = Date.now
        // Three legacy logs sharing date+mileage with divided shares.
        // Implied original total: 100 + 100 + 100 = 300.
        _ = makeLog(service: s1, vehicle: vehicle, date: date, mileage: 32000, cost: 100, category: .maintenance)
        _ = makeLog(service: s2, vehicle: vehicle, date: date, mileage: 32000, cost: 100, category: .maintenance)
        _ = makeLog(service: s3, vehicle: vehicle, date: date, mileage: 32000, cost: 100, category: .maintenance)

        try ServiceVisitBackfill.perform(context: modelContext)

        let visits = fetchVisits()
        XCTAssertEqual(visits.count, 1)
        let visit = visits[0]
        XCTAssertEqual(visit.totalCost, 300)
        XCTAssertEqual(visit.mileageAtVisit, 32000)
        XCTAssertEqual(visit.costCategory, .maintenance)
        XCTAssertFalse(visit.isItemized)

        // All three logs should be re-parented and have their per-service costs blanked.
        let logs = fetchLogs()
        XCTAssertEqual(logs.count, 3)
        for log in logs {
            XCTAssertEqual(log.visit?.id, visit.id)
            XCTAssertNil(log.cost)
            XCTAssertNil(log.costCategory)
        }
    }

    func test_backfill_groupsByDateAndMileage_keepsSeparateClustersSeparate() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Brakes", vehicle: vehicle)
        let date = Date.now
        // Cluster A: date, 32000, 2 logs.
        _ = makeLog(service: s1, vehicle: vehicle, date: date, mileage: 32000, cost: 50)
        _ = makeLog(service: s2, vehicle: vehicle, date: date, mileage: 32000, cost: 50)
        // Cluster B: same date, different mileage, 2 logs.
        _ = makeLog(service: s1, vehicle: vehicle, date: date, mileage: 35000, cost: 60)
        _ = makeLog(service: s2, vehicle: vehicle, date: date, mileage: 35000, cost: 60)

        try ServiceVisitBackfill.perform(context: modelContext)

        let visits = fetchVisits()
        XCTAssertEqual(visits.count, 2)
        XCTAssertEqual(Set(visits.compactMap(\.totalCost)), [100, 120])
    }

    func test_backfill_groupOfAllNilCosts_createsVisitWithNilTotal() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Brakes", vehicle: vehicle)
        _ = makeLog(service: s1, vehicle: vehicle, date: .now, mileage: 32000, cost: nil)
        _ = makeLog(service: s2, vehicle: vehicle, date: .now, mileage: 32000, cost: nil)

        try ServiceVisitBackfill.perform(context: modelContext)

        let visits = fetchVisits()
        XCTAssertEqual(visits.count, 1)
        XCTAssertNil(visits[0].totalCost)
    }

    func test_backfill_dedupesIdenticalAttachmentsAcrossClusterLogs() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Tire Rotation", vehicle: vehicle)
        let date = Date.now
        let log1 = makeLog(service: s1, vehicle: vehicle, date: date, mileage: 32000, cost: 50)
        let log2 = makeLog(service: s2, vehicle: vehicle, date: date, mileage: 32000, cost: 50)

        // Simulate the legacy code path: the same receipt attached to every
        // child log in the cluster (same fileName + mimeType, distinct UUIDs).
        let sharedFileName = "receipt_42.jpg"
        let sharedMime = "image/jpeg"
        let copy1 = ServiceAttachment(
            serviceLog: log1,
            data: Data([0x01]),
            fileName: sharedFileName,
            mimeType: sharedMime
        )
        let copy2 = ServiceAttachment(
            serviceLog: log2,
            data: Data([0x01]),
            fileName: sharedFileName,
            mimeType: sharedMime
        )
        modelContext.insert(copy1)
        modelContext.insert(copy2)

        try ServiceVisitBackfill.perform(context: modelContext)

        let attachments = try modelContext.fetch(FetchDescriptor<ServiceAttachment>())
        XCTAssertEqual(attachments.count, 1, "Identical legacy copies should collapse to one attachment per visit.")
        XCTAssertEqual(attachments.first?.fileName, sharedFileName)
    }

    func test_backfill_preservesDistinctAttachmentsWithinVisit() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Tire Rotation", vehicle: vehicle)
        let date = Date.now
        let log1 = makeLog(service: s1, vehicle: vehicle, date: date, mileage: 32000, cost: 50)
        let log2 = makeLog(service: s2, vehicle: vehicle, date: date, mileage: 32000, cost: 50)

        // Two genuinely distinct receipts — different fileNames.
        let receiptA = ServiceAttachment(
            serviceLog: log1,
            data: Data([0x01]),
            fileName: "receipt_A.jpg",
            mimeType: "image/jpeg"
        )
        let receiptB = ServiceAttachment(
            serviceLog: log2,
            data: Data([0x02]),
            fileName: "receipt_B.jpg",
            mimeType: "image/jpeg"
        )
        modelContext.insert(receiptA)
        modelContext.insert(receiptB)

        try ServiceVisitBackfill.perform(context: modelContext)

        let attachments = try modelContext.fetch(FetchDescriptor<ServiceAttachment>())
        XCTAssertEqual(attachments.count, 2, "Distinct attachments should survive the dedup pass.")
    }

    func test_runIfNeeded_isIdempotent() throws {
        let vehicle = makeVehicle()
        let s1 = makeService(name: "Oil Change", vehicle: vehicle)
        let s2 = makeService(name: "Brakes", vehicle: vehicle)
        _ = makeLog(service: s1, vehicle: vehicle, date: .now, mileage: 32000, cost: 50)
        _ = makeLog(service: s2, vehicle: vehicle, date: .now, mileage: 32000, cost: 50)

        ServiceVisitBackfill.runIfNeeded(context: modelContext)
        let visitsAfterFirst = fetchVisits().count

        ServiceVisitBackfill.runIfNeeded(context: modelContext)
        let visitsAfterSecond = fetchVisits().count

        XCTAssertEqual(visitsAfterFirst, 1)
        XCTAssertEqual(visitsAfterSecond, 1)  // didn't run again
    }
}
