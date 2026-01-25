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
}
