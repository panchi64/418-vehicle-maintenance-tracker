//
//  CostsMetricsTests.swift
//  checkpointTests
//
//  Covers the Costs tab's one-pass derivation: visit dedup, period scoping,
//  the hero's monthly average, the trend's month span, the one rule for
//  uncategorized spend, the year comparison, and the month groups.
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
        cost: Decimal?,
        category: CostCategory? = .maintenance,
        visit: ServiceVisit? = nil
    ) -> ServiceLog {
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -daysAgo, to: now)!,
            mileageAtService: 30000 - daysAgo,
            cost: cost,
            costCategory: category
        )
        log.visit = visit
        modelContext.insert(log)
        return log
    }

    @MainActor
    private func visit(daysAgo: Int, total: Decimal?, category: CostCategory? = .repair) -> ServiceVisit {
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -daysAgo, to: now)!,
            mileageAtVisit: 30000 - daysAgo,
            totalCost: total,
            costCategory: category
        )
        modelContext.insert(visit)
        return visit
    }

    /// Logs are handed to `CostsMetrics` newest-first, matching the query.
    @MainActor
    private func metrics(_ logs: [ServiceLog], period: CostsTab.PeriodFilter = .allTime) -> CostsMetrics {
        CostsMetrics(
            logs: logs.sorted { $0.performedDate > $1.performedDate },
            period: period,
            calendar: calendar,
            now: now
        )
    }

    private func month(_ year: Int, _ month: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    // MARK: - Retroactive Costs

    /// A cluster marked done without a cost, then priced later by editing one of
    /// its services, must reach the Costs tab.
    @MainActor
    func test_costAddedLaterToVisitService_countsInTotals() {
        let v = visit(daysAgo: 10, total: nil, category: nil)
        let oil = log(daysAgo: 10, cost: nil, category: nil, visit: v)
        let filter = log(daysAgo: 10, cost: nil, category: nil, visit: v)
        XCTAssertEqual(metrics([oil, filter]).totalSpent, 0)

        oil.applyEditedCost(120, category: .maintenance)

        let result = metrics([oil, filter])
        XCTAssertEqual(result.totalSpent, 120)
        XCTAssertEqual(result.events.count, 1)
    }

    @MainActor
    func test_costAddedLaterToStandaloneService_countsInTotals() {
        let oil = log(daysAgo: 10, cost: nil, category: nil)
        oil.applyEditedCost(60, category: .maintenance)
        XCTAssertEqual(metrics([oil]).totalSpent, 60)
    }

    // MARK: - Totals and dedup

    @MainActor
    func test_totalSpent_sumsCostedEventsOnly() {
        let result = metrics([
            log(daysAgo: 5, cost: 50),
            log(daysAgo: 10, cost: Decimal(string: "75.50")!),
            log(daysAgo: 15, cost: nil),
            log(daysAgo: 20, cost: 0)
        ])

        XCTAssertEqual(result.totalSpent, Decimal(string: "125.50")!)
        XCTAssertEqual(result.events.count, 2)
    }

    @MainActor
    func test_visit_countsOnceRegardlessOfChildLogCount() {
        let shopVisit = visit(daysAgo: 7, total: 400)
        let result = metrics([
            log(daysAgo: 7, cost: nil, visit: shopVisit),
            log(daysAgo: 7, cost: nil, visit: shopVisit),
            log(daysAgo: 7, cost: nil, visit: shopVisit),
            log(daysAgo: 30, cost: 100)
        ])

        XCTAssertEqual(result.events.count, 2)
        XCTAssertEqual(result.totalSpent, 500)
    }

    @MainActor
    func test_noCostedEvents_isEmptyStateNotZeroes() {
        let shopVisit = visit(daysAgo: 7, total: nil)
        let result = metrics([log(daysAgo: 7, cost: nil, visit: shopVisit)])

        XCTAssertFalse(result.hasAnyExpense)
        XCTAssertTrue(result.hasAnyLog)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Period

    @MainActor
    func test_periodFilter_rawValuesStayStableForAnalytics() {
        XCTAssertEqual(CostsTab.PeriodFilter.allCases.map(\.rawValue), ["Month", "YTD", "Year", "All"])
    }

    @MainActor
    func test_periodFilter_scopesEvents() {
        let logs = [
            log(daysAgo: 5, cost: 100),     // Jun 10
            log(daysAgo: 40, cost: 200),    // May
            log(daysAgo: 200, cost: 400),   // Nov 2024
            log(daysAgo: 500, cost: 800)    // 2024
        ]

        XCTAssertEqual(metrics(logs, period: .last30Days).totalSpent, 100)
        XCTAssertEqual(metrics(logs, period: .yearToDate).totalSpent, 300)
        XCTAssertEqual(metrics(logs, period: .last12Months).totalSpent, 700)
        XCTAssertEqual(metrics(logs, period: .allTime).totalSpent, 1500)
    }

    @MainActor
    func test_emptyPeriod_keepsVehicleOutOfEmptyState() {
        let result = metrics([log(daysAgo: 200, cost: 100)], period: .last30Days)

        XCTAssertTrue(result.hasAnyExpense)
        XCTAssertTrue(result.monthGroups.isEmpty)
        XCTAssertEqual(result.totalSpent, 0)
    }

    // MARK: - Monthly average

    /// Averaged from the first expense, not Jan 1: March→June is four months.
    @MainActor
    func test_monthlyAverage_spansFromFirstExpenseInPeriod() {
        let result = metrics([
            log(daysAgo: 5, cost: 100),   // Jun 10
            log(daysAgo: 95, cost: 200)   // Mar 12
        ], period: .yearToDate)

        XCTAssertEqual(result.monthlyAverage, 75)
        XCTAssertFalse(result.averageIsTwelveMonth)
    }

    /// Thirty days is too short to average: 30D reports the 12-month average.
    @MainActor
    func test_monthlyAverage_thirtyDaysUsesTwelveMonthAverage() {
        let result = metrics([
            log(daysAgo: 5, cost: 120),
            log(daysAgo: 200, cost: 240),
            log(daysAgo: 400, cost: 999)   // older than 12 months
        ], period: .last30Days)

        XCTAssertEqual(result.monthlyAverage, 30)
        XCTAssertTrue(result.averageIsTwelveMonth)
    }

    @MainActor
    func test_monthlyAverage_nilWithoutEvents() {
        XCTAssertNil(metrics([log(daysAgo: 200, cost: 100)], period: .yearToDate).monthlyAverage)
    }

    // MARK: - Trend

    @MainActor
    func test_trend_isOneBarPerMonthOldestFirstWithGapsKept() {
        let result = metrics([
            log(daysAgo: 5, cost: 100),    // Jun
            log(daysAgo: 70, cost: 200),   // Apr
            log(daysAgo: 130, cost: 300)   // Feb
        ])

        XCTAssertEqual(result.trend.map(\.month), [
            month(2025, 2), month(2025, 3), month(2025, 4), month(2025, 5), month(2025, 6)
        ])
        XCTAssertEqual(result.trend.map(\.amount), [300, 0, 200, 0, 100])
        XCTAssertTrue(result.trendIsReady)
    }

    @MainActor
    func test_trend_needsThreeMonthsWithSpend() {
        let result = metrics([log(daysAgo: 5, cost: 100), log(daysAgo: 70, cost: 200)])
        XCTAssertFalse(result.trendIsReady)
    }

    @MainActor
    func test_trend_thirtyDaysIsTwoBarsReadyWithTwoExpenses() {
        let one = metrics([log(daysAgo: 3, cost: 100)], period: .last30Days)
        XCTAssertEqual(one.trend.count, 2)
        XCTAssertFalse(one.trendIsReady)

        let two = metrics([log(daysAgo: 3, cost: 100), log(daysAgo: 20, cost: 50)], period: .last30Days)
        XCTAssertTrue(two.trendIsReady)
    }

    @MainActor
    func test_trend_isCappedAtTwentyFourBars() {
        let result = metrics([log(daysAgo: 5, cost: 100), log(daysAgo: 1000, cost: 100)])
        XCTAssertEqual(result.trend.count, 24)
        XCTAssertEqual(result.trend.last?.month, month(2025, 6))
    }

    // MARK: - Category buckets

    /// One rule: uncategorized spend is its own bucket, so the buckets always
    /// sum to the hero's total.
    @MainActor
    func test_uncategorizedSpend_isItsOwnBucket() {
        let result = metrics([
            log(daysAgo: 5, cost: 100, category: .maintenance),
            log(daysAgo: 6, cost: 50, category: .repair),
            log(daysAgo: 7, cost: 50, category: nil)
        ])

        XCTAssertEqual(Set(result.bucketShares.map(\.bucket)), [.category(.maintenance), .category(.repair), .uncategorized])
        XCTAssertEqual(result.bucketShares.first?.bucket, .category(.maintenance))
        XCTAssertEqual(result.bucketShares.map(\.amount).reduce(0, +), result.totalSpent)
        XCTAssertEqual(result.bucketShares.first { $0.bucket == .uncategorized }?.fraction ?? 0, 0.25, accuracy: 0.0001)
        XCTAssertTrue(result.categoryIsReady)
    }

    @MainActor
    func test_categoryChart_needsTwoBuckets() {
        let result = metrics([log(daysAgo: 5, cost: 100), log(daysAgo: 6, cost: 50)])
        XCTAssertFalse(result.categoryIsReady)
    }

    // MARK: - Year comparison

    @MainActor
    func test_comparison_isThisYearAgainstSameSpanLastYear() {
        let result = metrics([
            log(daysAgo: 10, cost: 300),    // 2025
            log(daysAgo: 380, cost: 200),   // May 2024 — inside last year's span
            log(daysAgo: 250, cost: 999)    // Oct 2024 — after this date last year
        ], period: .last30Days)  // independent of the period

        XCTAssertEqual(result.comparison, CostYearComparison(
            year: 2025,
            thisYearTotal: 300,
            lastYearTotal: 200,
            percentChange: 50
        ))
        XCTAssertEqual(result.currentYear, 2025)
    }

    @MainActor
    func test_comparison_nilWithoutLastYearSpendByThisDate() {
        let result = metrics([log(daysAgo: 10, cost: 300), log(daysAgo: 250, cost: 999)])
        XCTAssertNil(result.comparison)
    }

    // MARK: - Month groups

    @MainActor
    func test_monthGroups_newestFirstWithTotals() {
        let result = metrics([
            log(daysAgo: 5, cost: 100),    // Jun
            log(daysAgo: 8, cost: 25),     // Jun
            log(daysAgo: 70, cost: 200)    // Apr
        ])

        XCTAssertEqual(result.monthGroups.map(\.month), [month(2025, 6), month(2025, 4)])
        XCTAssertEqual(result.monthGroups.map(\.total), [125, 200])
        XCTAssertEqual(result.monthGroups.first?.events.count, 2)
    }

    // MARK: - Signals

    @MainActor
    func test_anomalies_comeFromThePeriodEvents() {
        let huge = log(daysAgo: 400, cost: 5000)
        let recent = [log(daysAgo: 1, cost: 50), log(daysAgo: 2, cost: 50), log(daysAgo: 3, cost: 50)]

        let yearToDate = metrics(recent + [huge], period: .yearToDate)
        XCTAssertTrue(yearToDate.anomalyEventIDs.isEmpty)

        let allTime = metrics(recent + [huge])
        XCTAssertTrue(allTime.anomalyEventIDs.contains(huge.id))
    }

    // MARK: - Wording

    @MainActor
    func test_summaries_areAlwaysWrittenWhenChartsAreReady() {
        let result = metrics([
            log(daysAgo: 5, cost: 100, category: .repair),
            log(daysAgo: 70, cost: 200),
            log(daysAgo: 130, cost: 300)
        ])

        XCTAssertFalse(result.chartSummary(.trend).isEmpty)
        XCTAssertFalse(result.chartSummary(.category).isEmpty)
        XCTAssertNotNil(result.averageLine)
    }
}
