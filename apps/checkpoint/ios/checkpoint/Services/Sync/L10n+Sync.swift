//
//  L10n+Sync.swift
//  checkpoint
//
//  iCloud sync status and error messages. Keys are prefixed `sync.`; the
//  Settings-row sync strings stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func sync(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static var syncErrorNotSignedIn: String { sync("sync.error.notSignedIn") }
    static var syncErrorQuotaExceeded: String { sync("sync.error.quotaExceeded") }
    static var syncErrorOffline: String { sync("sync.error.offline") }
    static var syncErrorGeneric: String { sync("sync.error.generic") }
    static var syncErrorUnknownStatus: String { sync("sync.error.unknownStatus") }
    static var syncActionOpenSettings: String { sync("sync.action.openSettings") }
    static var syncActionManageStorage: String { sync("sync.action.manageStorage") }
    static var syncStateSynced: String { sync("sync.state.synced") }
    static var syncStateSyncing: String { sync("sync.state.syncing") }
    static var syncStateSignIn: String { sync("sync.state.signIn") }
}
