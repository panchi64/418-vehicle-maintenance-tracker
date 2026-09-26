//
//  ServiceLogAnalyticsTests.swift
//  checkpointTests
//
//  Tests for the visit-aware per-log cost helpers on ServiceLog: ensures
//  un-itemized visit logs don't show per-log money, and that edited costs
//  land where the cost analytics read them.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceLogAnalyticsTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - attributableCost

    func test_attributableCost_standaloneLog_returnsCost() {
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)
        XCTAssertEqual(log.attributableCost, 50)
    }

    func test_attributableCost_unitemizedVisitLog_returnsNil() {
        let visit = ServiceVisit(totalCost: 200, isItemized: false)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)
        log.visit = visit
        XCTAssertNil(log.attributableCost)
    }

    func test_attributableCost_itemizedVisitLog_returnsLogCost() {
        let visit = ServiceVisit(totalCost: 200, isItemized: true)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)
        log.visit = visit
        XCTAssertEqual(log.attributableCost, 50)
    }

    // MARK: - applyEditedCost

    func test_applyEditedCost_standaloneLog_writesLog() {
        let log = ServiceLog(performedDate: .now, mileageAtService: 0)
        log.applyEditedCost(80, category: .repair)
        XCTAssertEqual(log.cost, 80)
        XCTAssertEqual(log.costCategory, .repair)
    }

    func test_applyEditedCost_unitemizedVisitLog_writesVisitTotal() {
        let visit = ServiceVisit(isItemized: false)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0)
        log.visit = visit

        log.applyEditedCost(150, category: .maintenance)

        XCTAssertEqual(visit.totalCost, 150)
        XCTAssertEqual(visit.costCategory, .maintenance)
        XCTAssertNil(log.cost)
        XCTAssertNil(log.costCategory)
        XCTAssertEqual(log.editableCost, 150)
    }

    func test_applyEditedCost_itemizedVisitLog_writesLog() {
        let visit = ServiceVisit(totalCost: 200, isItemized: true)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0)
        log.visit = visit

        log.applyEditedCost(50, category: .maintenance)

        XCTAssertEqual(log.cost, 50)
        XCTAssertEqual(visit.totalCost, 200)
    }

    func test_applyEditedCost_clearingVisitCost_clearsCategory() {
        let visit = ServiceVisit(totalCost: 90, costCategory: .repair, isItemized: false)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0)
        log.visit = visit

        log.applyEditedCost(nil, category: .repair)

        XCTAssertNil(visit.totalCost)
        XCTAssertNil(visit.costCategory)
    }

    func test_editableCost_strandedCostOnVisitLog_surfacesForCorrection() {
        let visit = ServiceVisit(isItemized: false)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 40, costCategory: .upgrade)
        log.visit = visit
        XCTAssertEqual(log.editableCost, 40)
        XCTAssertEqual(log.editableCostCategory, .upgrade)
    }

    // MARK: - Stranded visit-cost backfill

    func test_backfillStrandedVisitCosts_movesChildCostsOntoVisitTotal() throws {
        let visit = ServiceVisit(isItemized: false)
        modelContext.insert(visit)
        let priced = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 70, costCategory: .repair)
        let unpriced = ServiceLog(performedDate: .now, mileageAtService: 0)
        for log in [priced, unpriced] {
            log.visit = visit
            modelContext.insert(log)
        }

        ServiceMigrationService.backfillStrandedVisitCosts(in: modelContext)

        XCTAssertEqual(visit.totalCost, 70)
        XCTAssertEqual(visit.costCategory, .repair)
        XCTAssertNil(priced.cost)
        XCTAssertEqual(CostAnalyticsService.totalSpent(on: [priced, unpriced]), 70)
    }

    func test_backfillStrandedVisitCosts_leavesExistingTotalAlone() throws {
        let visit = ServiceVisit(totalCost: 300, costCategory: .maintenance, isItemized: false)
        modelContext.insert(visit)
        let log = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 70, costCategory: .repair)
        log.visit = visit
        modelContext.insert(log)

        ServiceMigrationService.backfillStrandedVisitCosts(in: modelContext)

        XCTAssertEqual(visit.totalCost, 300)
        XCTAssertEqual(log.cost, 70)
    }
}
