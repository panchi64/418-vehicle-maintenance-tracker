//
//  CostTotalsConsistencyTests.swift
//  checkpointTests
//
//  Every surface that states a spend total — the Costs tab, the yearly
//  roundup notification and the PDF export — must quote the same number for
//  the same logs. The rule is `CostAnalyticsService`'s: a visit's entered
//  total counts once (itemized services and line items are its breakdown,
//  never added on top), and a standalone log counts its own cost.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class CostTotalsConsistencyTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    let calendar = Calendar(identifier: .gregorian)
    /// Every log is dated in `year`; `now` sits after all of them.
    let year = 2025
    var serviceDate: Date { calendar.date(from: DateComponents(year: year, month: 6, day: 10))! }
    var now: Date { calendar.date(from: DateComponents(year: year, month: 12, day: 31))! }

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
        vehicle = Vehicle(name: "Test", make: "Honda", model: "Civic", year: 2022, currentMileage: 40_000)
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    private func log(cost: Decimal?, visit: ServiceVisit? = nil) -> ServiceLog {
        let log = ServiceLog(vehicle: vehicle, performedDate: serviceDate, mileageAtService: 40_000,
                             cost: cost, costCategory: cost == nil ? nil : .maintenance)
        log.visit = visit
        modelContext.insert(log)
        return log
    }

    private func visit(total: Decimal?, isItemized: Bool) -> ServiceVisit {
        let visit = ServiceVisit(vehicle: vehicle, performedDate: serviceDate, mileageAtVisit: 40_000,
                                 totalCost: total, costCategory: .repair, isItemized: isItemized)
        modelContext.insert(visit)
        return visit
    }

    private func lineItem(_ amount: Decimal, on visit: ServiceVisit) {
        let item = VisitLineItem(visit: visit, label: "Tax", kind: .tax, amount: amount)
        modelContext.insert(item)
    }

    private func currency(_ amount: Decimal) -> String {
        Formatters.currency.string(from: amount as NSDecimalNumber)!
    }

    /// Asserts the Costs tab, the yearly roundup and the PDF export all state `expected`.
    private func assertAllSurfacesTotal(
        _ logs: [ServiceLog],
        equal expected: Decimal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let costsTab = CostsMetrics(logs: logs, period: .allTime, calendar: calendar, now: now).totalSpent
        let roundup = CostAnalyticsService.totalSpent(on: logs, inYear: year, calendar: calendar)
        let pdf = ServiceHistoryPDFService.shared
            .buildExportData(for: vehicle, serviceLogs: logs, options: ExportOptions())
            .totalString

        XCTAssertEqual(costsTab, expected, "Costs tab", file: file, line: line)
        XCTAssertEqual(roundup, expected, "Yearly roundup", file: file, line: line)
        XCTAssertEqual(pdf, currency(expected), "PDF export", file: file, line: line)
    }

    // MARK: - Totals

    func test_totals_nonItemizedVisit_countsVisitTotalOnce() {
        let shopVisit = visit(total: 300, isItemized: false)
        let logs = (0..<3).map { _ in log(cost: nil, visit: shopVisit) }

        assertAllSurfacesTotal(logs, equal: 300)
    }

    func test_totals_itemizedVisit_countsVisitTotalNotBreakdown() {
        // $80 + $70 services, $30 tax line item, $20 unitemized shop charge.
        let shopVisit = visit(total: 200, isItemized: true)
        let logs = [log(cost: 80, visit: shopVisit), log(cost: 70, visit: shopVisit)]
        lineItem(30, on: shopVisit)

        assertAllSurfacesTotal(logs, equal: 200)
    }

    func test_totals_itemizedVisitWithoutTotal_countsBreakdownOnce() {
        let shopVisit = visit(total: nil, isItemized: true)
        let logs = [log(cost: 80, visit: shopVisit), log(cost: 70, visit: shopVisit)]
        lineItem(30, on: shopVisit)

        assertAllSurfacesTotal(logs, equal: 180)
    }

    func test_totals_standaloneLogs_countOwnCosts() {
        let logs = [log(cost: 45), log(cost: 30.25), log(cost: nil)]

        assertAllSurfacesTotal(logs, equal: 75.25)
    }

    func test_totals_mixedVisitsAndStandalone_agree() {
        let plain = visit(total: 300, isItemized: false)
        let itemized = visit(total: 200, isItemized: true)
        lineItem(30, on: itemized)
        let logs = [
            log(cost: nil, visit: plain),
            log(cost: nil, visit: plain),
            log(cost: 80, visit: itemized),
            log(cost: 70, visit: itemized),
            log(cost: 45),
        ]

        assertAllSurfacesTotal(logs, equal: 545)
    }

    // MARK: - Roundup year scoping

    func test_roundup_excludesOtherYears() {
        let thisYear = log(cost: 100)
        let nextYear = ServiceLog(vehicle: vehicle,
                                  performedDate: calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!,
                                  mileageAtService: 41_000, cost: 999)
        modelContext.insert(nextYear)

        let logs = [nextYear, thisYear]
        XCTAssertEqual(CostAnalyticsService.totalSpent(on: logs, inYear: year, calendar: calendar), 100)
    }

    // MARK: - PDF rows

    func test_pdfRows_showOnlyAttributableCosts() {
        let plain = visit(total: 300, isItemized: false)
        let itemized = visit(total: 200, isItemized: true)
        let plainLog = log(cost: nil, visit: plain)
        let itemizedLog = log(cost: 80, visit: itemized)
        let standalone = log(cost: 45)

        let rows = ServiceHistoryPDFService.shared
            .buildExportData(for: vehicle, serviceLogs: [plainLog, itemizedLog, standalone], options: ExportOptions())
            .logs
            .compactMap(\.costString)

        XCTAssertEqual(Set(rows), [currency(80), currency(45)])
    }
}
