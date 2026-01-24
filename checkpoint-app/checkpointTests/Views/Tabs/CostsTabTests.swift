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
            for: Vehicle.self, Service.self, ServiceLog.self,
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
}
