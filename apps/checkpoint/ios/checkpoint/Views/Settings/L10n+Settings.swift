//
//  L10n+Settings.swift
//  checkpoint
//
//  Strings added for the Settings switchboard. Keys are prefixed
//  `settings.`; the older settings accessors stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func settings(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Notifications

    static var settingsNotifications: String { settings("settings.notifications") }
    static var settingsNotificationsAllowed: String { settings("settings.notifications.allowed") }
    static var settingsNotificationsOff: String { settings("settings.notifications.off") }
    static var settingsNotificationsNotAsked: String { settings("settings.notifications.notAsked") }
    static var settingsNotificationsOpenSettings: String { settings("settings.notifications.openSettings") }
    static var settingsNotificationsTurnOn: String { settings("settings.notifications.turnOn") }

    // MARK: - Sync

    static var syncTakesEffectNextLaunch: String { settings("settings.sync.nextLaunch") }

    // MARK: - Restore purchases

    static var settingsRestoreSuccess: String { settings("settings.restore.success") }
    static var settingsRestoreNothing: String { settings("settings.restore.nothing") }
    static var settingsRestoreFailed: String { settings("settings.restore.failed") }
}
