//
//  SeasonalSettings.swift
//  checkpoint
//
//  Observable singleton for seasonal reminder preferences with UserDefaults sync
//

import Foundation

@Observable
@MainActor
final class SeasonalSettings {
    // MARK: - Singleton

    static let shared = SeasonalSettings()

    // MARK: - Storage Keys

    private static let isEnabledKey = "seasonalRemindersEnabled"
    private static let climateZoneKey = "seasonalClimateZone"
    private static let dismissedRemindersKey = "seasonalDismissedReminders"
    private static let suppressedRemindersKey = "seasonalSuppressedReminders"

    // MARK: - Properties

    /// Whether seasonal reminders are enabled
    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.isEnabledKey)
        }
    }

    /// User's selected climate zone (nil = not yet set)
    var climateZone: ClimateZone? {
        didSet {
            guard climateZone != oldValue else { return }
            if let zone = climateZone {
                UserDefaults.standard.set(zone.rawValue, forKey: Self.climateZoneKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.climateZoneKey)
            }
        }
    }

    /// Reminders dismissed for a specific year (keys like "winterTires-2026")
    private(set) var dismissedReminders: Set<String> {
        didSet {
            guard dismissedReminders != oldValue else { return }
            UserDefaults.standard.set(Array(dismissedReminders), forKey: Self.dismissedRemindersKey)
        }
    }

    /// Permanently suppressed reminder IDs
    private(set) var suppressedReminders: Set<String> {
        didSet {
            guard suppressedReminders != oldValue else { return }
            UserDefaults.standard.set(Array(suppressedReminders), forKey: Self.suppressedRemindersKey)
        }
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // isEnabled: default true
        if defaults.object(forKey: Self.isEnabledKey) != nil {
            self.isEnabled = defaults.bool(forKey: Self.isEnabledKey)
        } else {
            self.isEnabled = true
        }

        // climateZone: default nil
        if let rawValue = defaults.string(forKey: Self.climateZoneKey) {
            self.climateZone = ClimateZone(rawValue: rawValue)
        } else {
            self.climateZone = nil
        }

        // dismissedReminders
        if let stored = defaults.stringArray(forKey: Self.dismissedRemindersKey) {
            self.dismissedReminders = Set(stored)
        } else {
            self.dismissedReminders = []
        }

        // suppressedReminders
        if let stored = defaults.stringArray(forKey: Self.suppressedRemindersKey) {
            self.suppressedReminders = Set(stored)
        } else {
            self.suppressedReminders = []
        }
    }

    // MARK: - Default Registration

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            isEnabledKey: true
        ])
    }

    // MARK: - Reset (for testing)

    /// Resets all settings to defaults. Used by tests to ensure clean state.
    func reset() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.isEnabledKey)
        defaults.removeObject(forKey: Self.climateZoneKey)
        defaults.removeObject(forKey: Self.dismissedRemindersKey)
        defaults.removeObject(forKey: Self.suppressedRemindersKey)

        isEnabled = true
        climateZone = nil
        dismissedReminders = []
        suppressedReminders = []
    }

    // MARK: - Dismissal Methods

    /// Check if a reminder is dismissed for a given year
    func isDismissed(_ reminderID: String, year: Int) -> Bool {
        dismissedReminders.contains("\(reminderID)-\(year)")
    }

    /// Dismiss a reminder for the current year
    func dismissForYear(_ reminderID: String, year: Int) {
        dismissedReminders.insert("\(reminderID)-\(year)")
    }

    /// Check if a reminder is permanently suppressed
    func isSuppressed(_ reminderID: String) -> Bool {
        suppressedReminders.contains(reminderID)
    }

    /// Permanently suppress a reminder
    func suppressPermanently(_ reminderID: String) {
        suppressedReminders.insert(reminderID)
    }
}
