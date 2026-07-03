//
//  WidgetAppGroup.swift
//  CheckpointWidget
//
//  Centralized access to the shared App Group UserDefaults for the widget
//  extension. Mirrors `AppGroupConstants.iPhoneWidgetDefaults()` in the
//  main app target so silent misconfiguration (missing entitlement, stale
//  state) is surfaced via a one-time warning on either side.
//

import Foundation
import os
import Synchronization

enum WidgetAppGroup {
    /// App Group shared between the main iPhone app and this widget extension.
    /// Must stay equal to `AppGroupConstants.iPhoneWidget` in the app target.
    static let identifier = "group.com.418-studio.checkpoint.shared"

    // MARK: - Shared UserDefaults keys
    //
    // Single source for these literals on the widget side. The app target mirrors
    // them in `AppGroupConstants`; keep the two in sync.

    /// Snapshot for the app's currently selected vehicle ("Match App" widgets).
    static let widgetDataKey = "widgetData"
    /// Prefix for per-vehicle snapshots ("widgetData_<uuid>").
    static let widgetDataKeyPrefix = "widgetData_"
    /// Lightweight vehicle list for the widget/Siri configuration picker.
    static let vehicleListKey = "vehicleList"
    /// The vehicle id the app currently has selected.
    static let appSelectedVehicleIDKey = "appSelectedVehicleID"
    /// Queue of service completions tapped from the widget "Done" button.
    static let pendingWidgetCompletionsKey = "pendingWidgetCompletions"

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
