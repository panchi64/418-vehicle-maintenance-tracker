//
//  NotificationAskPolicyTests.swift
//  checkpointTests
//
//  When the reminders pre-prompt may appear. Pure — the test host has no
//  notification authorization, so nothing here touches the system prompt.
//

import XCTest
import UserNotifications
@testable import checkpoint

final class NotificationAskPolicyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func policy(
        permission: NotificationPermission = .notAsked,
        onboarded: Bool = true,
        services: Int = 1,
        declinedDaysAgo: Int? = nil,
        askedThisSession: Bool = false
    ) -> NotificationAskPolicy {
        NotificationAskPolicy(
            permission: permission,
            hasCompletedOnboarding: onboarded,
            serviceCount: services,
            lastDeclinedAt: declinedDaysAgo.map { now.addingTimeInterval(TimeInterval(-$0 * 86_400)) },
            askedThisSession: askedThisSession
        )
    }

    func test_shouldAsk_firstServiceExists_neverAsked_isTrue() {
        XCTAssertTrue(policy().shouldAsk(now: now))
    }

    func test_shouldAsk_noServicesYet_isFalse() {
        XCTAssertFalse(policy(services: 0).shouldAsk(now: now), "Nothing to remind about yet")
    }

    func test_shouldAsk_duringOnboarding_isFalse() {
        XCTAssertFalse(policy(onboarded: false).shouldAsk(now: now))
    }

    func test_shouldAsk_alreadyAllowed_isFalse() {
        XCTAssertFalse(policy(permission: .allowed).shouldAsk(now: now), "Users who granted are left alone")
    }

    func test_shouldAsk_turnedOff_isFalse() {
        XCTAssertFalse(policy(permission: .off).shouldAsk(now: now), "Only Settings can undo a refusal")
    }

    func test_shouldAsk_oncePerSession() {
        XCTAssertFalse(policy(askedThisSession: true).shouldAsk(now: now))
    }

    func test_shouldAsk_recentNotNow_waitsOutTheCooldown() {
        XCTAssertFalse(policy(declinedDaysAgo: 3).shouldAsk(now: now))
        XCTAssertTrue(policy(declinedDaysAgo: NotificationAskPolicy.declineCooldownDays).shouldAsk(now: now))
    }

    func test_permission_mapsSystemStatus() {
        XCTAssertEqual(NotificationPermission(.notDetermined), .notAsked)
        XCTAssertEqual(NotificationPermission(.denied), .off)
        XCTAssertEqual(NotificationPermission(.authorized), .allowed)
        XCTAssertEqual(NotificationPermission(.provisional), .allowed)
    }
}
