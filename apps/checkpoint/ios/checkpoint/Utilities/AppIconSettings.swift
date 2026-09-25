//
//  AppIconSettings.swift
//  checkpoint
//
//  Observable singleton for automatic app icon switching preference
//  Persists to UserDefaults with App Group sync
//

import Foundation

@Observable
@MainActor
final class AppIconSettings {
    // MARK: - Singleton

    static let shared = AppIconSettings()

    // MARK: - Storage Keys

    static let autoChangeIconKey = "autoChangeAppIcon"
    // MARK: - UserDefaults

    private static var standardDefaults: UserDefaults { .standard }
    private static var sharedDefaults: UserDefaults? {
        AppGroupConstants.iPhoneWidgetDefaults()
    }

    // MARK: - Properties

    /// Whether the app icon automatically changes based on service urgency.
    /// When disabled, the default icon is always used.
    var autoChangeEnabled: Bool {
        didSet {
            guard autoChangeEnabled != oldValue else { return }
            persist(autoChangeEnabled)
        }
    }

    // MARK: - Initialization

    private init() {
        self.autoChangeEnabled = Self.standardDefaults.bool(forKey: Self.autoChangeIconKey)
    }

    // MARK: - Persistence

    private func persist(_ enabled: Bool) {
        Self.standardDefaults.set(enabled, forKey: Self.autoChangeIconKey)
        Self.sharedDefaults?.set(enabled, forKey: Self.autoChangeIconKey)
    }

    // MARK: - Default Registration

    /// Register default values for UserDefaults.
    /// Call this in app initialization, before `shared` is first read.
    ///
    /// Off by default: every icon switch makes iOS show a "You have changed the
    /// icon" alert the user never asked for — at launch, mid-tour, or over the
    /// test host. Users who installed before this default changed (onboarding
    /// already complete, preference never touched) keep the behavior they had,
    /// pinned once so it doesn't flip when a new user finishes onboarding.
    static func registerDefaults() {
        let explicitlySet = standardDefaults.persistentDomain(
            forName: Bundle.main.bundleIdentifier ?? ""
        )?[autoChangeIconKey] != nil
        if !explicitlySet && OnboardingState.hasCompletedOnboarding {
            standardDefaults.set(true, forKey: autoChangeIconKey)
            sharedDefaults?.set(true, forKey: autoChangeIconKey)
        }
        standardDefaults.register(defaults: [autoChangeIconKey: false])
        sharedDefaults?.register(defaults: [autoChangeIconKey: false])
    }
}
