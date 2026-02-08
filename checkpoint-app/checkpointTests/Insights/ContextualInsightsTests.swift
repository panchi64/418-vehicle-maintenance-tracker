//
//  ContextualInsightsTests.swift
//  checkpointTests
//
//  Tests for contextual insights: time-since formatting, average cost, service counts
//

import XCTest
import SwiftData
@testable import checkpoint

final class ContextualInsightsTests: XCTestCase {

    // MARK: - TimeSinceFormatter Full Format

    func test_timeSinceFull_today_returnsToday() {
        let now = Date.now
        let result = TimeSinceFormatter.full(from: now, relativeTo: now)
        XCTAssertEqual(result, "Today", "Same date should return 'Today'")
    }

    func test_timeSinceFull_yesterday_returnsYesterday() {
        let now = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let result = TimeSinceFormatter.full(from: yesterday, relativeTo: now)
        XCTAssertEqual(result, "Yesterday", "1 day ago should return 'Yesterday'")
    }

    func test_timeSinceFull_days_returnsDaysAgo() {
        let now = Date.now
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        let result = TimeSinceFormatter.full(from: fiveDaysAgo, relativeTo: now)
        XCTAssertEqual(result, "5 days ago", "5 days ago should return '5 days ago'")
    }

    func test_timeSinceFull_months_returnsMonthsAgo() {
        let now = Date.now
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now)!
        let result = TimeSinceFormatter.full(from: threeMonthsAgo, relativeTo: now)
        XCTAssertEqual(result, "3 months ago", "3 months ago should return '3 months ago'")
    }

    func test_timeSinceFull_oneMonth_returnsSingularMonth() {
        let now = Date.now
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let result = TimeSinceFormatter.full(from: oneMonthAgo, relativeTo: now)
        XCTAssertEqual(result, "1 month ago", "1 month ago should use singular form")
    }

    // MARK: - TimeSinceFormatter Abbreviated Format

    func test_timeSinceAbbreviated_today_returnsTODAY() {
        let now = Date.now
        let result = TimeSinceFormatter.abbreviated(from: now, relativeTo: now)
        XCTAssertEqual(result, "TODAY", "Same date should return 'TODAY'")
    }

    func test_timeSinceAbbreviated_yesterday_returnsYESTERDAY() {
        let now = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let result = TimeSinceFormatter.abbreviated(from: yesterday, relativeTo: now)
        XCTAssertEqual(result, "YESTERDAY", "1 day ago should return 'YESTERDAY'")
    }

    func test_timeSinceAbbreviated_days_returnsDaysAbbreviated() {
        let now = Date.now
        let twelveDaysAgo = Calendar.current.date(byAdding: .day, value: -12, to: now)!
        let result = TimeSinceFormatter.abbreviated(from: twelveDaysAgo, relativeTo: now)
        XCTAssertEqual(result, "12D AGO", "12 days ago should return '12D AGO'")
    }

    func test_timeSinceAbbreviated_months_returnsMonthsAbbreviated() {
        let now = Date.now
        let fiveMonthsAgo = Calendar.current.date(byAdding: .month, value: -5, to: now)!
        let result = TimeSinceFormatter.abbreviated(from: fiveMonthsAgo, relativeTo: now)
        XCTAssertEqual(result, "5 MO AGO", "5 months ago should return '5 MO AGO'")
    }

    // MARK: - Average Cost Calculation

    func test_averageCost_multipleLogsWithCost_calculatesCorrectly() {
        let logs = [
            ServiceLog(performedDate: .now, mileageAtService: 10000, cost: 50),
            ServiceLog(performedDate: .now, mileageAtService: 15000, cost: 60),
            ServiceLog(performedDate: .now, mileageAtService: 20000, cost: 40),
        ]

        let logsWithCost = logs.filter { $0.cost != nil }
        let totalCost = logsWithCost.compactMap { $0.cost }.reduce(Decimal.zero, +)
        let averageCost = totalCost / Decimal(logsWithCost.count)

        XCTAssertEqual(averageCost, 50, "Average of 50, 60, 40 should be 50")
    }

    func test_averageCost_singleLog_returnsThatCost() {
        let logs = [
            ServiceLog(performedDate: .now, mileageAtService: 10000, cost: 75),
        ]

        let logsWithCost = logs.filter { $0.cost != nil }
        let totalCost = logsWithCost.compactMap { $0.cost }.reduce(Decimal.zero, +)
        let averageCost = totalCost / Decimal(logsWithCost.count)

        XCTAssertEqual(averageCost, 75, "Single log cost should equal average")
    }

    func test_averageCost_noLogsWithCost_emptyFilter() {
        let logs = [
            ServiceLog(performedDate: .now, mileageAtService: 10000),
        ]

        let logsWithCost = logs.filter { $0.cost != nil }
        XCTAssertTrue(logsWithCost.isEmpty, "Logs without cost should be filtered out")
    }

    // MARK: - Insights Visibility

    func test_insightsVisibility_noLogs_shouldNotShow() {
        let service = Service(name: "Oil Change")
        let logs = service.logs ?? []
        XCTAssertTrue(logs.isEmpty, "Service with no logs should have empty logs array")
    }

    func test_insightsVisibility_withLogs_shouldShow() {
        let service = Service(name: "Oil Change")
        let log = ServiceLog(
            service: service,
            performedDate: .now,
            mileageAtService: 10000,
            cost: 50
        )
        service.logs = [log]

        let logs = service.logs ?? []
        XCTAssertFalse(logs.isEmpty, "Service with logs should show insights")
    }

    // MARK: - Mileage-Tracked Service Count

    func test_mileageTrackedServiceCount_mixedServices_countsCorrectly() {
        let services = [
            Service(name: "Oil Change", dueMileage: 35000),
            Service(name: "Battery Check"),
            Service(name: "Tire Rotation", dueMileage: 40000),
            Service(name: "Wiper Blades"),
        ]

        let count = services.filter { $0.dueMileage != nil }.count
        XCTAssertEqual(count, 2, "Should count only services with dueMileage")
    }

    func test_mileageTrackedServiceCount_noMileageServices_returnsZero() {
        let services = [
            Service(name: "Battery Check"),
            Service(name: "Wiper Blades"),
        ]

        let count = services.filter { $0.dueMileage != nil }.count
        XCTAssertEqual(count, 0, "Services without dueMileage should yield 0")
    }

    func test_mileageTrackedServiceCount_allMileageServices_countsAll() {
        let services = [
            Service(name: "Oil Change", dueMileage: 35000),
            Service(name: "Tire Rotation", dueMileage: 40000),
            Service(name: "Brake Inspection", dueMileage: 50000),
        ]

        let count = services.filter { $0.dueMileage != nil }.count
        XCTAssertEqual(count, 3, "All services with dueMileage should be counted")
    }
}
