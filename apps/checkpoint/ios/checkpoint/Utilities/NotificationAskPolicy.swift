//
//  NotificationAskPolicy.swift
//  checkpoint
//
//  When the app may ask to send reminders, as a pure function of state, so
//  the timing is testable without the system prompt (the test host has no
//  notification authorization).
//
//  WHY IN CONTEXT. The system prompt used to fire twice with no context: when
//  onboarding completed, and again at every launch until answered. A user
//  who has nothing scheduled has no reason to say yes, and iOS lets an app
//  ask only once — a reflexive "Don't Allow" is permanent. So the app asks
//  once a service exists, with a one-line pre-prompt that says what the
//  reminders are for. Only "Allow" there triggers the system prompt; "Not
//  Now" costs nothing and the app may ask again later.
//
//  The rules, all of which must hold:
//
//  1. Never decided: iOS hasn't been asked yet. Anyone who already allowed
//     or refused is left alone (Settings shows the state and the way out).
//  2. Onboarding is over — nothing interrupts the tour or the hand-off.
//  3. There is something to be reminded about: at least one service.
//  4. Once per session, and not within 14 days of a "Not Now".
//

import Foundation
import UserNotifications

/// Where the user stands on notifications, in the words Settings shows.
nonisolated enum NotificationPermission: Equatable, Sendable {
    case allowed
    case off
    case notAsked

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notAsked
        case .denied: self = .off
        // .authorized, .provisional, .ephemeral, and anything future: the
        // app can deliver.
        default: self = .allowed
        }
    }
}

nonisolated struct NotificationAskPolicy: Equatable, Sendable {
    static let declineCooldownDays = 14

    var permission: NotificationPermission
    var hasCompletedOnboarding: Bool
    var serviceCount: Int
    var lastDeclinedAt: Date?
    var askedThisSession: Bool

    func shouldAsk(now: Date = .now) -> Bool {
        guard permission == .notAsked else { return false }
        guard hasCompletedOnboarding else { return false }
        guard serviceCount > 0 else { return false }
        guard !askedThisSession else { return false }
        if let lastDeclinedAt {
            let days = Calendar.current.dateComponents([.day], from: lastDeclinedAt, to: now).day ?? 0
            guard days >= Self.declineCooldownDays else { return false }
        }
        return true
    }
}

/// The pre-prompt's memory: when it was last declined (persisted) and
/// whether it has been shown this launch.
@MainActor
enum NotificationPrePromptStore {
    private static let declinedKey = "notificationPrePromptDeclinedAt"
    private(set) static var askedThisSession = false

    static var lastDeclinedAt: Date? {
        UserDefaults.standard.object(forKey: declinedKey) as? Date
    }

    static func recordShown() {
        askedThisSession = true
    }

    static func recordDeclined(now: Date = .now) {
        UserDefaults.standard.set(now, forKey: declinedKey)
    }
}
