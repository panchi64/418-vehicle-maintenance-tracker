//
//  CostsMetricsTests.swift
//  checkpointTests
//
//  Covers the Costs tab's one-pass derivation. These assertions are the contract
//  that the derivation moved out of `CostsTab`'s computed properties without
//  changing any number on the screen: visit dedup, filter scoping, the category
//  split, and the time series.
//

import XCTest
import SwiftData
@testable import checkpoint

final class CostsMetricsTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    /// Fixed so month/year arithmetic can't straddle a boundary mid-run.
    let now = Date(timeIntervalSince1970: 1_750_000_000)  // 2025-06-15
    let calendar = Calendar(identifier: .gregorian)

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self,
            ServiceAttachment.self, VisitLineItem.self,
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
    private func log(
        daysAgo: Int,
        mileage: Int,
        cost: Decimal?,
        category: CostCategory? = .maintenance,
        visit: ServiceVisit? = nil
    ) -> ServiceLog {
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -daysAgo, to: now)!,
            mileageAtService: mileage,
            cost: cost,
            costCategory: category
        )
        log.visit = visit
        modelContext.insert(log)
        return log
    }

    @MainActor
    private func visit(
        daysAgo: Int,
        mileage: Int,
        total: Decimal?,
        category: CostCategory? = .repair
    ) -> ServiceVisit {
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -daysAgo, to: now)!,
            mileageAtVisit: mileage,
            totalCost: total,
            costCategory: category
        )
        modelContext.insert(visit)
        return visit
    }

    /// Logs are handed to `CostsMetrics` newest-first, matching the query.
    @MainActor
    private func metrics(
        _ logs: [ServiceLog],
        period: CostsTab.PeriodFilter = .all,
        category: CostsTab.CategoryFilter = .all
    ) -> CostsMetrics {
        CostsMetrics(
            logs: logs.sorted { $0.performedDate > $1.performedDate },
            hasVehicle: true,
            period: period,
            category: category,
            calendar: calendar,
            now: now
        )
    }

    // MARK: - Totals

    @MainActor
    func testTotalSpent_SumsCostedEventsOnly() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(50)),
            log(daysAgo: 10, mileage: 29500, cost: Decimal(75.50)),
            log(daysAgo: 15, mileage: 29000, cost: nil),
            log(daysAgo: 20, mileage: 28500, cost: Decimal(0))
        ]

        let result = metrics(logs)

        XCTAssertEqual(result.totalSpent, Decimal(125.50))
        XCTAssertEqual(result.serviceCount, 2)
        XCTAssertEqual(result.averageCost, Decimal(125.50) / 2)
    }

    @MainActor
    func testAverageCost_IsNilWithoutCostedEvents() {
        let result = metrics([log(daysAgo: 1, mileage: 30000, cost: nil)])

        XCTAssertNil(result.averageCost)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(result.formattedAverageCost, "-")
    }

    // MARK: - Visit Dedup

    @MainActor
    func testVisit_CountsOnceRegardlessOfChildLogCount() {
        let shopVisit = visit(daysAgo: 7, mileage: 29800, total: Decimal(400))
        let logs = [
            log(daysAgo: 7, mileage: 29800, cost: nil, visit: shopVisit),
            log(daysAgo: 7, mileage: 29800, cost: nil, visit: shopVisit),
            log(daysAgo: 7, mileage: 29800, cost: nil, visit: shopVisit),
            log(daysAgo: 30, mileage: 29000, cost: Decimal(100))
        ]

        let result = metrics(logs)

        // One visit event + one standalone, not four events.
        XCTAssertEqual(result.serviceCount, 2)
        XCTAssertEqual(result.totalSpent, Decimal(500))
        XCTAssertEqual(result.events.filter { if case .visit = $0 { return true } else { return false } }.count, 1)
    }

    @MainActor
    func testVisitWithoutTotal_StaysOutOfMoneyMetrics() {
        let shopVisit = visit(daysAgo: 7, mileage: 29800, total: nil)
        let logs = [log(daysAgo: 7, mileage: 29800, cost: nil, visit: shopVisit)]

        let result = metrics(logs)

        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(result.totalSpent, 0)
        // Still present in the unfiltered event list.
        XCTAssertEqual(result.allEvents.count, 1)
    }

    // MARK: - Filters

    @MainActor
    func testPeriodFilter_ExcludesOlderEvents() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(100)),
            log(daysAgo: 200, mileage: 25000, cost: Decimal(900))
        ]

        XCTAssertEqual(metrics(logs, period: .month).totalSpent, Decimal(100))
        XCTAssertEqual(metrics(logs, period: .year).totalSpent, Decimal(1000))
        XCTAssertEqual(metrics(logs, period: .all).totalSpent, Decimal(1000))
    }

    @MainActor
    func testCategoryFilter_NarrowsToOneCategory() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(100), category: .maintenance),
            log(daysAgo: 6, mileage: 29900, cost: Decimal(300), category: .repair),
            log(daysAgo: 7, mileage: 29800, cost: Decimal(50), category: .upgrade)
        ]

        let repairs = metrics(logs, category: .repair)

        XCTAssertEqual(repairs.serviceCount, 1)
        XCTAssertEqual(repairs.totalSpent, Decimal(300))
        // The unfiltered list stays whole, so the category picker keeps its counts.
        XCTAssertEqual(repairs.allEvents.count, 3)
    }

    // MARK: - Category Split

    @MainActor
    func testCategoryBreakdown_IsSortedByAmountWithPercentages() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(250), category: .maintenance),
            log(daysAgo: 6, mileage: 29900, cost: Decimal(750), category: .repair)
        ]

        let result = metrics(logs)

        XCTAssertEqual(result.categoryBreakdown.count, 2)
        XCTAssertEqual(result.categoryBreakdown.first?.category, .repair)
        XCTAssertEqual(result.categoryBreakdown.first?.percentage ?? 0, 75, accuracy: 0.001)
        XCTAssertEqual(result.reactiveShare, 75, accuracy: 0.001)
        XCTAssertEqual(result.preventiveShare, 25, accuracy: 0.001)
        XCTAssertEqual(result.discretionaryShare, 0, accuracy: 0.001)
    }

    @MainActor
    func testUncategorisedSpend_IsExcludedFromShares() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(500), category: .maintenance),
            log(daysAgo: 6, mileage: 29900, cost: Decimal(500), category: nil)
        ]

        let result = metrics(logs)

        // The uncategorised half counts toward the total but claims no category,
        // so preventive is 50% of spend rather than 100%.
        XCTAssertEqual(result.totalSpent, Decimal(1000))
        XCTAssertEqual(result.preventiveShare, 50, accuracy: 0.001)
        XCTAssertEqual(result.categoryBreakdown.count, 1)
    }

    @MainActor
    func testShares_AreZeroWithoutSpend() {
        let result = metrics([log(daysAgo: 1, mileage: 30000, cost: nil)])

        XCTAssertEqual(result.preventiveShare, 0)
        XCTAssertEqual(result.reactiveShare, 0)
        XCTAssertTrue(result.categoryBreakdown.isEmpty)
    }

    // MARK: - Cost Per Mile

    @MainActor
    func testCostPerMile_UsesDistanceBetweenOldestAndNewestEvent() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(200)),
            log(daysAgo: 100, mileage: 28000, cost: Decimal(300))
        ]

        let result = metrics(logs)

        // $500 across 2,000 miles.
        XCTAssertEqual(result.costPerMile ?? 0, 0.25, accuracy: 0.0001)
    }

    @MainActor
    func testCostPerMile_IsNilWithoutForwardMotion() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(200)),
            log(daysAgo: 100, mileage: 30000, cost: Decimal(300))
        ]

        XCTAssertNil(metrics(logs).costPerMile)
        XCTAssertEqual(metrics(logs).formattedCostPerMile, "-")
    }

    @MainActor
    func testCostPerMile_IsNilWithASingleEvent() {
        XCTAssertNil(metrics([log(daysAgo: 5, mileage: 30000, cost: Decimal(200))]).costPerMile)
    }

    // MARK: - Time Series

    @MainActor
    func testMonthlyBreakdown_GroupsByMonthNewestFirst() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(100)),
            log(daysAgo: 8, mileage: 29900, cost: Decimal(50)),
            log(daysAgo: 45, mileage: 29000, cost: Decimal(200))
        ]

        let result = metrics(logs)

        XCTAssertEqual(result.monthlyBreakdown.count, 2)
        XCTAssertEqual(result.monthlyBreakdown.first?.amount, Decimal(150))
        // Chronological is the same data reversed, for a chart's x-axis.
        XCTAssertEqual(
            result.monthlyBreakdownChronological.map(\.amount),
            result.monthlyBreakdown.map(\.amount).reversed()
        )
        XCTAssertEqual(result.monthlyBreakdownChronological.first?.amount, Decimal(200))
    }

    @MainActor
    func testCumulativeCost_AccumulatesAndMergesSameDay() {
        let logs = [
            log(daysAgo: 30, mileage: 29000, cost: Decimal(100)),
            log(daysAgo: 30, mileage: 29000, cost: Decimal(50)),
            log(daysAgo: 10, mileage: 29800, cost: Decimal(25))
        ]

        let series = metrics(logs).cumulativeCostOverTime

        XCTAssertEqual(series.count, 2)
        XCTAssertEqual(series.first?.cumulativeAmount, Decimal(150))
        XCTAssertEqual(series.last?.cumulativeAmount, Decimal(175))
        // Strictly increasing dates.
        XCTAssertLessThan(series[0].date, series[1].date)
    }

    @MainActor
    func testMonthlyBreakdownByCategory_AssignsUncategorisedToMaintenance() {
        let logs = [log(daysAgo: 5, mileage: 30000, cost: Decimal(80), category: nil)]

        let byCategory = metrics(logs).monthlyBreakdownByCategory

        // A stacked bar has to place every dollar, unlike the share split.
        XCTAssertEqual(byCategory.count, 1)
        XCTAssertEqual(byCategory.first?.category, .maintenance)
        XCTAssertEqual(byCategory.first?.amount, Decimal(80))
    }

    // MARK: - Prior Period

    @MainActor
    func testPeriodDelta_ComparesAgainstThePriorWindow() {
        let logs = [
            log(daysAgo: 10, mileage: 30000, cost: Decimal(300)),   // this month
            log(daysAgo: 45, mileage: 29000, cost: Decimal(100))    // prior month
        ]

        let result = metrics(logs, period: .month)

        XCTAssertTrue(result.hasPriorPeriod)
        XCTAssertEqual(result.priorPeriodTotal, Decimal(100))
        XCTAssertEqual(result.periodDeltaAmount, Decimal(200))
        XCTAssertEqual(result.periodDeltaDirection, .up)
    }

    @MainActor
    func testPeriodDelta_IsNilForAllTime() {
        let result = metrics([log(daysAgo: 10, mileage: 30000, cost: Decimal(300))], period: .all)

        XCTAssertFalse(result.hasPriorPeriod)
        XCTAssertNil(result.periodDeltaAmount)
        XCTAssertEqual(result.periodDeltaDirection, .flat)
    }

    // MARK: - Yearly Roundup

    @MainActor
    func testPreviousYearLogs_AreScopedToTheYearBeforeTheRoundup() {
        let logs = [
            log(daysAgo: 10, mileage: 30000, cost: Decimal(300)),
            log(daysAgo: 400, mileage: 25000, cost: Decimal(100))
        ]

        let result = metrics(logs, period: .all)

        XCTAssertEqual(result.currentYear, calendar.component(.year, from: now))
        XCTAssertEqual(result.previousYearLogs.count, 1)
        XCTAssertTrue(result.shouldShowYearlyRoundup)
    }

    @MainActor
    func testYearlyRoundup_HiddenForShortPeriods() {
        let result = metrics([log(daysAgo: 5, mileage: 30000, cost: Decimal(300))], period: .month)

        XCTAssertFalse(result.shouldShowYearlyRoundup)
    }

    // MARK: - Signals

    @MainActor
    func testAnomaliesAndTopExpenses_ComeFromTheFilteredEvents() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(1000)),
            log(daysAgo: 6, mileage: 29900, cost: Decimal(50)),
            log(daysAgo: 7, mileage: 29800, cost: Decimal(50))
        ]

        let result = metrics(logs)

        XCTAssertEqual(result.topExpenses.count, 3)
        XCTAssertEqual(result.topExpenses.first?.amount, Decimal(1000))
        XCTAssertEqual(result.anomalyEventIDs.count, 1)
        XCTAssertTrue(result.anomalyEventIDs.contains(logs[0].id))
    }

    @MainActor
    func testRepairCluster_IgnoresTheCategoryFilter() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(400), category: .repair),
            log(daysAgo: 20, mileage: 29800, cost: Decimal(600), category: .repair),
            log(daysAgo: 25, mileage: 29700, cost: Decimal(80), category: .maintenance)
        ]

        // Narrowed to maintenance, the repair warning must still fire.
        let result = metrics(logs, category: .maintenance)

        XCTAssertEqual(result.repairCluster?.count, 2)
        XCTAssertEqual(result.repairCluster?.totalAmount, Decimal(1000))
    }

    // MARK: - No Vehicle

    @MainActor
    func testWithoutVehicle_CostPerMileIsSuppressed() {
        let logs = [
            log(daysAgo: 5, mileage: 30000, cost: Decimal(200)),
            log(daysAgo: 100, mileage: 28000, cost: Decimal(300))
        ]

        let result = CostsMetrics(
            logs: logs,
            hasVehicle: false,
            period: .all,
            category: .all,
            calendar: calendar,
            now: now
        )

        XCTAssertNil(result.costPerMile)
        XCTAssertEqual(result.totalSpent, Decimal(500))
    }
}
