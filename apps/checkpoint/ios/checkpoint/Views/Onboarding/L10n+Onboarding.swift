//
//  L10n+Onboarding.swift
//  checkpoint
//
//  Strings added for the shortened onboarding and the in-context reminders
//  ask. Keys are prefixed `onboarding.`; the older onboarding accessors stay
//  in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func onboarding(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Get started

    static var onboardingGetStartedBody: String { onboarding("onboarding.getstarted.body") }

    // MARK: - Reminders pre-prompt

    static var onboardingRemindersTitle: String { onboarding("onboarding.reminders.title") }
    static var onboardingRemindersMessage: String { onboarding("onboarding.reminders.message") }
    static var onboardingRemindersAllow: String { onboarding("onboarding.reminders.allow") }
    static var onboardingRemindersNotNow: String { onboarding("onboarding.reminders.notNow") }
}
