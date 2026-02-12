//
//  DistanceSettings.swift
//  checkpoint
//
//  Observable singleton for distance unit preference with UserDefaults sync
//  Supports App Group for widget access
//

import Foundation
import WidgetKit

@Observable
@MainActor
final class DistanceSettings {
    // MARK: - Singleton

    static let shared = DistanceSettings()

    // MARK: - Storage Keys

    private static let unitKey = "distanceUnit"
    // MARK: - UserDefaults

    private static var standardDefaults: UserDefaults { .standard }
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
    }

    // MARK: - Properties

    /// Current distance unit preference
    /// Changes are automatically persisted to UserDefaults and App Group
    var unit: DistanceUnit {
        didSet {
            guard unit != oldValue else { return }
            persist(unit)
        }
    }

    // MARK: - Initialization

    private init() {
        // Load from UserDefaults, defaulting to miles
        let rawValue = Self.standardDefaults.string(forKey: Self.unitKey)
        self.unit = rawValue.flatMap(DistanceUnit.init(rawValue:)) ?? .miles
    }

    // MARK: - Persistence

    private func persist(_ unit: DistanceUnit) {
        // Save to standard UserDefaults
        Self.standardDefaults.set(unit.rawValue, forKey: Self.unitKey)

        // Sync to App Group for widget access
        Self.sharedDefaults?.set(unit.rawValue, forKey: Self.unitKey)

        // Reload widgets so "Match App" distance unit picks up the change immediately
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget Access (Non-reactive)

    /// Read distance unit for widget (non-reactive, synchronous)
    /// Use this in WidgetKit timeline providers
    static func widgetUnit() -> DistanceUnit {
        let rawValue = sharedDefaults?.string(forKey: unitKey)
            ?? standardDefaults.string(forKey: unitKey)
        return rawValue.flatMap(DistanceUnit.init(rawValue:)) ?? .miles
    }

    // MARK: - Default Registration

    /// Register default values for UserDefaults
    /// Call this in app initialization
    static func registerDefaults() {
        standardDefaults.register(defaults: [
            unitKey: DistanceUnit.miles.rawValue
        ])
        sharedDefaults?.register(defaults: [
            unitKey: DistanceUnit.miles.rawValue
        ])
    }
}
