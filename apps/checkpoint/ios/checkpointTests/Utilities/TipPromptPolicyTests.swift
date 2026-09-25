//
//  TipPromptPolicyTests.swift
//  checkpointTests
//
//  The tip prompt must be earned, spaced, and capped.
//

import XCTest
@testable import checkpoint

final class TipPromptPolicyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: now)!
    }

    private func policy(
        actions: Int = 3,
        dismisses: Int = 0,
        shown: Int = 0,
        hasTipped: Bool = false,
        lastTip: Date? = nil,
        lastPrompt: Date? = nil,
        thisSession: Bool = false
    ) -> TipPromptPolicy {
        TipPromptPolicy(
            completedActionCount: actions,
            dismissCount: dismisses,
            promptsShown: shown,
            hasTipped: hasTipped,
            lastTipDate: lastTip,
            lastPromptDate: lastPrompt,
            shownThisSession: thisSession
        )
    }

    func test_firstPrompt_afterBaseThreshold() {
        XCTAssertFalse(policy(actions: 2).shouldShow(now: now))
        XCTAssertTrue(policy(actions: 3).shouldShow(now: now))
    }

    func test_backoff_growsPerDismissAndCaps() {
        XCTAssertEqual(policy(dismisses: 0).actionThreshold, 3)
        XCTAssertEqual(policy(dismisses: 1).actionThreshold, 6)
        XCTAssertEqual(policy(dismisses: 2).actionThreshold, 9)
        XCTAssertEqual(policy(dismisses: 10).actionThreshold, TipPromptPolicy.maxActionThreshold)
        XCTAssertFalse(policy(actions: 5, dismisses: 1, shown: 1, lastPrompt: daysAgo(60)).shouldShow(now: now))
        XCTAssertTrue(policy(actions: 6, dismisses: 1, shown: 1, lastPrompt: daysAgo(60)).shouldShow(now: now))
    }

    func test_oncePerSession() {
        XCTAssertFalse(policy(thisSession: true).shouldShow(now: now))
    }

    func test_spacing_atLeastThirtyDaysBetweenPrompts() {
        XCTAssertFalse(policy(shown: 1, lastPrompt: daysAgo(29)).shouldShow(now: now))
        XCTAssertTrue(policy(shown: 1, lastPrompt: daysAgo(30)).shouldShow(now: now))
    }

    func test_cooldown_afterTip() {
        XCTAssertFalse(policy(hasTipped: true, lastTip: daysAgo(10)).shouldShow(now: now))
        XCTAssertTrue(policy(hasTipped: true, lastTip: daysAgo(31)).shouldShow(now: now))
    }

    func test_lifetimeCap_withoutTip() {
        XCTAssertTrue(policy(actions: 15, shown: 2, lastPrompt: daysAgo(90)).shouldShow(now: now))
        XCTAssertFalse(policy(actions: 15, shown: TipPromptPolicy.maxPromptsWithoutTip, lastPrompt: daysAgo(90)).shouldShow(now: now))
    }

    func test_lifetimeCap_liftedForTippers() {
        XCTAssertTrue(
            policy(actions: 15, shown: 5, hasTipped: true, lastTip: daysAgo(200), lastPrompt: daysAgo(90))
                .shouldShow(now: now)
        )
    }

    @MainActor
    func test_purchaseSettings_recordPromptShown_startsSpacingAndCounts() {
        let settings = PurchaseSettings.shared
        let defaults = UserDefaults.standard
        let keys = ["purchaseLastTipPromptDate", "purchaseTipPromptShownCount"]
        keys.forEach(defaults.removeObject(forKey:))
        defer {
            keys.forEach(defaults.removeObject(forKey:))
            settings.hasShownTipModalThisSession = false
        }

        settings.recordTipPromptShown(at: now)

        XCTAssertEqual(settings.tipPromptShownCount, 1)
        XCTAssertEqual(settings.lastTipPromptDate, now)
        XCTAssertTrue(settings.hasShownTipModalThisSession)
        XCTAssertEqual(settings.tipPromptPolicy.promptsShown, 1)
        XCTAssertEqual(settings.tipPromptPolicy.lastPromptDate, now)
    }
}
