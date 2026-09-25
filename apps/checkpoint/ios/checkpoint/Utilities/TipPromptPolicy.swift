//
//  TipPromptPolicy.swift
//  checkpoint
//
//  When the app may ask for a tip, as a pure function of stored counters, so
//  the rules are testable without UserDefaults or a clock.
//
//  The rules, all of which must hold:
//
//  1. Once per session at most.
//  2. Earned: the user has completed enough actions since the last prompt.
//     A completed action is recording or scheduling a service — something the
//     app did for them. Updating the odometer is upkeep the app asks of the
//     user, and counting it made the prompt follow a chore.
//     The threshold starts at 3 and grows by 3 per dismissal, capped at 15.
//  3. Spaced: at least 30 days since the last prompt, whatever its outcome,
//     and at least 30 days since the last tip.
//  4. Capped: a user who has never tipped is asked at most 3 times, ever.
//     Three "not now"s is an answer. Tippers are not capped by count — they
//     have said they welcome it — but rules 1–3 still apply.
//
//  The in-app Tip Jar (Settings) is always available; none of this gates it.
//

import Foundation

nonisolated struct TipPromptPolicy: Equatable, Sendable {
    static let tipCooldownDays = 30
    static let promptSpacingDays = 30
    static let maxPromptsWithoutTip = 3

    static let baseActionThreshold = 3
    static let dismissBackoffIncrement = 3
    static let maxActionThreshold = 15

    var completedActionCount: Int
    var dismissCount: Int
    var promptsShown: Int
    var hasTipped: Bool
    var lastTipDate: Date?
    var lastPromptDate: Date?
    var shownThisSession: Bool

    /// Actions required before the next prompt, growing with each dismissal.
    var actionThreshold: Int {
        min(
            Self.baseActionThreshold + dismissCount * Self.dismissBackoffIncrement,
            Self.maxActionThreshold
        )
    }

    func shouldShow(now: Date = .now) -> Bool {
        guard !shownThisSession else { return false }
        guard completedActionCount >= actionThreshold else { return false }
        guard hasTipped || promptsShown < Self.maxPromptsWithoutTip else { return false }
        guard Self.daysElapsed(since: lastPromptDate, to: now, atLeast: Self.promptSpacingDays) else { return false }
        guard Self.daysElapsed(since: lastTipDate, to: now, atLeast: Self.tipCooldownDays) else { return false }
        return true
    }

    private static func daysElapsed(since date: Date?, to now: Date, atLeast days: Int) -> Bool {
        guard let date else { return true }
        let elapsed = Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
        return elapsed >= days
    }
}
