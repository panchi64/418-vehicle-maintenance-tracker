//
//  ServiceVisitTests.swift
//  checkpointTests
//
//  Tests for ServiceVisit model and its reconciliation rules.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceVisitTests: XCTestCase {
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
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_init_storesAllProvidedFields() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let date = Date.now
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: date,
            mileageAtVisit: 32000,
            totalCost: Decimal(300),
            costCategory: .maintenance,
            isItemized: true,
            shopName: "Bob's Auto",
            notes: "Bundled visit"
        )

        XCTAssertNotNil(visit.vehicle)
        XCTAssertEqual(visit.performedDate, date)
        XCTAssertEqual(visit.mileageAtVisit, 32000)
        XCTAssertEqual(visit.totalCost, 300)
        XCTAssertEqual(visit.costCategory, .maintenance)
        XCTAssertTrue(visit.isItemized)
        XCTAssertEqual(visit.shopName, "Bob's Auto")
        XCTAssertEqual(visit.notes, "Bundled visit")
    }

    func test_init_defaultIsItemizedIsFalse() {
        let visit = ServiceVisit()
        XCTAssertFalse(visit.isItemized)
    }

    // MARK: - Reconciliation: Residual

    func test_reconciliationResidual_notItemized_returnsNil() {
        let visit = ServiceVisit(totalCost: 100, isItemized: false)
        XCTAssertNil(visit.reconciliationResidual)
    }

    func test_reconciliationResidual_itemizedWithNoTotal_returnsNil() {
        let visit = ServiceVisit(totalCost: nil, isItemized: true)
        XCTAssertNil(visit.reconciliationResidual)
    }

    func test_reconciliationResidual_underTotal_returnsPositive() {
        let visit = ServiceVisit(totalCost: 100, isItemized: true)
        let log1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 30)
        let log2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 40)
        log1.visit = visit
        log2.visit = visit
        visit.logs = [log1, log2]

        XCTAssertEqual(visit.reconciliationResidual, 30)
        XCTAssertEqual(visit.shopChargeResidual, 30)
        XCTAssertFalse(visit.hasOverflow)
    }

    func test_reconciliationResidual_overTotal_returnsNegativeAndFlagsOverflow() {
        let visit = ServiceVisit(totalCost: 50, isItemized: true)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 80)
        log.visit = visit
        visit.logs = [log]

        XCTAssertEqual(visit.reconciliationResidual, -30)
        XCTAssertNil(visit.shopChargeResidual)
        XCTAssertTrue(visit.hasOverflow)
    }

    // MARK: - Reconciliation: Itemized Sum

    func test_itemizedSum_includesLineItems() {
        let visit = ServiceVisit(totalCost: 200, isItemized: true)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)
        log.visit = visit
        visit.logs = [log]
        visit.lineItems = [
            VisitLineItem(visit: visit, label: "Tax", kind: .tax, amount: 10),
            VisitLineItem(visit: visit, label: "Tip", kind: .tip, amount: 20),
        ]

        XCTAssertEqual(visit.itemizedSum, 80)
        XCTAssertEqual(visit.reconciliationResidual, 120)
    }

    // MARK: - Occasion edits

    private func visitWithTwoLogs() -> (ServiceVisit, ServiceLog, ServiceLog) {
        let date = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        let visit = ServiceVisit(performedDate: date, mileageAtVisit: 30000)
        modelContext.insert(visit)
        let oil = ServiceLog(performedDate: date, mileageAtService: 30000)
        let filter = ServiceLog(performedDate: date, mileageAtService: 30000)
        for log in [oil, filter] {
            log.visit = visit
            modelContext.insert(log)
        }
        return (visit, oil, filter)
    }

    func test_applyEditedOccasion_movesVisitAndEverySibling() {
        let (visit, oil, filter) = visitWithTwoLogs()
        let newDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)!

        oil.applyEditedOccasion(performedDate: newDate, mileage: 30500)

        XCTAssertEqual(visit.performedDate, newDate)
        XCTAssertEqual(visit.mileageAtVisit, 30500)
        XCTAssertEqual(filter.performedDate, newDate, "A sibling must not keep the old date")
        XCTAssertEqual(filter.mileageAtService, 30500)
    }

    func test_applyEditedOccasion_nilMileageKeepsStoredMileage() {
        let (visit, oil, filter) = visitWithTwoLogs()

        oil.applyEditedOccasion(performedDate: .now, mileage: nil)

        XCTAssertEqual(visit.mileageAtVisit, 30000)
        XCTAssertEqual(filter.mileageAtService, 30000)
    }

    func test_applyEditedOccasion_standaloneLogMovesOnlyItself() {
        let log = ServiceLog(performedDate: .distantPast, mileageAtService: 100)
        let other = ServiceLog(performedDate: .distantPast, mileageAtService: 100)
        modelContext.insert(log)
        modelContext.insert(other)

        log.applyEditedOccasion(performedDate: .now, mileage: 200)

        XCTAssertEqual(log.mileageAtService, 200)
        XCTAssertEqual(other.mileageAtService, 100)
    }

    func test_anchorsNextReminder_onlyForNewestLogOfRecurringService() {
        let service = Service(name: "Oil Change", intervalMonths: 6)
        modelContext.insert(service)
        let older = ServiceLog(service: service, performedDate: .distantPast, mileageAtService: 0)
        let newer = ServiceLog(service: service, performedDate: .now, mileageAtService: 0)
        modelContext.insert(older)
        modelContext.insert(newer)

        XCTAssertTrue(newer.anchorsNextReminder)
        XCTAssertFalse(older.anchorsNextReminder)
    }
}
