//
//  DueSoonSettings.swift
//  checkpoint
//
//  Observable singleton for customizable "due soon" thresholds with UserDefaults sync
//

import Foundation

@Observable
@MainActor
final class DueSoonSettings {
    // MARK: - Singleton

    static let shared = DueSoonSettings()

    // MARK: - Storage Keys

    private static let mileageThresholdKey = "dueSoonMileageThreshold"
    private static let daysThresholdKey = "dueSoonDaysThreshold"

    // MARK: - Properties

    /// Mileage threshold for "due soon" status (default 750 miles)
    var mileageThreshold: Int {
        didSet {
            guard mileageThreshold != oldValue else { return }
            UserDefaults.standard.set(mileageThreshold, forKey: Self.mileageThresholdKey)
        }
    }

    /// Days threshold for "due soon" status (default 30 days)
    var daysThreshold: Int {
        didSet {
            guard daysThreshold != oldValue else { return }
            UserDefaults.standard.set(daysThreshold, forKey: Self.daysThresholdKey)
        }
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // Load from UserDefaults with defaults
        let storedMileage = defaults.integer(forKey: Self.mileageThresholdKey)
        self.mileageThreshold = storedMileage > 0 ? storedMileage : 750

        let storedDays = defaults.integer(forKey: Self.daysThresholdKey)
        self.daysThreshold = storedDays > 0 ? storedDays : 30
    }

    // MARK: - Default Registration

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            mileageThresholdKey: 750,
            daysThresholdKey: 30
        ])
    }

    // MARK: - Options

    /// Available mileage threshold options
    static let mileageOptions: [Int] = [500, 750, 1000, 1500]

    /// Available days threshold options
    static let daysOptions: [Int] = [14, 30, 45, 60]
}
