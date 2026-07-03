//
//  AppGroupConstants.swift
//  checkpoint
//
//  Centralized App Group identifiers to avoid hardcoded strings
//

import Foundation
import OSLog
import Synchronization

enum AppGroupConstants {
    /// App Group shared between the main iPhone app and its widget extension.
    /// Must stay equal to `WidgetAppGroup.identifier` in the widget target (they
    /// live in separate targets and can't reference each other directly).
    nonisolated static let iPhoneWidget = "group.com.418-studio.checkpoint.shared"

    /// App Group shared between the Watch app and its widget extension.
    /// Must stay equal to `WatchDataStore.appGroupID` in the watch target.
    nonisolated static let watchApp = "group.com.418-studio.checkpoint.watch"

    // MARK: - Shared UserDefaults keys (iPhone↔widget)
    //
    // Centralized here so the app side has a single source for these literals.
    // The widget target mirrors them in `WidgetAppGroup`; keep the two in sync.

    /// Snapshot for the app's currently selected vehicle ("Match App" widgets).
    nonisolated static let widgetDataKey = "widgetData"
    /// Prefix for per-vehicle snapshots ("widgetData_<uuid>").
    nonisolated static let widgetDataKeyPrefix = "widgetData_"
    /// Lightweight vehicle list for the widget/Siri configuration picker.
    nonisolated static let vehicleListKey = "vehicleList"
    /// The vehicle id the app currently has selected (mirrors the "Match App" target).
    nonisolated static let appSelectedVehicleIDKey = "appSelectedVehicleID"
    /// Queue of service completions tapped from the widget "Done" button.
    nonisolated static let pendingWidgetCompletionsKey = "pendingWidgetCompletions"

    /// Filesystem container URL for the iPhone↔widget App Group, or nil if entitlements
    /// don't grant access (e.g. test bundles).
    nonisolated static var iPhoneWidgetContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: iPhoneWidget)
    }

    /// Shared defaults for the iPhone↔widget App Group. Logs a one-time warning
    /// per process when the suite is nil so silent misconfiguration (missing
    /// entitlement, stale simulator state) doesn't masquerade as a working write.
    nonisolated static func iPhoneWidgetDefaults() -> UserDefaults? {
        if let defaults = UserDefaults(suiteName: iPhoneWidget) {
            return defaults
        }
        AppGroupDefaultsWarning.emitOnce(for: iPhoneWidget)
        return nil
    }
}

private enum AppGroupDefaultsWarning {
    nonisolated private static let warned = Mutex<Set<String>>([])

    nonisolated static func emitOnce(for suite: String) {
        let firstTime = warned.withLock { $0.insert(suite).inserted }
        guard firstTime else { return }
        Logger(category: "AppGroup").error(
            "UserDefaults(suiteName: \(suite, privacy: .public)) returned nil — widget/Siri writes will be dropped. Check the App Group entitlement."
        )
    }
}
