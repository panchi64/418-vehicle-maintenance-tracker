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
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"

    // MARK: - UserDefaults

    private static var standardDefaults: UserDefaults { .standard }
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
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
        // Check if the key has been explicitly set; default to true
        if Self.standardDefaults.object(forKey: Self.autoChangeIconKey) != nil {
            self.autoChangeEnabled = Self.standardDefaults.bool(forKey: Self.autoChangeIconKey)
        } else {
            self.autoChangeEnabled = true
        }
    }

    // MARK: - Persistence

    private func persist(_ enabled: Bool) {
        Self.standardDefaults.set(enabled, forKey: Self.autoChangeIconKey)
        Self.sharedDefaults?.set(enabled, forKey: Self.autoChangeIconKey)
    }

    // MARK: - Default Registration

    /// Register default values for UserDefaults.
    /// Call this in app initialization.
    static func registerDefaults() {
        standardDefaults.register(defaults: [
            autoChangeIconKey: true
        ])
        sharedDefaults?.register(defaults: [
            autoChangeIconKey: true
        ])
    }
}
