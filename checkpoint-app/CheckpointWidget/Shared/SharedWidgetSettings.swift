//
//  SharedWidgetSettings.swift
//  CheckpointWidget
//
//  Lightweight reader for widget to access shared settings from App Group UserDefaults
//

import Foundation

/// Shared widget settings reader for the widget extension
/// Reads settings stored by the main app via WidgetSettingsManager
struct SharedWidgetSettings {
    // MARK: - Storage Keys (must match WidgetSettingsManager)

    private static let vehicleIDKey = "widgetDefaultVehicleID"
    private static let mileageDisplayModeKey = "widgetMileageDisplayMode"
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"

    // MARK: - Load Settings

    /// Load shared widget settings from App Group UserDefaults
    /// - Returns: Tuple with optional vehicleID and mileage display mode
    static func load() -> (vehicleID: String?, displayMode: MileageDisplayMode) {
        let defaults = UserDefaults(suiteName: appGroupID)

        let vehicleID = defaults?.string(forKey: vehicleIDKey)

        let modeRawValue = defaults?.string(forKey: mileageDisplayModeKey)
        let displayMode = modeRawValue.flatMap(MileageDisplayMode.init(rawValue:)) ?? .absolute

        return (vehicleID, displayMode)
    }
}
