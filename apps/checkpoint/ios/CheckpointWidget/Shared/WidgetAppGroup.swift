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
    static let identifier = "group.com.418-studio.checkpoint.shared"

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
