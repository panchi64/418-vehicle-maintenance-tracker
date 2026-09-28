@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Trust suffix and ages")
struct TrustSuffixTests {
    let now = SampleData.now

    private func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-.minutes(minutes)) }

    @Test("Ages are relative under 24 h, then yesterday, then a date")
    func ages() {
        #expect(AgePhrase(since: ago(0.5), now: now) == .now)
        #expect(AgePhrase(since: ago(12), now: now) == .minutes(12))
        #expect(AgePhrase(since: ago(150), now: now) == .hours(2))
        // 30 h before Sunday 5:30 p.m. is Saturday morning.
        #expect(AgePhrase(since: ago(30 * 60), now: now) == .yesterday)
        let threeDays = ago(3 * 24 * 60)
        #expect(AgePhrase(since: threeDays, now: now) == .date(threeDays))
    }

    @Test("A fresh confirmed item is quiet and says when it was confirmed")
    func confirmedIsQuiet() {
        let suffix = TrustSuffix(label: .communityConfirmed(neighbours: 3), freshness: .fresh, dispute: .none, stamp: ago(12), now: now)
        #expect(suffix.phrase == .confirmed(.minutes(12)))
        #expect(suffix.tone == .quiet)
        #expect(!suffix.isPromoted)
    }

    @Test("Unverified and aging items are promoted as the news")
    func promoted() {
        let unverified = TrustSuffix(label: .unverified, freshness: .fresh, dispute: .none, stamp: ago(25), now: now)
        #expect(unverified.phrase == .unverified(.minutes(25)))
        #expect(unverified.tone == .news)

        let aging = TrustSuffix(label: .communityConfirmed(neighbours: 2), freshness: .aging, dispute: .none, stamp: ago(180), now: now)
        // Age is promoted in caution ink with a clock, never the label's own ink.
        #expect(aging.tone == .aging)
        #expect(aging.isPromoted)
        #expect(aging.ink == .statusCaution)
        #expect(aging.symbol == "clock")
    }

    @Test("A dispute replaces the label as the news")
    func disputed() {
        let suffix = TrustSuffix(label: .communityConfirmed(neighbours: 2), freshness: .fresh, dispute: .disputed, stamp: ago(20), now: now)
        #expect(suffix.phrase == .disputed(.minutes(20)))
        #expect(suffix.tone == .news)
    }

    @Test("Official items state their agency and clock time today, and the day before today")
    func official() {
        let stamp = ago(90)
        let suffix = TrustSuffix(label: .official(.luma), freshness: .fresh, dispute: .none, stamp: stamp, now: now)
        #expect(suffix.phrase == .official(.luma, .today(stamp)))
        #expect(suffix.tone == .quiet)

        let lastNight = TrustSuffix(label: .official(.aaa), freshness: .fresh, dispute: .none, stamp: ago(20 * 60), now: now)
        #expect(lastNight.phrase == .official(.aaa, .earlier(.hours(20))))
    }

    @Test("Stale items lead with their age")
    func stale() {
        let suffix = TrustSuffix(label: .unverified, freshness: .stale, dispute: .none, stamp: ago(30 * 60), now: now)
        #expect(suffix.phrase == .stale(.yesterday))
        #expect(suffix.tone == .stale)
        #expect(suffix.isPromoted)
    }
}
