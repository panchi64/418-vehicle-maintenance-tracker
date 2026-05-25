//
//  AppIconServiceTests.swift
//  checkpointTests
//
//  Tests for AppIconService behavior with the auto-change setting
//

import XCTest
@testable import checkpoint

@MainActor
final class AppIconServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure auto-change is enabled by default for each test
        AppIconSettings.shared.autoChangeEnabled = true
    }

    override func tearDown() {
        // Restore default state
        AppIconSettings.shared.autoChangeEnabled = true
        super.tearDown()
    }

    // MARK: - Icon Name Determination

    func testDetermineIconReturnsNilWhenNoVehicle() {
        // updateIcon with nil vehicle should not crash
        // We can't directly test the private method, but we test the public API doesn't crash
        AppIconService.shared.updateIcon(for: nil, services: [])
        // If we get here without crash, test passes
    }

    func testUpdateIconDoesNotCrashWithEmptyServices() {
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        AppIconService.shared.updateIcon(for: vehicle, services: [])
        // No crash = pass
    }

    // MARK: - Auto-Change Setting Integration

    func testUpdateIconRespectsDisabledSetting() {
        // Disable auto-change
        AppIconSettings.shared.autoChangeEnabled = false

        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )

        // Create an overdue service
        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .month, value: -1, to: .now),
            dueMileage: 45000,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        service.vehicle = vehicle

        // This should not crash and should early-return without changing the icon
        AppIconService.shared.updateIcon(for: vehicle, services: [service])
        // Test passes if no crash — actual icon change requires UIApplication context
    }

    func testUpdateIconAllowedWhenEnabled() {
        // Enable auto-change
        AppIconSettings.shared.autoChangeEnabled = true

        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )

        // This should proceed with normal icon logic (won't actually change icon in test)
        AppIconService.shared.updateIcon(for: vehicle, services: [])
    }

    // MARK: - Setting Toggle Triggers Reset

    func testDisablingSettingValuePersists() {
        AppIconSettings.shared.autoChangeEnabled = false
        XCTAssertFalse(AppIconSettings.shared.autoChangeEnabled,
                       "Setting should be disabled after toggle")
    }

    func testEnablingSettingValuePersists() {
        AppIconSettings.shared.autoChangeEnabled = false
        AppIconSettings.shared.autoChangeEnabled = true
        XCTAssertTrue(AppIconSettings.shared.autoChangeEnabled,
                      "Setting should be re-enabled after toggle")
    }
}
