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
    /// Canonical value lives in `WidgetAppGroup`, which is compiled into both
    /// targets, so the two sides can never drift.
    nonisolated static let iPhoneWidget = WidgetAppGroup.identifier

    /// App Group shared between the Watch app and its widget extension.
    /// Must stay equal to `WatchDataStore.appGroupID` in the watch target.
    nonisolated static let watchApp = "group.com.418-studio.checkpoint.watch"

    // MARK: - Shared UserDefaults keys (iPhone↔widget)
    //
    // Aliased from `WidgetAppGroup` (compiled into both targets) so app and
    // widget always read the same definitions.

    /// Snapshot for the app's currently selected vehicle ("Match App" widgets).
    nonisolated static let widgetDataKey = WidgetAppGroup.widgetDataKey
    /// Prefix for per-vehicle snapshots ("widgetData_<uuid>").
    nonisolated static let widgetDataKeyPrefix = WidgetAppGroup.widgetDataKeyPrefix
    /// Lightweight vehicle list for the widget/Siri configuration picker.
    nonisolated static let vehicleListKey = WidgetAppGroup.vehicleListKey
    /// The vehicle id the app currently has selected (mirrors the "Match App" target).
    nonisolated static let appSelectedVehicleIDKey = WidgetAppGroup.appSelectedVehicleIDKey
    /// Queue of service completions tapped from the widget "Done" button.
    nonisolated static let pendingWidgetCompletionsKey = WidgetAppGroup.pendingWidgetCompletionsKey

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
