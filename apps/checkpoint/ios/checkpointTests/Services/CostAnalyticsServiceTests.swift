//
//  CostAnalyticsServiceTests.swift
//  checkpointTests
//
//  Covers the spend rules shared by the Costs tab and App Intents: a visit
//  counts once, periods exclude the future, uncategorized spend is its own
//  bucket, and a category narrows the total without narrowing the buckets.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class CostAnalyticsServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    /// Fixed so period arithmetic can't straddle a boundary mid-run.
    let now = Date(timeIntervalSince1970: 1_750_000_000)  // 2025-06-15
    let calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
        vehicle = Vehicle(name: "Test", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30_000)
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func date(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: now)!
    }

    @discardableResult
    private func log(daysAgo: Int, cost: Decimal?, category: CostCategory? = .maintenance, visit: ServiceVisit? = nil) -> ServiceLog {
        let log = ServiceLog(vehicle: vehicle, performedDate: date(daysAgo: daysAgo),
                             mileageAtService: 30_000 - daysAgo, cost: cost, costCategory: category)
        log.visit = visit
        modelContext.insert(log)
        return log
    }

    private func visit(daysAgo: Int, total: Decimal?, category: CostCategory? = .repair) -> ServiceVisit {
        let visit = ServiceVisit(vehicle: vehicle, performedDate: date(daysAgo: daysAgo),
                                 mileageAtVisit: 30_000 - daysAgo, totalCost: total, costCategory: category)
        modelContext.insert(visit)
        return visit
    }

    // MARK: - Events

    func test_expenseEvents_visitCountsOnce() {
        let shopVisit = visit(daysAgo: 5, total: 300)
        let logs = [
            log(daysAgo: 5, cost: nil, visit: shopVisit),
            log(daysAgo: 5, cost: nil, visit: shopVisit),
            log(daysAgo: 5, cost: nil, visit: shopVisit),
            log(daysAgo: 10, cost: 50),
        ]

        let events = CostAnalyticsService.expenseEvents(from: logs)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(CostAnalyticsService.total(of: events), 350)
    }

    func test_expenseEvents_newestFirst() {
        let logs = [log(daysAgo: 30, cost: 10), log(daysAgo: 1, cost: 20), log(daysAgo: 10, cost: 30)]

        let dates = CostAnalyticsService.expenseEvents(from: logs).map(\.date)

        XCTAssertEqual(dates, dates.sorted(by: >))
    }

    func test_costedEvents_dropsZeroAndNilCost() {
        let logs = [log(daysAgo: 1, cost: nil), log(daysAgo: 2, cost: 0), log(daysAgo: 3, cost: 40)]

        XCTAssertEqual(CostAnalyticsService.costedEvents(from: logs).map(\.amount), [40])
    }

    // MARK: - Periods

    func test_eventsInPeriod_excludesFutureAndBeforeStart() {
        let logs = [log(daysAgo: -3, cost: 10), log(daysAgo: 10, cost: 20), log(daysAgo: 45, cost: 30)]
        let events = CostAnalyticsService.costedEvents(from: logs)

        let last30 = CostAnalyticsService.events(events, in: .last30Days, now: now, calendar: calendar)

        XCTAssertEqual(last30.map(\.amount), [20])
    }

    func test_eventsInPeriod_allTimeKeepsPastEvents() {
        let logs = [log(daysAgo: 10, cost: 20), log(daysAgo: 900, cost: 30)]
        let events = CostAnalyticsService.costedEvents(from: logs)

        XCTAssertEqual(CostAnalyticsService.events(events, in: .allTime, now: now, calendar: calendar).count, 2)
    }

    func test_costPeriod_rawValuesAreStableStorage() {
        XCTAssertEqual(CostPeriod.allCases.map(\.rawValue), ["Month", "YTD", "Year", "All"])
    }

    // MARK: - Summary

    func test_summary_totalsByBucket_keepsUncategorizedSeparate() {
        let logs = [
            log(daysAgo: 1, cost: 100, category: .maintenance),
            log(daysAgo: 2, cost: 40, category: nil),
            log(daysAgo: 3, cost: 60, category: .repair),
        ]

        let summary = CostAnalyticsService.summary(logs: logs, period: .allTime, now: now, calendar: calendar)

        XCTAssertEqual(summary.total, 200)
        XCTAssertEqual(summary.expenseCount, 3)
        XCTAssertEqual(summary.totalsByBucket[.category(.maintenance)], 100)
        XCTAssertEqual(summary.totalsByBucket[.category(.repair)], 60)
        XCTAssertEqual(summary.totalsByBucket[.uncategorized], 40)
    }

    func test_summary_category_narrowsTotalOnly() {
        let shopVisit = visit(daysAgo: 4, total: 250, category: .repair)
        let logs = [
            log(daysAgo: 1, cost: 100, category: .maintenance),
            log(daysAgo: 4, cost: nil, visit: shopVisit),
            log(daysAgo: 4, cost: nil, visit: shopVisit),
        ]

        let summary = CostAnalyticsService.summary(logs: logs, period: .last30Days, category: .repair,
                                                   now: now, calendar: calendar)

        XCTAssertEqual(summary.total, 250, "The visit's total, once")
        XCTAssertEqual(summary.expenseCount, 1)
        XCTAssertEqual(summary.totalsByBucket.count, 2, "Buckets describe the whole period")
    }

    func test_summary_noExpenses_isZero() {
        let summary = CostAnalyticsService.summary(logs: [], period: .yearToDate, now: now, calendar: calendar)

        XCTAssertEqual(summary.total, 0)
        XCTAssertEqual(summary.expenseCount, 0)
        XCTAssertTrue(summary.totalsByBucket.isEmpty)
    }
}
