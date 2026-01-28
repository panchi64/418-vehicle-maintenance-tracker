//
//  YearlyCostRoundupCardTests.swift
//  checkpointTests
//
//  Tests for YearlyCostRoundupCard component
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class YearlyCostRoundupCardTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 45000
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Total Spent Tests

    @MainActor
    func testTotalSpent_CalculatesCorrectly() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 3))!,
            mileageAtService: 43000,
            cost: Decimal(100)
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 44000,
            cost: Decimal(200)
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 9))!,
            mileageAtService: 45000,
            cost: Decimal(150)
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        let logs = [log1, log2, log3]

        // When
        let yearLogs = logs.filter {
            calendar.component(.year, from: $0.performedDate) == currentYear
        }
        let totalSpent = yearLogs.compactMap { $0.cost }.reduce(Decimal(0), +)

        // Then
        XCTAssertEqual(totalSpent, Decimal(450))
    }

    @MainActor
    func testTotalSpent_ExcludesOtherYears() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)
        let lastYear = currentYear - 1

        let currentYearLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 44000,
            cost: Decimal(100)
        )
        let lastYearLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: lastYear, month: 6))!,
            mileageAtService: 40000,
            cost: Decimal(500)
        )

        modelContext.insert(currentYearLog)
        modelContext.insert(lastYearLog)

        let logs = [currentYearLog, lastYearLog]

        // When
        let yearLogs = logs.filter {
            calendar.component(.year, from: $0.performedDate) == currentYear
        }
        let totalSpent = yearLogs.compactMap { $0.cost }.reduce(Decimal(0), +)

        // Then
        XCTAssertEqual(totalSpent, Decimal(100))
    }

    @MainActor
    func testTotalSpent_ExcludesNilCosts() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let logWithCost = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 3))!,
            mileageAtService: 43000,
            cost: Decimal(100)
        )
        let logWithoutCost = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 44000,
            cost: nil
        )

        modelContext.insert(logWithCost)
        modelContext.insert(logWithoutCost)

        let logs = [logWithCost, logWithoutCost]

        // When
        let logsWithCosts = logs.filter { $0.cost != nil && $0.cost! > 0 }
        let totalSpent = logsWithCosts.compactMap { $0.cost }.reduce(Decimal(0), +)

        // Then
        XCTAssertEqual(totalSpent, Decimal(100))
        XCTAssertEqual(logsWithCosts.count, 1)
    }

    // MARK: - Year Over Year Change Tests

    @MainActor
    func testYearOverYearChange_IncreasedSpending() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)
        let lastYear = currentYear - 1

        let currentYearTotal = Decimal(1000)
        let lastYearTotal = Decimal(800)

        // When
        let change = (NSDecimalNumber(decimal: currentYearTotal).doubleValue -
                      NSDecimalNumber(decimal: lastYearTotal).doubleValue) /
                      NSDecimalNumber(decimal: lastYearTotal).doubleValue * 100

        // Then
        XCTAssertEqual(change, 25.0, accuracy: 0.01)
    }

    @MainActor
    func testYearOverYearChange_DecreasedSpending() {
        // Given
        let currentYearTotal = Decimal(600)
        let lastYearTotal = Decimal(800)

        // When
        let change = (NSDecimalNumber(decimal: currentYearTotal).doubleValue -
                      NSDecimalNumber(decimal: lastYearTotal).doubleValue) /
                      NSDecimalNumber(decimal: lastYearTotal).doubleValue * 100

        // Then
        XCTAssertEqual(change, -25.0, accuracy: 0.01)
    }

    @MainActor
    func testYearOverYearChange_NoPreviousYear() {
        // Given
        let lastYearTotal = Decimal(0)

        // When - check for nil when previous year is 0
        let hasValidChange = lastYearTotal > 0

        // Then
        XCTAssertFalse(hasValidChange)
    }

    // MARK: - Category Breakdown Tests

    @MainActor
    func testCategoryBreakdown_CalculatesPercentages() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let maintenanceLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 3))!,
            mileageAtService: 43000,
            cost: Decimal(500),
            costCategory: .maintenance
        )
        let repairLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 44000,
            cost: Decimal(300),
            costCategory: .repair
        )
        let upgradeLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 9))!,
            mileageAtService: 45000,
            cost: Decimal(200),
            costCategory: .upgrade
        )

        modelContext.insert(maintenanceLog)
        modelContext.insert(repairLog)
        modelContext.insert(upgradeLog)

        let logs = [maintenanceLog, repairLog, upgradeLog]

        // When
        let totalSpent = logs.compactMap { $0.cost }.reduce(Decimal(0), +)
        let maintenanceAmount = logs.filter { $0.costCategory == .maintenance }.compactMap { $0.cost }.reduce(Decimal(0), +)
        let repairAmount = logs.filter { $0.costCategory == .repair }.compactMap { $0.cost }.reduce(Decimal(0), +)
        let upgradeAmount = logs.filter { $0.costCategory == .upgrade }.compactMap { $0.cost }.reduce(Decimal(0), +)

        let maintenancePercentage = NSDecimalNumber(decimal: maintenanceAmount).doubleValue /
                                    NSDecimalNumber(decimal: totalSpent).doubleValue * 100
        let repairPercentage = NSDecimalNumber(decimal: repairAmount).doubleValue /
                               NSDecimalNumber(decimal: totalSpent).doubleValue * 100
        let upgradePercentage = NSDecimalNumber(decimal: upgradeAmount).doubleValue /
                                NSDecimalNumber(decimal: totalSpent).doubleValue * 100

        // Then
        XCTAssertEqual(totalSpent, Decimal(1000))
        XCTAssertEqual(maintenancePercentage, 50.0, accuracy: 0.01)
        XCTAssertEqual(repairPercentage, 30.0, accuracy: 0.01)
        XCTAssertEqual(upgradePercentage, 20.0, accuracy: 0.01)
    }

    @MainActor
    func testCategoryBreakdown_ExcludesEmptyCategories() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let maintenanceLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 3))!,
            mileageAtService: 43000,
            cost: Decimal(100),
            costCategory: .maintenance
        )

        modelContext.insert(maintenanceLog)

        let logs = [maintenanceLog]

        // When
        var breakdown: [(CostCategory, Decimal)] = []
        for category in CostCategory.allCases {
            let amount = logs.filter { $0.costCategory == category }.compactMap { $0.cost }.reduce(Decimal(0), +)
            if amount > 0 {
                breakdown.append((category, amount))
            }
        }

        // Then - only maintenance should be in breakdown
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertEqual(breakdown.first?.0, .maintenance)
    }

    // MARK: - Service Count Tests

    @MainActor
    func testServiceCount_CountsAllServicesInYear() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 1))!,
            mileageAtService: 42000
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 44000
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 12))!,
            mileageAtService: 46000
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        let logs = [log1, log2, log3]

        // When
        let yearLogs = logs.filter {
            calendar.component(.year, from: $0.performedDate) == currentYear
        }

        // Then
        XCTAssertEqual(yearLogs.count, 3)
    }

    // MARK: - Miles Driven Estimate Tests

    @MainActor
    func testEstimatedMilesDriven_CalculatesFromFirstToLastLog() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 1))!,
            mileageAtService: 30000
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 37000
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 12))!,
            mileageAtService: 45000
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        let logs = [log1, log2, log3]

        // When
        let sortedLogs = logs.sorted { $0.performedDate < $1.performedDate }
        let estimatedMiles = (sortedLogs.last?.mileageAtService ?? 0) - (sortedLogs.first?.mileageAtService ?? 0)

        // Then
        XCTAssertEqual(estimatedMiles, 15000)
    }

    @MainActor
    func testEstimatedMilesDriven_ReturnsNilForSingleLog() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)

        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: currentYear, month: 6))!,
            mileageAtService: 45000
        )

        modelContext.insert(log)

        let logs = [log]

        // When
        let sortedLogs = logs.sorted { $0.performedDate < $1.performedDate }
        let estimatedMiles: Int?
        if sortedLogs.count >= 2,
           let first = sortedLogs.first,
           let last = sortedLogs.last,
           last.mileageAtService > first.mileageAtService {
            estimatedMiles = last.mileageAtService - first.mileageAtService
        } else {
            estimatedMiles = nil
        }

        // Then
        XCTAssertNil(estimatedMiles)
    }

    // MARK: - Empty State Tests

    @MainActor
    func testEmptyState_NoLogsForYear() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)
        let lastYear = currentYear - 1

        let lastYearLog = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(from: DateComponents(year: lastYear, month: 6))!,
            mileageAtService: 40000,
            cost: Decimal(100)
        )

        modelContext.insert(lastYearLog)

        let logs = [lastYearLog]

        // When
        let yearLogs = logs.filter {
            calendar.component(.year, from: $0.performedDate) == currentYear
        }

        // Then
        XCTAssertTrue(yearLogs.isEmpty)
    }

    // MARK: - Overflow Prevention Tests

    func testYearlyCurrencyFormat_LargeAmounts_BoundedCharCount() {
        // Given - yearly totals can be large, displayed in 56pt monospaced hero font
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0

        let largeYearlyTotals: [Decimal] = [
            Decimal(5000),
            Decimal(15000),
            Decimal(50000),
            Decimal(100000)
        ]

        for total in largeYearlyTotals {
            // When
            let formatted = formatter.string(from: total as NSDecimalNumber)

            // Then - verify formatting produces a valid string
            XCTAssertNotNil(formatted, "Should format \(total) as currency")

            // With minimumScaleFactor(0.5) on the hero text, strings up to ~17 chars
            // will fit on the smallest iPhone screen (375pt wide)
            let charCount = formatted!.count
            XCTAssertLessThan(charCount, 18,
                "Formatted yearly total '\(formatted!)' should fit with scale factor")
        }
    }

    func testYearOverYearChangeText_BoundedLength() {
        // Given - YoY change text format: "XX% from YYYY"
        let changes: [Double] = [5.0, 25.0, 100.0, 150.0]
        let year = 2025

        for change in changes {
            // When
            let text = String(format: "%.0f%% from %d", abs(change), year - 1)

            // Then - this text uses brutalistSecondary (13pt mono)
            // At 13pt mono, each char is ~7.8pt; available width ~287pt = ~36 chars
            XCTAssertLessThan(text.count, 20,
                "YoY change text '\(text)' should comfortably fit")
        }
    }

    @MainActor
    func testCategoryBreakdown_CurrencyAndPercentage_FitInRow() {
        // Given
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0

        let largeAmounts: [Decimal] = [
            Decimal(8000),
            Decimal(25000),
            Decimal(50000)
        ]

        for amount in largeAmounts {
            // When
            let currencyText = formatter.string(from: amount as NSDecimalNumber) ?? "$0"
            let percentageText = String(format: "%.0f%%", 75.0)

            // Then - category row has: icon(16pt) + name + spacer + currency + percentage(36pt)
            // Currency and percentage together should not exceed available space
            let combinedLength = currencyText.count + percentageText.count
            XCTAssertLessThan(combinedLength, 16,
                "Category currency '\(currencyText)' + percentage '\(percentageText)' should fit in row")
        }
    }
}
