//
//  AppIconSettingsTests.swift
//  checkpointTests
//
//  Tests for AppIconSettings persistence and default values
//

import XCTest
@testable import checkpoint

@MainActor
final class AppIconSettingsTests: XCTestCase {

    private let autoChangeKey = AppIconSettings.autoChangeIconKey
    private let appGroupID = AppGroupConstants.iPhoneWidget

    override func setUp() {
        super.setUp()
        // Reset to default before each test
        UserDefaults.standard.removeObject(forKey: autoChangeKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: autoChangeKey)
    }

    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: autoChangeKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: autoChangeKey)
        // Restore to default enabled state so other tests aren't affected
        AppIconSettings.shared.autoChangeEnabled = true
        super.tearDown()
    }

    // MARK: - Default Value Tests

    func testDefaultValueIsDisabledForNewInstall() {
        let hadOnboarded = OnboardingState.hasCompletedOnboarding
        defer { OnboardingState.hasCompletedOnboarding = hadOnboarded }
        OnboardingState.hasCompletedOnboarding = false

        AppIconSettings.registerDefaults()

        // Each switch raises an unrequested system alert, so a new install is off.
        let value = UserDefaults.standard.bool(forKey: autoChangeKey)
        XCTAssertFalse(value, "New installs should default to auto-change disabled")
    }

    func testExistingUserKeepsAutoChangeEnabled() {
        let hadOnboarded = OnboardingState.hasCompletedOnboarding
        defer { OnboardingState.hasCompletedOnboarding = hadOnboarded }
        OnboardingState.hasCompletedOnboarding = true

        AppIconSettings.registerDefaults()

        // Pinned explicitly, so it survives the registered default being false.
        let explicit = UserDefaults.standard.persistentDomain(
            forName: Bundle.main.bundleIdentifier ?? ""
        )?[autoChangeKey] as? Bool
        XCTAssertEqual(explicit, true, "An onboarded user who never chose should keep the old default")
    }

    // MARK: - Persistence Tests

    func testSettingPersistsToStandardUserDefaults() {
        let settings = AppIconSettings.shared

        // Disable auto-change
        settings.autoChangeEnabled = false

        UserDefaults.standard.synchronize()

        let rawValue = UserDefaults.standard.bool(forKey: autoChangeKey)
        XCTAssertFalse(rawValue, "Disabled state should persist to standard UserDefaults")
    }

    func testSettingPersistsToAppGroup() {
        let settings = AppIconSettings.shared

        // Disable auto-change
        settings.autoChangeEnabled = false

        let rawValue = UserDefaults(suiteName: appGroupID)?.bool(forKey: autoChangeKey)
        XCTAssertEqual(rawValue, false, "Disabled state should sync to App Group UserDefaults")
    }

    func testReEnablingPersists() {
        let settings = AppIconSettings.shared

        // Disable then re-enable
        settings.autoChangeEnabled = false
        settings.autoChangeEnabled = true

        UserDefaults.standard.synchronize()

        let rawValue = UserDefaults.standard.bool(forKey: autoChangeKey)
        XCTAssertTrue(rawValue, "Re-enabled state should persist")
    }

    // MARK: - Singleton Tests

    func testSharedInstanceReturnsSameInstance() {
        let instance1 = AppIconSettings.shared
        let instance2 = AppIconSettings.shared
        XCTAssertTrue(instance1 === instance2, "Shared should return same instance")
    }

    // MARK: - Toggle Behavior Tests

    func testToggleUpdatesValue() {
        let settings = AppIconSettings.shared

        settings.autoChangeEnabled = true
        XCTAssertTrue(settings.autoChangeEnabled)

        settings.autoChangeEnabled = false
        XCTAssertFalse(settings.autoChangeEnabled)

        settings.autoChangeEnabled = true
        XCTAssertTrue(settings.autoChangeEnabled)
    }

    func testSettingSameValueDoesNotTriggerPersist() {
        let settings = AppIconSettings.shared

        // Set to true (already default)
        settings.autoChangeEnabled = true

        // Setting the same value should be a no-op (didSet guard)
        // This test verifies the property can be set without error
        settings.autoChangeEnabled = true
        XCTAssertTrue(settings.autoChangeEnabled, "Value should remain true")
    }

    // MARK: - Default Registration Tests

    func testRegisterDefaultsSetsAppGroupFalseForNewInstall() {
        let hadOnboarded = OnboardingState.hasCompletedOnboarding
        defer { OnboardingState.hasCompletedOnboarding = hadOnboarded }
        OnboardingState.hasCompletedOnboarding = false
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: autoChangeKey)

        AppIconSettings.registerDefaults()

        let value = UserDefaults(suiteName: appGroupID)?.bool(forKey: autoChangeKey)
        XCTAssertEqual(value, false, "App Group should mirror the new-install default")
    }
}
