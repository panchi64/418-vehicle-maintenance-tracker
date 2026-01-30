//
//  WidgetSettingsManager.swift
//  checkpoint
//
//  Observable singleton for widget settings preference with UserDefaults sync
//  Supports App Group for widget access
//

import Foundation
import WidgetKit

/// Mileage display mode for widgets
/// Matches the MileageDisplayMode in widget extension
enum WidgetMileageDisplayMode: String, CaseIterable {
    case absolute = "absolute"
    case relative = "relative"

    var displayName: String {
        switch self {
        case .absolute: return "Due Mileage"
        case .relative: return "Miles Remaining"
        }
    }

    var description: String {
        switch self {
        case .absolute: return "Show when service is due"
        case .relative: return "Show miles until due"
        }
    }
}

@Observable
@MainActor
final class WidgetSettingsManager {
    // MARK: - Singleton

    static let shared = WidgetSettingsManager()

    // MARK: - Storage Keys

    private static let vehicleIDKey = "widgetDefaultVehicleID"
    private static let mileageDisplayModeKey = "widgetMileageDisplayMode"
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"

    // MARK: - UserDefaults

    private static var standardDefaults: UserDefaults { .standard }
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Properties

    /// Default vehicle ID for widgets
    /// When nil, widgets will use the first available vehicle
    var defaultVehicleID: String? {
        didSet {
            guard defaultVehicleID != oldValue else { return }
            persistVehicleID(defaultVehicleID)
            reloadWidgets()
        }
    }

    /// Mileage display mode for widgets
    var mileageDisplayMode: WidgetMileageDisplayMode {
        didSet {
            guard mileageDisplayMode != oldValue else { return }
            persistMileageDisplayMode(mileageDisplayMode)
            reloadWidgets()
        }
    }

    // MARK: - Initialization

    private init() {
        // Load vehicle ID from UserDefaults
        self.defaultVehicleID = Self.standardDefaults.string(forKey: Self.vehicleIDKey)

        // Load mileage display mode from UserDefaults, defaulting to absolute
        let rawValue = Self.standardDefaults.string(forKey: Self.mileageDisplayModeKey)
        self.mileageDisplayMode = rawValue.flatMap(WidgetMileageDisplayMode.init(rawValue:)) ?? .absolute
    }

    // MARK: - Persistence

    private func persistVehicleID(_ vehicleID: String?) {
        if let vehicleID = vehicleID {
            Self.standardDefaults.set(vehicleID, forKey: Self.vehicleIDKey)
            Self.sharedDefaults?.set(vehicleID, forKey: Self.vehicleIDKey)
        } else {
            Self.standardDefaults.removeObject(forKey: Self.vehicleIDKey)
            Self.sharedDefaults?.removeObject(forKey: Self.vehicleIDKey)
        }
    }

    private func persistMileageDisplayMode(_ mode: WidgetMileageDisplayMode) {
        Self.standardDefaults.set(mode.rawValue, forKey: Self.mileageDisplayModeKey)
        Self.sharedDefaults?.set(mode.rawValue, forKey: Self.mileageDisplayModeKey)
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget Access (Non-reactive)

    /// Read default vehicle ID for widget (non-reactive, synchronous)
    /// Use this in WidgetKit timeline providers
    static func widgetVehicleID() -> String? {
        sharedDefaults?.string(forKey: vehicleIDKey)
            ?? standardDefaults.string(forKey: vehicleIDKey)
    }

    /// Read mileage display mode for widget (non-reactive, synchronous)
    /// Use this in WidgetKit timeline providers
    static func widgetMileageDisplayMode() -> WidgetMileageDisplayMode {
        let rawValue = sharedDefaults?.string(forKey: mileageDisplayModeKey)
            ?? standardDefaults.string(forKey: mileageDisplayModeKey)
        return rawValue.flatMap(WidgetMileageDisplayMode.init(rawValue:)) ?? .absolute
    }

    // MARK: - Default Registration

    /// Register default values for UserDefaults
    /// Call this in app initialization
    static func registerDefaults() {
        standardDefaults.register(defaults: [
            mileageDisplayModeKey: WidgetMileageDisplayMode.absolute.rawValue
        ])
        sharedDefaults?.register(defaults: [
            mileageDisplayModeKey: WidgetMileageDisplayMode.absolute.rawValue
        ])
    }
}
