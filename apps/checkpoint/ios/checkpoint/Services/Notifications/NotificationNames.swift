//
//  NotificationNames.swift
//  checkpoint
//
//  Notification.Name extensions for app-wide events.
//
//  Notification *responses* don't go through here: they are stored as a
//  `NotificationRoute` so a cold launch can't drop them. See NotificationRoute.swift.
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    // Onboarding sync
    static let enableCloudSyncAfterOnboarding = Notification.Name("enableCloudSyncAfterOnboarding")
}
