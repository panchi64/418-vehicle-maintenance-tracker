//
//  ClusteringSettings.swift
//  checkpoint
//
//  Observable singleton for service clustering preferences with UserDefaults sync
//

import Foundation

@Observable
@MainActor
final class ClusteringSettings {
    // MARK: - Singleton

    static let shared = ClusteringSettings()

    // MARK: - Storage Keys

    private static let mileageWindowKey = "clusteringMileageWindow"
    private static let daysWindowKey = "clusteringDaysWindow"
    private static let isEnabledKey = "clusteringEnabled"

    // MARK: - Properties

    /// Mileage window for clustering (default 1000 miles)
    var mileageWindow: Int {
        didSet {
            guard mileageWindow != oldValue else { return }
            UserDefaults.standard.set(mileageWindow, forKey: Self.mileageWindowKey)
        }
    }

    /// Days window for clustering (default 30 days)
    var daysWindow: Int {
        didSet {
            guard daysWindow != oldValue else { return }
            UserDefaults.standard.set(daysWindow, forKey: Self.daysWindowKey)
        }
    }

    /// Whether clustering is enabled
    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.isEnabledKey)
        }
    }

    /// Minimum services required to form a cluster
    let minimumClusterSize: Int = 2

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // Load from UserDefaults with defaults
        let storedMileage = defaults.integer(forKey: Self.mileageWindowKey)
        self.mileageWindow = storedMileage > 0 ? storedMileage : 1000

        let storedDays = defaults.integer(forKey: Self.daysWindowKey)
        self.daysWindow = storedDays > 0 ? storedDays : 30

        // For bool, need to check if key exists since false is default
        if defaults.object(forKey: Self.isEnabledKey) != nil {
            self.isEnabled = defaults.bool(forKey: Self.isEnabledKey)
        } else {
            self.isEnabled = true  // Default to enabled
        }
    }

    // MARK: - Default Registration

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            mileageWindowKey: 1000,
            daysWindowKey: 30,
            isEnabledKey: true
        ])
    }

    // MARK: - Convenience

    /// Available mileage window options
    static let mileageWindowOptions: [Int] = [500, 1000, 1500, 2000]

    /// Available days window options
    static let daysWindowOptions: [Int] = [14, 30, 45, 60]
}
