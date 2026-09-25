//
//  L10n+Sync.swift
//  checkpoint
//
//  iCloud sync status and failure reasons. Keys are prefixed `sync.`; the
//  Settings-row sync strings stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func sync(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static var syncErrorQuotaExceeded: String { sync("sync.error.quotaExceeded") }
    static var syncErrorOffline: String { sync("sync.error.offline") }
    static var syncActionOpenSettings: String { sync("sync.action.openSettings") }
    static var syncStateSyncing: String { sync("sync.state.syncing") }
    static var syncStatusUnavailable: String { sync("sync.status.unavailable") }
    static var syncStatusFailed: String { sync("sync.status.failed") }
    static var syncStatusNeverSynced: String { sync("sync.status.neverSynced") }

    /// VoiceOver label for the status row: "iCloud sync, <status>".
    static func syncStatusAccessibility(_ status: String) -> String {
        String(format: sync("sync.status.a11y"), status)
    }

    /// VoiceOver label for a failure with a reason: "iCloud sync, <status>, <reason>".
    static func syncStatusAccessibility(_ status: String, reason: String) -> String {
        String(format: sync("sync.status.a11y.reason"), status, reason)
    }
}
