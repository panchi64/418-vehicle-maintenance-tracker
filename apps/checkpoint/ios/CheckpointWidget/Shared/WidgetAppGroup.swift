//
//  WidgetAppGroup.swift
//  CheckpointWidget
//
//  Canonical App Group identifier and shared UserDefaults keys for the
//  iPhone↔widget bridge. Compiled into BOTH the app and widget targets
//  (see the SharedEntities group), so `AppGroupConstants` in the app
//  aliases these values rather than duplicating the literals.
//

import Foundation
import os
import Synchronization

enum WidgetAppGroup {
    /// App Group shared between the main iPhone app and its widget extension.
    nonisolated static let identifier = "group.com.418-studio.checkpoint.shared"

    // MARK: - Shared UserDefaults keys
    //
    // Single source of truth for both targets; the app's `AppGroupConstants`
    // aliases these.

    /// Snapshot for the app's currently selected vehicle ("Match App" widgets).
    nonisolated static let widgetDataKey = "widgetData"
    /// Prefix for per-vehicle snapshots ("widgetData_<uuid>").
    nonisolated static let widgetDataKeyPrefix = "widgetData_"
    /// Lightweight vehicle list for the widget/Siri configuration picker.
    nonisolated static let vehicleListKey = "vehicleList"
    /// The vehicle id the app currently has selected.
    nonisolated static let appSelectedVehicleIDKey = "appSelectedVehicleID"
    /// Queue of service completions tapped from the widget "Done" button.
    nonisolated static let pendingWidgetCompletionsKey = "pendingWidgetCompletions"

    /// Shared defaults for the App Group. Logs a one-time warning per process
    /// when the suite is nil so silent misconfiguration doesn't masquerade as
    /// a working read/write.
    static func defaults() -> UserDefaults? {
        if let defaults = UserDefaults(suiteName: identifier) {
            return defaults
        }
        WidgetAppGroupWarning.emitOnce()
        return nil
    }
}

private enum WidgetAppGroupWarning {
    private static let warned = Mutex<Bool>(false)
    private static let logger = Logger(
        subsystem: "com.418-studio.checkpoint.widget",
        category: "AppGroup"
    )

    static func emitOnce() {
        let firstTime = warned.withLock { value in
            guard !value else { return false }
            value = true
            return true
        }
        guard firstTime else { return }
        logger.error(
            "UserDefaults(suiteName: \(WidgetAppGroup.identifier, privacy: .public)) returned nil — widget reads/writes will be dropped. Check the App Group entitlement."
        )
    }
}
