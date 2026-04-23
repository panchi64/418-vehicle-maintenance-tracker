//
//  SeasonalSettingsTests.swift
//  checkpointTests
//
//  Tests for SeasonalSettings persistence and dismissal logic
//

import XCTest
@testable import checkpoint

@MainActor
final class SeasonalSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SeasonalSettings.shared.reset()
    }

    override func tearDown() {
        SeasonalSettings.shared.reset()
        super.tearDown()
    }

    // MARK: - Default Values

    func test_defaultValues() {
        let settings = SeasonalSettings.shared
        XCTAssertTrue(settings.isEnabled, "Should be enabled by default")
        XCTAssertNil(settings.climateZone, "Climate zone should be nil by default")
        XCTAssertTrue(settings.dismissedReminders.isEmpty, "Dismissed should be empty by default")
        XCTAssertTrue(settings.suppressedReminders.isEmpty, "Suppressed should be empty by default")
    }

    // MARK: - Dismissal Tests

    func test_dismissForYear_persistsAndFilters() {
        let settings = SeasonalSettings.shared
        settings.dismissForYear("winterTires", year: 2026)

        XCTAssertTrue(settings.isDismissed("winterTires", year: 2026), "Should be dismissed for 2026")
    }

    func test_dismissForYear_doesNotAffectOtherYears() {
        let settings = SeasonalSettings.shared
        settings.dismissForYear("winterTires", year: 2026)

        XCTAssertFalse(settings.isDismissed("winterTires", year: 2027), "Should not be dismissed for 2027")
        XCTAssertFalse(settings.isDismissed("winterTires", year: 2025), "Should not be dismissed for 2025")
    }

    func test_dismissForYear_doesNotAffectOtherReminders() {
        let settings = SeasonalSettings.shared
        settings.dismissForYear("winterTires", year: 2026)

        XCTAssertFalse(settings.isDismissed("antifreeze", year: 2026), "Should not affect other reminders")
    }

    // MARK: - Suppression Tests

    func test_suppressPermanently_persists() {
        let settings = SeasonalSettings.shared
        settings.suppressPermanently("antifreeze")

        XCTAssertTrue(settings.isSuppressed("antifreeze"), "Should be permanently suppressed")
    }

    func test_suppressPermanently_doesNotAffectOtherReminders() {
        let settings = SeasonalSettings.shared
        settings.suppressPermanently("antifreeze")

        XCTAssertFalse(settings.isSuppressed("winterTires"), "Should not affect other reminders")
    }

    // MARK: - Toggle Tests

    func test_toggleEnabled_persists() {
        let settings = SeasonalSettings.shared

        settings.isEnabled = false
        XCTAssertFalse(settings.isEnabled, "Should be disabled after toggle")

        let stored = UserDefaults.standard.bool(forKey: "seasonalRemindersEnabled")
        XCTAssertFalse(stored, "Disabled state should persist to UserDefaults")

        settings.isEnabled = true
        XCTAssertTrue(settings.isEnabled, "Should be enabled after toggle back")
    }

    // MARK: - Climate Zone Tests

    func test_climateZone_persists() {
        let settings = SeasonalSettings.shared

        settings.climateZone = .hotDry
        let stored = UserDefaults.standard.string(forKey: "seasonalClimateZone")
        XCTAssertEqual(stored, "hotDry", "Climate zone should persist to UserDefaults")

        settings.climateZone = .tropical
        let stored2 = UserDefaults.standard.string(forKey: "seasonalClimateZone")
        XCTAssertEqual(stored2, "tropical", "Updated climate zone should persist")
    }

    func test_climateZone_nilClearsStorage() {
        let settings = SeasonalSettings.shared

        settings.climateZone = .coldWinter
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "seasonalClimateZone"))

        settings.climateZone = nil
        XCTAssertNil(UserDefaults.standard.string(forKey: "seasonalClimateZone"), "Nil zone should clear storage")
    }

    // MARK: - Persistence to UserDefaults

    func test_dismissedReminders_persistToUserDefaults() {
        let settings = SeasonalSettings.shared
        settings.dismissForYear("winterTires", year: 2026)
        settings.dismissForYear("antifreeze", year: 2026)

        let stored = UserDefaults.standard.stringArray(forKey: "seasonalDismissedReminders") ?? []
        XCTAssertTrue(stored.contains("winterTires-2026"), "Dismissed keys should persist")
        XCTAssertTrue(stored.contains("antifreeze-2026"), "Multiple dismissed keys should persist")
    }

    func test_suppressedReminders_persistToUserDefaults() {
        let settings = SeasonalSettings.shared
        settings.suppressPermanently("batteryHeat")

        let stored = UserDefaults.standard.stringArray(forKey: "seasonalSuppressedReminders") ?? []
        XCTAssertTrue(stored.contains("batteryHeat"), "Suppressed IDs should persist")
    }
}
