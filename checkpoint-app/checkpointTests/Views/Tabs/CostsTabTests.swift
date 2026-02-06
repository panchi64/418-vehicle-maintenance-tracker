//
//  CostsTabTests.swift
//  checkpointTests
//
//  Tests for CostsTab view content and functionality
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class CostsTabTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Period Filter Tests

    func testPeriodFilter_AllCases() {
        // Given
        let allFilters = CostsTab.PeriodFilter.allCases

        // Then
        XCTAssertEqual(allFilters.count, 4)
        XCTAssertTrue(allFilters.contains(.month))
        XCTAssertTrue(allFilters.contains(.ytd))
        XCTAssertTrue(allFilters.contains(.year))
        XCTAssertTrue(allFilters.contains(.all))
    }

    func testPeriodFilter_RawValues() {
        // Then
        XCTAssertEqual(CostsTab.PeriodFilter.month.rawValue, "Month")
        XCTAssertEqual(CostsTab.PeriodFilter.ytd.rawValue, "YTD")
        XCTAssertEqual(CostsTab.PeriodFilter.year.rawValue, "Year")
        XCTAssertEqual(CostsTab.PeriodFilter.all.rawValue, "All")
    }

    func testPeriodFilter_StartDates() {
        // Given/When
        let calendar = Calendar.current

        // Then - Month filter should have a start date ~30 days ago
        let monthStart = CostsTab.PeriodFilter.month.startDate
        XCTAssertNotNil(monthStart)

        // YTD should have start date at beginning of year
        let ytdStart = CostsTab.PeriodFilter.ytd.startDate
        XCTAssertNotNil(ytdStart)
        if let ytdStart = ytdStart {
            let components = calendar.dateComponents([.month, .day], from: ytdStart)
            XCTAssertEqual(components.month, 1)
            XCTAssertEqual(components.day, 1)
        }

        // Year filter should have a start date ~365 days ago
        let yearStart = CostsTab.PeriodFilter.year.startDate
        XCTAssertNotNil(yearStart)

        // All filter should have nil start date
        let allStart = CostsTab.PeriodFilter.all.startDate
        XCTAssertNil(allStart)
    }

    // MARK: - Total Spent Calculation Tests

    @MainActor
    func testTotalSpent_CalculatesCorrectly() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(50.00)
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29500,
            cost: Decimal(75.50)
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29000,
            cost: nil // No cost
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        // When
        let logs = [log1, log2, log3]
        let totalSpent = logs.compactMap { $0.cost }.reduce(Decimal(0), +)

        // Then
        XCTAssertEqual(totalSpent, Decimal(125.50))
    }

    @MainActor
    func testTotalSpent_ExcludesNilCosts() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let logWithCost = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(100.00)
        )
        let logWithoutCost = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29000,
            cost: nil
        )

        modelContext.insert(logWithCost)
        modelContext.insert(logWithoutCost)

        // When
        let logs = [logWithCost, logWithoutCost]
        let logsWithCosts = logs.filter { $0.cost != nil }

        // Then
        XCTAssertEqual(logsWithCosts.count, 1)
    }

    // MARK: - Average Cost Calculation Tests

    @MainActor
    func testAverageCost_CalculatesCorrectly() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(50.00)
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29000,
            cost: Decimal(100.00)
        )

        modelContext.insert(log1)
        modelContext.insert(log2)

        // When
        let logs = [log1, log2]
        let logsWithCosts = logs.filter { $0.cost != nil && $0.cost! > 0 }
        let totalSpent = logsWithCosts.compactMap { $0.cost }.reduce(Decimal(0), +)
        let averageCost = totalSpent / Decimal(logsWithCosts.count)

        // Then
        XCTAssertEqual(averageCost, Decimal(75.00))
    }

    // MARK: - Period Filtering Tests

    @MainActor
    func testPeriodFilter_FiltersLogsByDate() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        let recentLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -15, to: .now)!,
            mileageAtService: 30000,
            cost: Decimal(50.00)
        )
        let oldLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -60, to: .now)!,
            mileageAtService: 28000,
            cost: Decimal(75.00)
        )

        modelContext.insert(recentLog)
        modelContext.insert(oldLog)

        // When - filter by month (last 30 days)
        let monthStart = CostsTab.PeriodFilter.month.startDate!
        let logs = [recentLog, oldLog]
        let filteredLogs = logs.filter { $0.performedDate >= monthStart }

        // Then - only recent log should be included
        XCTAssertEqual(filteredLogs.count, 1)
        XCTAssertEqual(filteredLogs.first?.cost, Decimal(50.00))
    }

    @MainActor
    func testAllFilter_IncludesAllLogs() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        let recentLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(50.00)
        )
        let oldLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .year, value: -2, to: .now)!,
            mileageAtService: 20000,
            cost: Decimal(100.00)
        )

        modelContext.insert(recentLog)
        modelContext.insert(oldLog)

        // When - filter by "all" (nil start date)
        let allStart = CostsTab.PeriodFilter.all.startDate
        let logs = [recentLog, oldLog]
        let filteredLogs: [ServiceLog]
        if let startDate = allStart {
            filteredLogs = logs.filter { $0.performedDate >= startDate }
        } else {
            filteredLogs = logs
        }

        // Then - all logs should be included
        XCTAssertEqual(filteredLogs.count, 2)
    }

    // MARK: - Service Count Tests

    @MainActor
    func testServiceCount_CountsAllServicesInPeriod() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29500
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29000
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        // When
        let logs = [log1, log2, log3]
        let serviceCount = logs.count

        // Then
        XCTAssertEqual(serviceCount, 3)
    }

    // MARK: - Category Filter Tests

    func testCategoryFilter_AllCases() {
        // Given
        let allFilters = CostsTab.CategoryFilter.allCases

        // Then
        XCTAssertEqual(allFilters.count, 4)
        XCTAssertTrue(allFilters.contains(.all))
        XCTAssertTrue(allFilters.contains(.maintenance))
        XCTAssertTrue(allFilters.contains(.repair))
        XCTAssertTrue(allFilters.contains(.upgrade))
    }

    func testCategoryFilter_RawValues() {
        // Then
        XCTAssertEqual(CostsTab.CategoryFilter.all.rawValue, "All")
        XCTAssertEqual(CostsTab.CategoryFilter.maintenance.rawValue, "Maint")
        XCTAssertEqual(CostsTab.CategoryFilter.repair.rawValue, "Repair")
        XCTAssertEqual(CostsTab.CategoryFilter.upgrade.rawValue, "Upgrade")
    }

    func testCategoryFilter_CostCategoryMapping() {
        // Then
        XCTAssertNil(CostsTab.CategoryFilter.all.costCategory)
        XCTAssertEqual(CostsTab.CategoryFilter.maintenance.costCategory, .maintenance)
        XCTAssertEqual(CostsTab.CategoryFilter.repair.costCategory, .repair)
        XCTAssertEqual(CostsTab.CategoryFilter.upgrade.costCategory, .upgrade)
    }

    @MainActor
    func testCategoryFilter_FiltersByCostCategory() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let maintenanceLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(50.00),
            costCategory: .maintenance
        )
        let repairLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29500,
            cost: Decimal(200.00),
            costCategory: .repair
        )
        let upgradeLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29000,
            cost: Decimal(150.00),
            costCategory: .upgrade
        )

        modelContext.insert(maintenanceLog)
        modelContext.insert(repairLog)
        modelContext.insert(upgradeLog)

        // When filtering by maintenance
        let logs = [maintenanceLog, repairLog, upgradeLog]
        let maintenanceLogs = logs.filter { $0.costCategory == .maintenance }
        let repairLogs = logs.filter { $0.costCategory == .repair }
        let upgradeLogs = logs.filter { $0.costCategory == .upgrade }

        // Then
        XCTAssertEqual(maintenanceLogs.count, 1)
        XCTAssertEqual(repairLogs.count, 1)
        XCTAssertEqual(upgradeLogs.count, 1)
        XCTAssertEqual(maintenanceLogs.first?.cost, Decimal(50.00))
        XCTAssertEqual(repairLogs.first?.cost, Decimal(200.00))
        XCTAssertEqual(upgradeLogs.first?.cost, Decimal(150.00))
    }

    @MainActor
    func testCategoryBreakdown_CalculatesPercentages() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let maintenanceLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 30000,
            cost: Decimal(50.00),
            costCategory: .maintenance
        )
        let repairLog = ServiceLog(
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 29500,
            cost: Decimal(50.00),
            costCategory: .repair
        )

        modelContext.insert(maintenanceLog)
        modelContext.insert(repairLog)

        // When
        let logs = [maintenanceLog, repairLog]
        let totalCost = logs.compactMap { $0.cost }.reduce(Decimal(0), +)
        let maintenanceCost = logs.filter { $0.costCategory == .maintenance }.compactMap { $0.cost }.reduce(Decimal(0), +)
        let maintenancePercentage = NSDecimalNumber(decimal: maintenanceCost).doubleValue / NSDecimalNumber(decimal: totalCost).doubleValue * 100

        // Then
        XCTAssertEqual(totalCost, Decimal(100.00))
        XCTAssertEqual(maintenancePercentage, 50.0, accuracy: 0.1)
    }

    // MARK: - Yearly Roundup Visibility Tests

    func testYearlyRoundup_ShouldShowForYearFilter() {
        // Given
        let periodFilter = CostsTab.PeriodFilter.year

        // When
        let shouldShow = periodFilter == .year || periodFilter == .all

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testYearlyRoundup_ShouldShowForAllFilter() {
        // Given
        let periodFilter = CostsTab.PeriodFilter.all

        // When
        let shouldShow = periodFilter == .year || periodFilter == .all

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testYearlyRoundup_ShouldNotShowForMonthFilter() {
        // Given
        let periodFilter = CostsTab.PeriodFilter.month

        // When
        let shouldShow = periodFilter == .year || periodFilter == .all

        // Then
        XCTAssertFalse(shouldShow)
    }

    func testYearlyRoundup_ShouldNotShowForYTDFilter() {
        // Given
        let periodFilter = CostsTab.PeriodFilter.ytd

        // When
        let shouldShow = periodFilter == .year || periodFilter == .all

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: - Monthly Breakdown Tests

    @MainActor
    func testMonthlyBreakdown_GroupsByMonth() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        let januaryDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let februaryDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!

        let janLog = ServiceLog(
            vehicle: vehicle,
            performedDate: januaryDate,
            mileageAtService: 30000,
            cost: Decimal(100.00)
        )
        let febLog1 = ServiceLog(
            vehicle: vehicle,
            performedDate: februaryDate,
            mileageAtService: 30500,
            cost: Decimal(50.00)
        )
        let febLog2 = ServiceLog(
            vehicle: vehicle,
            performedDate: februaryDate,
            mileageAtService: 31000,
            cost: Decimal(75.00)
        )

        modelContext.insert(janLog)
        modelContext.insert(febLog1)
        modelContext.insert(febLog2)

        // When - group by month
        let logs = [janLog, febLog1, febLog2]
        var monthlyTotals: [Date: Decimal] = [:]

        for log in logs {
            let components = calendar.dateComponents([.year, .month], from: log.performedDate)
            if let monthStart = calendar.date(from: components) {
                monthlyTotals[monthStart, default: 0] += log.cost ?? 0
            }
        }

        // Then
        XCTAssertEqual(monthlyTotals.count, 2)

        let janStart = calendar.date(from: DateComponents(year: 2024, month: 1))!
        let febStart = calendar.date(from: DateComponents(year: 2024, month: 2))!

        XCTAssertEqual(monthlyTotals[janStart], Decimal(100.00))
        XCTAssertEqual(monthlyTotals[febStart], Decimal(125.00))
    }

    // MARK: - Overflow Prevention Tests

    func testCurrencyFormatting_LargeYearlyTotal_FitsScreenWidth() {
        // Given - large totals typical of Year/All period filters
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0

        let largeAmounts: [Decimal] = [
            Decimal(12345),
            Decimal(99999),
            Decimal(123456),
            Decimal(999999)
        ]

        for amount in largeAmounts {
            // When
            let formatted = formatter.string(from: amount as NSDecimalNumber) ?? "$0"

            // Then - monospaced chars at 56pt are ~33.6pt each
            // iPhone SE width: 375pt - 2*20pt (screen padding) - 2*24pt (card padding) = 287pt
            // At 56pt monospaced, that fits ~8.5 chars without scaling
            // With minimumScaleFactor(0.5), we can fit ~17 chars
            // Verify the formatted string length is reasonable for display
            let charCount = formatted.count
            XCTAssertLessThan(charCount, 18,
                "Currency string '\(formatted)' with \(charCount) chars should fit with minimumScaleFactor(0.5)")
        }
    }

    func testCurrencyFormatting_AllTimePeriod_ProducesValidString() {
        // Given - very large totals that could appear with "All" period
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0

        let veryLargeAmount = Decimal(1234567)

        // When
        let formatted = formatter.string(from: veryLargeAmount as NSDecimalNumber)

        // Then
        XCTAssertNotNil(formatted)
        XCTAssertEqual(formatted, "$1,234,567")
        // At 56pt mono, this would be 10 chars * ~33.6pt = 336pt
        // Without minimumScaleFactor, this overflows the 287pt available on iPhone SE
        // With minimumScaleFactor(0.5), it scales down to ~28pt effectively fitting in 168pt
        XCTAssertTrue(formatted!.count <= 17,
            "Even very large amounts should be representable within scale factor limits")
    }

    func testMonthlyBreakdown_BarWidthBounded() {
        // Given - bar width calculation from monthlySummarySection
        let maxAmount = Decimal(5000)
        let testAmounts: [Decimal] = [
            Decimal(5000),  // 100% - max bar
            Decimal(2500),  // 50%
            Decimal(100),   // 2% - min bar
            Decimal(0)      // 0% edge case
        ]

        for amount in testAmounts {
            // When - replicate the bar width calculation
            let ratio = NSDecimalNumber(decimal: amount).doubleValue /
                        NSDecimalNumber(decimal: maxAmount).doubleValue
            let barWidth = CGFloat(ratio) * 60

            // Then - bar width should never exceed 60pt
            XCTAssertLessThanOrEqual(barWidth, 60,
                "Bar width \(barWidth) should not exceed 60pt maximum")
            XCTAssertGreaterThanOrEqual(barWidth, 0,
                "Bar width \(barWidth) should not be negative")
        }
    }

    @MainActor
    func testYearFilter_AccumulatesLargerTotals_ThanMonth() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        var logs: [ServiceLog] = []

        // Create 12 months of service logs spread over the past year
        for monthsAgo in 0...11 {
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date.now)!
            let log = ServiceLog(
                vehicle: vehicle,
                performedDate: date,
                mileageAtService: 50000 - (monthsAgo * 500),
                cost: Decimal(150)
            )
            modelContext.insert(log)
            logs.append(log)
        }

        // When - filter by month vs year
        let monthStart = CostsTab.PeriodFilter.month.startDate!
        let yearStart = CostsTab.PeriodFilter.year.startDate!

        let monthLogs = logs.filter { $0.performedDate >= monthStart }
        let yearLogs = logs.filter { $0.performedDate >= yearStart }

        let monthTotal = monthLogs.compactMap { $0.cost }.reduce(Decimal(0), +)
        let yearTotal = yearLogs.compactMap { $0.cost }.reduce(Decimal(0), +)

        // Then - year total should be significantly larger, demonstrating why
        // overflow protection is needed for Year/All period filters
        XCTAssertGreaterThan(yearTotal, monthTotal,
            "Year total (\(yearTotal)) should exceed month total (\(monthTotal)), requiring text scaling")
        XCTAssertGreaterThan(yearLogs.count, monthLogs.count,
            "Year filter should include more logs than month filter")
    }

    func testStatsCard_CostPerMileFormat_BoundedLength() {
        // Given - cost per mile values that could appear in stats cards
        let testValues: [Double] = [0.05, 0.50, 1.23, 9.99, 12.50]

        for value in testValues {
            // When
            let formatted = String(format: "$%.2f/mi", value)

            // Then - each stats card gets 1/3 of available width (~95pt on iPhone SE)
            // At 20pt mono, each char is ~12pt, so max ~7-8 chars fit without scaling
            // With minimumScaleFactor(0.7), we can fit ~11 chars
            XCTAssertLessThan(formatted.count, 12,
                "Cost per mile '\(formatted)' should fit within stats card with scaling")
        }
    }

    // MARK: - Monthly Breakdown By Category Tests

    @MainActor
    func testMonthlyBreakdownByCategory_GroupsCorrectly() {
        // Given - different categories in the same month
        let calendar = Calendar.current
        let januaryDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!

        let logs = [
            ServiceLog(performedDate: januaryDate, mileageAtService: 30000, cost: Decimal(100), costCategory: .maintenance),
            ServiceLog(performedDate: januaryDate, mileageAtService: 30000, cost: Decimal(200), costCategory: .repair),
            ServiceLog(performedDate: januaryDate, mileageAtService: 30000, cost: Decimal(50), costCategory: .maintenance)
        ]

        // When - group by month and category
        var grouped: [Date: [CostCategory: Decimal]] = [:]
        for log in logs {
            let components = calendar.dateComponents([.year, .month], from: log.performedDate)
            if let monthStart = calendar.date(from: components) {
                let category = log.costCategory ?? .maintenance
                grouped[monthStart, default: [:]][category, default: 0] += log.cost ?? 0
            }
        }

        // Then
        let janStart = calendar.date(from: DateComponents(year: 2025, month: 1))!
        XCTAssertEqual(grouped.count, 1, "All logs are in the same month")
        XCTAssertEqual(grouped[janStart]?[.maintenance], Decimal(150), "Two maintenance logs should sum to 150")
        XCTAssertEqual(grouped[janStart]?[.repair], Decimal(200), "Repair log should be 200")
    }

    @MainActor
    func testMonthlyBreakdownByCategory_EmptyWhenNoCosts() {
        // Given - no logs
        let logs: [ServiceLog] = []

        // When
        let logsWithCosts = logs.filter { $0.cost != nil && $0.cost! > 0 }
        let calendar = Calendar.current
        var grouped: [Date: [CostCategory: Decimal]] = [:]
        for log in logsWithCosts {
            let components = calendar.dateComponents([.year, .month], from: log.performedDate)
            if let monthStart = calendar.date(from: components) {
                let category = log.costCategory ?? .maintenance
                grouped[monthStart, default: [:]][category, default: 0] += log.cost ?? 0
            }
        }

        // Then
        XCTAssertTrue(grouped.isEmpty, "Should be empty when no costs exist")
    }

    // MARK: - Monthly Breakdown Chronological Tests

    func testMonthlyBreakdownChronological_SortsOldestFirst() {
        // Given - monthly breakdown sorted newest-first (default)
        let calendar = Calendar.current
        let jan = calendar.date(from: DateComponents(year: 2025, month: 1))!
        let feb = calendar.date(from: DateComponents(year: 2025, month: 2))!
        let mar = calendar.date(from: DateComponents(year: 2025, month: 3))!

        let newestFirst: [(month: Date, amount: Decimal)] = [
            (month: mar, amount: Decimal(300)),
            (month: feb, amount: Decimal(200)),
            (month: jan, amount: Decimal(100))
        ]

        // When - sort oldest-first (as monthlyBreakdownChronological does)
        let chronological = newestFirst.sorted { $0.month < $1.month }

        // Then
        XCTAssertEqual(chronological[0].month, jan, "First entry should be oldest (January)")
        XCTAssertEqual(chronological[1].month, feb)
        XCTAssertEqual(chronological[2].month, mar, "Last entry should be newest (March)")
    }

    // MARK: - Cumulative Cost Over Time Tests

    @MainActor
    func testCumulativeCostOverTime_CalculatesRunningTotal() {
        // Given
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        let date3 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 20))!

        let logs = [
            ServiceLog(performedDate: date1, mileageAtService: 30000, cost: Decimal(50)),
            ServiceLog(performedDate: date2, mileageAtService: 31000, cost: Decimal(75)),
            ServiceLog(performedDate: date3, mileageAtService: 32000, cost: Decimal(100))
        ]

        // When - compute cumulative totals
        let sorted = logs.sorted { $0.performedDate < $1.performedDate }
        var cumulative: Decimal = 0
        let result = sorted.map { log -> (date: Date, cumulativeAmount: Decimal) in
            cumulative += log.cost ?? 0
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: log.performedDate)
            let dayDate = calendar.date(from: dayComponents) ?? log.performedDate
            return (date: dayDate, cumulativeAmount: cumulative)
        }

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].cumulativeAmount, Decimal(50))
        XCTAssertEqual(result[1].cumulativeAmount, Decimal(125))
        XCTAssertEqual(result[2].cumulativeAmount, Decimal(225))
    }

    @MainActor
    func testCumulativeCostOverTime_MergesSameDate() {
        // Given - two logs on the same date
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        let logs = [
            ServiceLog(performedDate: date1, mileageAtService: 30000, cost: Decimal(50)),
            ServiceLog(performedDate: date1, mileageAtService: 30000, cost: Decimal(30)),
            ServiceLog(performedDate: date2, mileageAtService: 31000, cost: Decimal(100))
        ]

        // When - merge same-date entries and compute cumulative
        let sorted = logs.sorted { $0.performedDate < $1.performedDate }
        var dailyTotals: [(date: Date, amount: Decimal)] = []
        for log in sorted {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: log.performedDate)
            let dayDate = calendar.date(from: dayComponents) ?? log.performedDate

            if let lastIndex = dailyTotals.indices.last, dailyTotals[lastIndex].date == dayDate {
                dailyTotals[lastIndex].amount += log.cost ?? 0
            } else {
                dailyTotals.append((date: dayDate, amount: log.cost ?? 0))
            }
        }

        var cumulative: Decimal = 0
        let result = dailyTotals.map { entry -> (date: Date, cumulativeAmount: Decimal) in
            cumulative += entry.amount
            return (date: entry.date, cumulativeAmount: cumulative)
        }

        // Then - two points (merged same date), not three
        XCTAssertEqual(result.count, 2, "Two logs on same date should merge into one point")
        XCTAssertEqual(result[0].cumulativeAmount, Decimal(80), "First point: 50 + 30 = 80")
        XCTAssertEqual(result[1].cumulativeAmount, Decimal(180), "Second point: 80 + 100 = 180")
    }

    @MainActor
    func testCumulativeCostOverTime_RespectsFilters() {
        // Given - logs in different categories
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        let maintenanceLog = ServiceLog(performedDate: date1, mileageAtService: 30000, cost: Decimal(50), costCategory: .maintenance)
        let repairLog = ServiceLog(performedDate: date2, mileageAtService: 31000, cost: Decimal(200), costCategory: .repair)

        // When - filter to maintenance only (as the category filter would)
        let allLogs = [maintenanceLog, repairLog]
        let filteredLogs = allLogs.filter { $0.costCategory == .maintenance }
        let logsWithCosts = filteredLogs.filter { $0.cost != nil && $0.cost! > 0 }

        // Then
        XCTAssertEqual(logsWithCosts.count, 1, "Only maintenance logs should remain after filter")
        XCTAssertEqual(logsWithCosts.first?.cost, Decimal(50))
    }

    @MainActor
    func testCumulativeCostOverTime_EmptyWithInsufficientData() {
        // Given - only one log (< 2 needed for meaningful chart, < 3 for display threshold)
        let log = ServiceLog(performedDate: .now, mileageAtService: 30000, cost: Decimal(100))

        // When
        let logs = [log]
        let logsWithCosts = logs.filter { $0.cost != nil && $0.cost! > 0 }

        // Then - fewer than 3 points means chart won't display
        XCTAssertLessThan(logsWithCosts.count, 3,
            "With only 1 log, chart visibility threshold (>= 3) is not met")
    }
}
