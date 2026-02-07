//
//  AnalyticsSettings.swift
//  checkpoint
//
//  Settings for analytics opt-in/opt-out preferences
//

import Foundation

/// Manages user preferences for analytics collection
@MainActor
final class AnalyticsSettings {
    static let shared = AnalyticsSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let analyticsEnabled = "analyticsEnabled"
    }

    // MARK: - Properties

    /// Whether analytics collection is enabled (default: true — opt-out model)
    var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.analyticsEnabled) }
        set { defaults.set(newValue, forKey: Keys.analyticsEnabled) }
    }

    private init() {}

    // MARK: - Registration

    /// Register default values for analytics settings
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.analyticsEnabled: true
        ])
    }
}
