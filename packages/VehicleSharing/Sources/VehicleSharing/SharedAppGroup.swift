//
//  SharedAppGroup.swift
//  VehicleSharing
//
//  Cross-product App Group shared between Checkpoint and Biombo.
//

import Foundation
import os

/// Identifiers and accessors for the neutral cross-product App Group.
///
/// This is intentionally separate from Checkpoint's widget/Siri group
/// (`group.com.418-studio.checkpoint.shared`) so Biombo isn't coupled to a
/// "checkpoint"-named container. Both apps must declare this group in their
/// entitlements.
public enum SharedAppGroup {
    /// App Group shared between Checkpoint (writer) and Biombo (reader/updater).
    public static let identifier = "group.com.418-studio.shared"

    /// Shared defaults for the cross-product App Group, or `nil` when the
    /// entitlement isn't granted (e.g. test bundles, misconfigured signing).
    /// Logs a one-time warning per process so silent misconfiguration doesn't
    /// masquerade as a working write.
    public static func defaults() -> UserDefaults? {
        if let defaults = UserDefaults(suiteName: identifier) {
            return defaults
        }
        MissingSuiteWarning.emitOnce(for: identifier)
        return nil
    }

    /// Filesystem container URL for the App Group, or `nil` if entitlements
    /// don't grant access.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

private enum MissingSuiteWarning {
    nonisolated private static let warned = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    nonisolated static func emitOnce(for suite: String) {
        let firstTime = warned.withLock { $0.insert(suite).inserted }
        guard firstTime else { return }
        Logger(subsystem: "com.418-studio.shared", category: "AppGroup").error(
            "UserDefaults(suiteName: \(suite, privacy: .public)) returned nil — cross-app odometer sync will be dropped. Check the App Group entitlement."
        )
    }
}
