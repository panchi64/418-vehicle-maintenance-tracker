//
//  CostsTabInsightsTests.swift
//  checkpointTests
//
//  Tests the pure-data insights that power the redesigned Costs tab:
//  repair-cluster detection, anomaly detection, top-N extraction, and
//  year-end projection. The CostsTab view itself is hard to instantiate
//  in tests (it needs @Query + AppState), so the algorithms are reachable
//  through `CostsInsightsCore`.
//

import XCTest
import SwiftData
@testable import checkpoint

final class CostsTabInsightsTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self, ServiceVisit.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    private func makeLog(daysAgo: Int, cost: Decimal, category: CostCategory, mileage: Int = 30000) -> ServiceLog {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: date,
            mileageAtService: mileage,
            cost: cost,
            costCategory: category
        )
        modelContext.insert(log)
        return log
    }

    // MARK: - Repair Cluster Detection

    @MainActor
    func test_detectRepairCluster_emptyEvents_returnsNil() {
        XCTAssertNil(CostsInsightsCore.detectRepairCluster(events: []))
    }

    @MainActor
    func test_detectRepairCluster_singleRepair_returnsNil() {
        let log = makeLog(daysAgo: 10, cost: 500, category: .repair)
        let events: [ExpenseEvent] = [.standalone(log)]
        XCTAssertNil(CostsInsightsCore.detectRepairCluster(events: events))
    }

    @MainActor
    func test_detectRepairCluster_twoRepairsInWindow_returnsCluster() {
        let r1 = makeLog(daysAgo: 5, cost: 800, category: .repair)
        let r2 = makeLog(daysAgo: 60, cost: 400, category: .repair)
        let events: [ExpenseEvent] = [.standalone(r1), .standalone(r2)]

        let cluster = CostsInsightsCore.detectRepairCluster(events: events)
        XCTAssertNotNil(cluster)
        XCTAssertEqual(cluster?.count, 2)
        XCTAssertEqual(cluster?.totalAmount, Decimal(1200))
    }

    @MainActor
    func test_detectRepairCluster_repairsOutsideWindow_returnsNil() {
        let recent = makeLog(daysAgo: 5, cost: 800, category: .repair)
        let oldRepair = makeLog(daysAgo: 200, cost: 400, category: .repair)
        let events: [ExpenseEvent] = [.standalone(recent), .standalone(oldRepair)]
        XCTAssertNil(CostsInsightsCore.detectRepairCluster(events: events))
    }

    @MainActor
    func test_detectRepairCluster_maintenanceDoesNotCount() {
        let r = makeLog(daysAgo: 5, cost: 800, category: .repair)
        let m1 = makeLog(daysAgo: 10, cost: 50, category: .maintenance)
        let m2 = makeLog(daysAgo: 20, cost: 50, category: .maintenance)
        let events: [ExpenseEvent] = [.standalone(r), .standalone(m1), .standalone(m2)]
        XCTAssertNil(CostsInsightsCore.detectRepairCluster(events: events))
    }

    // MARK: - Anomaly Detection

    @MainActor
    func test_detectAnomalies_fewEvents_returnsEmpty() {
        let l1 = makeLog(daysAgo: 1, cost: 100, category: .maintenance)
        let l2 = makeLog(daysAgo: 2, cost: 5000, category: .repair)
        let events: [ExpenseEvent] = [.standalone(l1), .standalone(l2)]
        XCTAssertTrue(CostsInsightsCore.detectAnomalies(events: events).isEmpty)
    }

    @MainActor
    func test_detectAnomalies_outlierAboveTwoXAverage_returnsID() {
        let cheap1 = makeLog(daysAgo: 1, cost: 50, category: .maintenance)
        let cheap2 = makeLog(daysAgo: 2, cost: 50, category: .maintenance)
        let cheap3 = makeLog(daysAgo: 3, cost: 50, category: .maintenance)
        let huge = makeLog(daysAgo: 4, cost: 2000, category: .repair)
        let events: [ExpenseEvent] = [
            .standalone(cheap1), .standalone(cheap2),
            .standalone(cheap3), .standalone(huge)
        ]

        let anomalies = CostsInsightsCore.detectAnomalies(events: events)
        XCTAssertTrue(anomalies.contains(huge.id))
        XCTAssertFalse(anomalies.contains(cheap1.id))
    }

    @MainActor
    func test_detectAnomalies_allSimilarAmounts_returnsEmpty() {
        let a = makeLog(daysAgo: 1, cost: 100, category: .maintenance)
        let b = makeLog(daysAgo: 2, cost: 110, category: .maintenance)
        let c = makeLog(daysAgo: 3, cost: 95, category: .maintenance)
        let events: [ExpenseEvent] = [.standalone(a), .standalone(b), .standalone(c)]
        XCTAssertTrue(CostsInsightsCore.detectAnomalies(events: events).isEmpty)
    }

    // MARK: - Top Expenses

    @MainActor
    func test_topExpenses_returnsDescendingOrder() {
        let a = makeLog(daysAgo: 1, cost: 50, category: .maintenance)
        let b = makeLog(daysAgo: 2, cost: 500, category: .repair)
        let c = makeLog(daysAgo: 3, cost: 200, category: .upgrade)
        let d = makeLog(daysAgo: 4, cost: 75, category: .maintenance)
        let events: [ExpenseEvent] = [.standalone(a), .standalone(b), .standalone(c), .standalone(d)]

        let top = CostsInsightsCore.topExpenses(events: events)
        XCTAssertEqual(top.count, 3)
        XCTAssertEqual(top[0].amount, 500)
        XCTAssertEqual(top[1].amount, 200)
        XCTAssertEqual(top[2].amount, 75)
    }

    @MainActor
    func test_topExpenses_fewerThanLimit_returnsAll() {
        let a = makeLog(daysAgo: 1, cost: 50, category: .maintenance)
        let b = makeLog(daysAgo: 2, cost: 100, category: .repair)
        let events: [ExpenseEvent] = [.standalone(a), .standalone(b)]
        let top = CostsInsightsCore.topExpenses(events: events)
        XCTAssertEqual(top.count, 2)
    }

    // MARK: - Year-End Projection

    func test_projectYearEnd_zeroSpend_returnsNil() {
        let now = makeDate(year: 2025, month: 6, day: 15)
        XCTAssertNil(CostsInsightsCore.projectYearEnd(totalSpent: 0, now: now))
    }

    func test_projectYearEnd_earlyJanuary_returnsNil() {
        let now = makeDate(year: 2025, month: 1, day: 2)
        XCTAssertNil(CostsInsightsCore.projectYearEnd(totalSpent: 100, now: now))
    }

    func test_projectYearEnd_midYear_doublesYTD() {
        // At July 2 (roughly the middle of the year), $600 YTD projects to ~$1200.
        let now = makeDate(year: 2025, month: 7, day: 2)
        let projection = CostsInsightsCore.projectYearEnd(totalSpent: 600, now: now)
        XCTAssertNotNil(projection)
        if let projection {
            let value = NSDecimalNumber(decimal: projection).doubleValue
            XCTAssertEqual(value, 1200, accuracy: 60) // ±5% tolerance
        }
    }

    func test_projectYearEnd_endOfYear_approximatesYTD() {
        let now = makeDate(year: 2025, month: 12, day: 30)
        let projection = CostsInsightsCore.projectYearEnd(totalSpent: 1000, now: now)
        XCTAssertNotNil(projection)
        if let projection {
            let value = NSDecimalNumber(decimal: projection).doubleValue
            XCTAssertEqual(value, 1000, accuracy: 20) // very close to YTD
        }
    }

    // MARK: - TrendDirection

    func test_trendDirection_upIsUnfavorable() {
        XCTAssertTrue(TrendDirection.up.isUnfavorable)
        XCTAssertFalse(TrendDirection.down.isUnfavorable)
        XCTAssertFalse(TrendDirection.flat.isUnfavorable)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        return Calendar.current.date(from: c)!
    }
}
