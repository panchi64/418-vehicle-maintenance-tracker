//
//  QueryIntentTests.swift
//  checkpointTests
//
//  The read-only intents answer from the store through the registered
//  container: what's due, what's overdue, when a service was last done, and
//  what was spent — the same figures the app shows.
//

import XCTest
import AppIntents
import SwiftData
@testable import checkpoint

final class QueryIntentTests: IntentTestCase {

    // MARK: - Due

    func test_upcoming_mostUrgentFirst_trackedOnly() {
        addService("Coolant Flush", dueInDays: 120)
        addService("Oil Change", dueInDays: -5)
        addService("Wiper Blades", dueInDays: nil, intervalMonths: nil, intervalMiles: nil, isRecurring: false)

        let rows = DueServices.upcoming(on: vehicle)

        XCTAssertEqual(rows.map(\.name), ["Oil Change", "Coolant Flush"])
        XCTAssertEqual(rows.first?.status, .overdue)
        XCTAssertFalse(rows[0].due.isEmpty)
    }

    func test_checkNextDue_answer_namesTheMostUrgent() {
        addService("Coolant Flush", dueInDays: 120)
        addService("Oil Change", dueInDays: -5)

        let answer = CheckNextDueIntent.answer(DueServices.upcoming(on: vehicle).first, vehicle: vehicle)

        XCTAssertTrue(answer.hasPrefix("Oil Change on Daily is overdue"), answer)
    }

    func test_checkNextDue_nothingScheduled() {
        XCTAssertEqual(
            CheckNextDueIntent.answer(nil, vehicle: vehicle),
            L10n.siriNothingScheduled(vehicle: "Daily")
        )
    }

    func test_checkNextDue_perform_readsTheStoreNotASnapshot() async throws {
        addService("Oil Change", dueInDays: -5)
        try context.save()

        // Resolves through the registered container; nothing in the App
        // Group snapshot the old read path used.
        _ = try await wired(CheckNextDueIntent()).perform()
    }

    func test_listUpcoming_answer_coversEachService() {
        addService("Oil Change", dueInDays: -5)
        addService("Coolant Flush", dueInDays: 120)

        let answer = ListUpcomingServicesIntent.answer(DueServices.upcoming(on: vehicle), vehicle: vehicle)

        XCTAssertTrue(answer.contains("Oil Change is overdue"), answer)
        XCTAssertTrue(answer.contains("Coolant Flush"), answer)
    }

    func test_listOverdue_onlyOverdue() async throws {
        addService("Oil Change", dueInDays: -5)
        addService("Tire Rotation", dueInDays: -1)
        addService("Coolant Flush", dueInDays: 120)
        try context.save()

        let result = try await wired(ListOverdueIntent()).perform()

        XCTAssertEqual(Set(result.value?.map(\.name) ?? []), ["Oil Change", "Tire Rotation"])
        XCTAssertTrue(ListOverdueIntent.answer(DueServices.overdue(on: vehicle), vehicle: vehicle).hasPrefix("2 services"))
    }

    func test_listOverdue_none() {
        addService("Coolant Flush", dueInDays: 120)
        XCTAssertEqual(
            ListOverdueIntent.answer(DueServices.overdue(on: vehicle), vehicle: vehicle),
            L10n.siriOverdueNone(vehicle: "Daily")
        )
    }

    // MARK: - Last service

    func test_lastService_newestMatchOnThisVehicle() throws {
        let oil = addService("Oil Change")
        addLog(for: oil, daysAgo: 200, mileage: 38_000)
        let newest = addLog(for: oil, daysAgo: 20, mileage: 44_500)
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        context.insert(other)
        addLog(for: addService("Oil Change", to: other), daysAgo: 1)
        try context.save()

        let found = try LastServiceQueryIntent.lastLog(matching: "oil", on: vehicle, in: context)

        XCTAssertEqual(found?.id, newest.id)
    }

    func test_lastService_matchesServiceNameNotNotes() throws {
        let rotation = addService("Tire Rotation")
        let log = addLog(for: rotation, daysAgo: 5)
        log.notes = "Topped up the oil"
        try context.save()

        XCTAssertNil(try LastServiceQueryIntent.lastLog(matching: "oil", on: vehicle, in: context))
    }

    func test_lastService_perform_returnsTheEntry() async throws {
        let oil = addService("Oil Change")
        let log = addLog(for: oil, daysAgo: 20)
        try context.save()
        let intent = LastServiceQueryIntent()
        intent.service = "oil change"

        let result = try await wired(intent).perform()

        XCTAssertEqual(result.value??.id, log.id)
    }

    // MARK: - Spending

    func test_spending_matchesCostAnalyticsService() async throws {
        let oil = addService("Oil Change")
        addLog(for: oil, daysAgo: 10, cost: 60)
        addLog(for: oil, daysAgo: 40, cost: 55)
        try context.save()
        let intent = SpendingSummaryIntent()
        intent.period = .last30Days

        let result = try await wired(intent).perform()

        let expected = CostAnalyticsService.summary(logs: vehicle.serviceLogs ?? [], period: .last30Days)
        XCTAssertEqual(result.value?.amount, expected.total)
        XCTAssertEqual(expected.total, 60)
    }

    func test_spending_answer_withAndWithoutCategory() {
        let summary = CostSummary(
            period: .yearToDate, category: nil, total: 115, expenseCount: 2,
            totalsByBucket: [.category(.maintenance): 100, .category(.repair): 15]
        )
        let answer = SpendingSummaryIntent.answer(summary, total: "$115.00", vehicle: vehicle)
        XCTAssertTrue(answer.contains("$115.00") && answer.contains(CostPeriod.yearToDate.fullName), answer)

        let narrowed = CostSummary(
            period: .yearToDate, category: .repair, total: 15, expenseCount: 1, totalsByBucket: [:]
        )
        let categoryAnswer = SpendingSummaryIntent.answer(narrowed, total: "$15.00", vehicle: vehicle)
        XCTAssertTrue(categoryAnswer.contains(CostCategory.repair.displayName), categoryAnswer)
    }

    func test_spending_breakdown_fixedOrder_skipsEmpty() {
        let summary = CostSummary(
            period: .allTime, category: nil, total: 130, expenseCount: 3,
            totalsByBucket: [.uncategorized: 10, .category(.repair): 20, .category(.maintenance): 100, .category(.upgrade): 0]
        )
        XCTAssertEqual(
            SpendingSummaryIntent.breakdown(summary).map(\.label),
            [CostCategory.maintenance.displayName, CostCategory.repair.displayName, L10n.costsUncategorized]
        )
    }

    // MARK: - Resolution

    func test_intentStore_noVehicleNamed_usesTheSelectedOne() throws {
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        context.insert(other)
        try context.save()

        XCTAssertEqual(try IntentStore.vehicle(for: nil, in: context).id, vehicle.id)
        UserDefaults.standard.set(other.id.uuidString, forKey: AppGroupConstants.appSelectedVehicleIDKey)
        XCTAssertEqual(try IntentStore.vehicle(for: nil, in: context).id, other.id)
    }

    func test_intentStore_noVehicles_throws() throws {
        context.delete(vehicle)
        try context.save()
        XCTAssertThrowsError(try IntentStore.vehicle(for: nil, in: context)) { error in
            XCTAssertEqual(error as? IntentError, .noVehicles)
        }
    }
}
