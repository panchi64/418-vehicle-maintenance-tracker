//
//  ServiceLogAnalyticsTests.swift
//  checkpointTests
//
//  Tests for the visit-aware analytics helpers on ServiceLog: ensures
//  un-itemized visit logs don't contribute per-log money, and that visit
//  totals are counted exactly once when iterating a log set.
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceLogAnalyticsTests: XCTestCase {
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

    // MARK: - honestTotalCost

    func test_honestTotalCost_standaloneLogsOnly_sumsCosts() {
        let logs = [
            ServiceLog(performedDate: .now, mileageAtService: 0, cost: 30),
            ServiceLog(performedDate: .now, mileageAtService: 0, cost: 70),
            ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil),
        ]
        XCTAssertEqual(logs.honestTotalCost(), 100)
    }

    func test_honestTotalCost_unitemizedVisit_countsTotalOnce() {
        let visit = ServiceVisit(totalCost: 300, isItemized: false)
        let log1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        let log2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        let log3 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        log1.visit = visit
        log2.visit = visit
        log3.visit = visit

        // Sum across the three visit-bound logs MUST equal the visit total once,
        // not 3 * total. This is the bug-fix invariant.
        XCTAssertEqual([log1, log2, log3].honestTotalCost(), 300)
    }

    func test_honestTotalCost_itemizedVisit_sumsPerLogCosts() {
        let visit = ServiceVisit(totalCost: 100, isItemized: true)
        let log1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 40)
        let log2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 60)
        log1.visit = visit
        log2.visit = visit

        XCTAssertEqual([log1, log2].honestTotalCost(), 100)
    }

    func test_honestTotalCost_mixedStandaloneAndUnitemizedVisit_combinesCorrectly() {
        let visit = ServiceVisit(totalCost: 200, isItemized: false)
        let visitLog1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        let visitLog2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        visitLog1.visit = visit
        visitLog2.visit = visit
        let standalone = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)

        XCTAssertEqual([visitLog1, visitLog2, standalone].honestTotalCost(), 250)
    }

    // MARK: - distinctVisitCount

    func test_distinctVisitCount_unitemizedVisit_countsOnce() {
        let visit = ServiceVisit(totalCost: 200, isItemized: false)
        let log1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        let log2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        let log3 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        log1.visit = visit
        log2.visit = visit
        log3.visit = visit

        XCTAssertEqual([log1, log2, log3].distinctVisitCount(), 1)
    }

    func test_distinctVisitCount_mixedSet_combinesVisitsAndStandalone() {
        let visit = ServiceVisit(totalCost: 200, isItemized: false)
        let visitLog = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)
        visitLog.visit = visit
        let standalone1 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 50)
        let standalone2 = ServiceLog(performedDate: .now, mileageAtService: 0, cost: 30)
        let standaloneNoCost = ServiceLog(performedDate: .now, mileageAtService: 0, cost: nil)

        // 1 visit + 2 standalone with cost = 3. Standalone-no-cost is excluded.
        XCTAssertEqual([visitLog, standalone1, standalone2, standaloneNoCost].distinctVisitCount(), 3)
    }
}
