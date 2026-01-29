//
//  SyncSettings.swift
//  checkpoint
//
//  Settings for iCloud sync preferences
//

import Foundation

/// Manages user preferences for iCloud sync
@MainActor
final class SyncSettings {
    static let shared = SyncSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let migrationCompleted = "iCloudMigrationCompleted"
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Properties

    /// Whether iCloud sync is enabled (default: true for new users)
    var iCloudSyncEnabled: Bool {
        get { defaults.bool(forKey: Keys.iCloudSyncEnabled) }
        set { defaults.set(newValue, forKey: Keys.iCloudSyncEnabled) }
    }

    /// Whether data migration from local store to CloudKit has been completed
    var migrationCompleted: Bool {
        get { defaults.bool(forKey: Keys.migrationCompleted) }
        set { defaults.set(newValue, forKey: Keys.migrationCompleted) }
    }

    /// Last successful sync date
    var lastSyncDate: Date? {
        get { defaults.object(forKey: Keys.lastSyncDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastSyncDate) }
    }

    private init() {}

    // MARK: - Registration

    /// Register default values for sync settings
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.iCloudSyncEnabled: true,  // Enabled by default for new users
            Keys.migrationCompleted: false
        ])
    }
}
