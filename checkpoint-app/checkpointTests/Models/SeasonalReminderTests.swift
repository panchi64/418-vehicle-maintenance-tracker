//
//  SeasonalReminderTests.swift
//  checkpointTests
//
//  Tests for seasonal reminder catalog and active filtering logic
//

import XCTest
@testable import checkpoint

@MainActor
final class SeasonalReminderTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - Helpers

    /// Create a date for a specific month/day/year
    private func makeDate(month: Int, day: Int, year: Int = 2026) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }

    override func setUp() {
        super.setUp()
        SeasonalSettings.shared.reset()
    }

    override func tearDown() {
        SeasonalSettings.shared.reset()
        super.tearDown()
    }

    // MARK: - Catalog Tests

    func test_allReminders_returnsExpectedCount() {
        XCTAssertEqual(SeasonalReminder.allReminders.count, 8, "Should have 8 reminders in catalog")
    }

    // MARK: - Active Reminders Tests

    func test_activeReminders_coldWinter_october_includesWinterTires() {
        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date)
        let ids = active.map(\.id)
        XCTAssertTrue(ids.contains("winterTires"), "Cold winter zone in October should include winter tires")
    }

    func test_activeReminders_coldWinter_october_includesAntifreeze() {
        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date)
        let ids = active.map(\.id)
        XCTAssertTrue(ids.contains("antifreeze"), "Cold winter zone in October should include antifreeze check")
    }

    func test_activeReminders_hotDry_october_excludesWinterTires() {
        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .hotDry, on: date)
        let ids = active.map(\.id)
        XCTAssertFalse(ids.contains("winterTires"), "Hot dry zone should not include winter tires")
    }

    func test_activeReminders_hotDry_may_includesBatteryCheck() {
        let date = makeDate(month: 5, day: 15)
        let active = SeasonalReminder.activeReminders(for: .hotDry, on: date)
        let ids = active.map(\.id)
        XCTAssertTrue(ids.contains("batteryHeat"), "Hot dry zone in May should include battery check")
    }

    func test_activeReminders_outsideDisplayWindow_returnsEmpty() {
        // July 15 — no cold winter reminders are active in July
        let date = makeDate(month: 7, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date)
        XCTAssertTrue(active.isEmpty, "No cold winter reminders should be active in July")
    }

    func test_activeReminders_dismissedForYear_excluded() {
        let settings = SeasonalSettings.shared
        settings.dismissForYear("winterTires", year: 2026)

        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date, settings: settings)
        let ids = active.map(\.id)
        XCTAssertFalse(ids.contains("winterTires"), "Dismissed reminders should be excluded")
        // Antifreeze should still be active
        XCTAssertTrue(ids.contains("antifreeze"), "Non-dismissed reminders should still show")
    }

    func test_activeReminders_permanentlySuppressed_excluded() {
        let settings = SeasonalSettings.shared
        settings.suppressPermanently("antifreeze")

        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date, settings: settings)
        let ids = active.map(\.id)
        XCTAssertFalse(ids.contains("antifreeze"), "Suppressed reminders should be excluded")
    }

    func test_activeReminders_disabledSetting_returnsEmpty() {
        let settings = SeasonalSettings.shared
        settings.isEnabled = false

        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: .coldWinter, on: date, settings: settings)
        XCTAssertTrue(active.isEmpty, "Disabled setting should return empty")
    }

    func test_activeReminders_nilClimateZone_returnsEmpty() {
        let date = makeDate(month: 10, day: 15)
        let active = SeasonalReminder.activeReminders(for: nil, on: date)
        XCTAssertTrue(active.isEmpty, "Nil climate zone should return empty")
    }

    // MARK: - Display Window Edge Cases

    func test_displayWindow_firstDayOfTargetMonth_isActive() {
        // Oct 1 should be within window for Oct reminders
        let date = makeDate(month: 10, day: 1)
        let winterTires = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!
        XCTAssertTrue(winterTires.isWithinDisplayWindow(on: date), "First day of target month should be active")
    }

    func test_displayWindow_lastDayOfTargetMonth_isActive() {
        // Oct 31 should be within window for Oct reminders
        let date = makeDate(month: 10, day: 31)
        let winterTires = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!
        XCTAssertTrue(winterTires.isWithinDisplayWindow(on: date), "Last day of target month should be active")
    }

    func test_displayWindow_beforeWindow_isNotActive() {
        // Aug 31 — 30 days before Oct 1 is Sep 1, so Aug 31 is outside
        let date = makeDate(month: 8, day: 31)
        let winterTires = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!
        XCTAssertFalse(winterTires.isWithinDisplayWindow(on: date), "Before window start should not be active")
    }

    func test_displayWindow_windowStartDay_isActive() {
        // Sep 1 — exactly 30 days before Oct 1
        let date = makeDate(month: 9, day: 1)
        let winterTires = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!
        XCTAssertTrue(winterTires.isWithinDisplayWindow(on: date), "Window start day should be active")
    }

    func test_displayWindow_dayAfterTargetMonth_isNotActive() {
        // Nov 1 — after Oct ends
        let date = makeDate(month: 11, day: 1)
        let winterTires = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!
        XCTAssertFalse(winterTires.isWithinDisplayWindow(on: date), "Day after target month should not be active")
    }

    func test_displayWindow_shortWindow_14days() {
        // Salt damage: target March, 14 day window → active from Feb 15 through Mar 31
        let saltDamage = SeasonalReminder.allReminders.first { $0.id == "saltDamage" }!

        let withinWindow = makeDate(month: 2, day: 15)
        XCTAssertTrue(saltDamage.isWithinDisplayWindow(on: withinWindow), "Feb 15 should be within 14-day window for March")

        let beforeWindow = makeDate(month: 2, day: 14)
        XCTAssertFalse(saltDamage.isWithinDisplayWindow(on: beforeWindow), "Feb 14 should be outside 14-day window for March")
    }
}
