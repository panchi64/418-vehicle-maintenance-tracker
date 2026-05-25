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
    /// App Group shared between the main iPhone app and its widget extension
    nonisolated static let iPhoneWidget = "group.com.418-studio.checkpoint.shared"

    /// App Group shared between the Watch app and its widget extension
    nonisolated static let watchApp = "group.com.418-studio.checkpoint.watch"

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
    private static let warned = Mutex<Set<String>>([])

    nonisolated static func emitOnce(for suite: String) {
        let firstTime = warned.withLock { $0.insert(suite).inserted }
        guard firstTime else { return }
        Logger(category: "AppGroup").error(
            "UserDefaults(suiteName: \(suite, privacy: .public)) returned nil — widget/Siri writes will be dropped. Check the App Group entitlement."
        )
    }
}
