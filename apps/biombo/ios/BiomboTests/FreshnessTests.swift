@testable import Biombo
import Foundation
import Testing

@Suite("Freshness gating")
struct FreshnessTests {
    let policy = FreshnessPolicy()
    let now = SampleData.now

    private func report(
        _ kind: ReportKind,
        minutesAgo: Double,
        confirmedMinutesAgo: Double? = nil,
        source: Source = .community,
        statedEnd: Date? = nil
    ) -> Report {
        Report(
            kind: kind,
            placeID: "test.place",
            capturedAt: now.addingTimeInterval(-.minutes(minutesAgo)),
            lastConfirmedAt: confirmedMinutesAgo.map { now.addingTimeInterval(-.minutes($0)) },
            source: source,
            statedEnd: statedEnd
        )
    }

    private func area(
        lifecycle: OutageArea.Lifecycle = .confirmed,
        openedHoursAgo: Double,
        evidenceHoursAgo: Double
    ) -> OutageArea {
        OutageArea(
            id: "test.area", layer: .power, municipio: "Caguas", barrios: [], region: .central, polygon: [],
            lifecycle: lifecycle, evidence: .init(distinctDevices: 6, disputeShare: 0),
            openedAt: now.addingTimeInterval(-.hours(openedHoursAgo)),
            latestEvidenceAt: now.addingTimeInterval(-.hours(evidenceHoursAgo))
        )
    }

    // MARK: - Generic decay

    @Test("Fresh, then aging at half the window, then stale, then expired past the horizon")
    func decayStages() {
        let window = TimeInterval.hours(4)
        func at(_ age: TimeInterval) -> Freshness {
            policy.evaluate(anchor: now.addingTimeInterval(-age), window: window, now: now)
        }
        #expect(at(0) == .fresh)
        #expect(at(.hours(1.99)) == .fresh)
        #expect(at(.hours(2)) == .aging)
        #expect(at(.hours(4)) == .stale)
        #expect(at(.hours(4) + policy.showOlderHorizon - 1) == .stale)
        #expect(at(.hours(4) + policy.showOlderHorizon) == .expired)
    }

    @Test("Only fresh and aging items are current; only stale ones are revealable")
    func gating() {
        #expect(Freshness.fresh.isCurrent && Freshness.aging.isCurrent)
        #expect(!Freshness.stale.isCurrent && !Freshness.expired.isCurrent)
        #expect(Freshness.stale.isRevealableOnly)
        #expect(!Freshness.expired.isRevealableOnly && !Freshness.fresh.isRevealableOnly)
    }

    @Test("A report from the future is fresh, not negative-aged")
    func futureCapture() {
        #expect(policy.evaluate(report(.price, minutesAgo: -5), now: now) == .fresh)
    }

    // MARK: - Per-kind windows

    struct WindowCase: Sendable, CustomTestStringConvertible {
        let kind: ReportKind
        let minutesAgo: Double
        let expected: Freshness

        var testDescription: String { "\(kind) at \(Int(minutesAgo)) min → \(expected)" }
    }

    static let windowCases: [WindowCase] = [
        WindowCase(kind: .queue, minutesAgo: 20, expected: .fresh),
        WindowCase(kind: .queue, minutesAgo: 30, expected: .aging),
        WindowCase(kind: .queue, minutesAgo: 50, expected: .stale),
        WindowCase(kind: .price, minutesAgo: 47 * 60, expected: .aging),
        WindowCase(kind: .price, minutesAgo: 49 * 60, expected: .stale),
        WindowCase(kind: .flooded, minutesAgo: 3 * 60, expected: .stale),
        WindowCase(kind: .connectorDamaged, minutesAgo: 48 * 60, expected: .aging),
        WindowCase(kind: .chargerBusy, minutesAgo: 31, expected: .stale),
    ]

    @Test("Each kind decays on its own window", arguments: windowCases)
    func perKindWindows(_ testCase: WindowCase) {
        #expect(policy.evaluate(report(testCase.kind, minutesAgo: testCase.minutesAgo), now: now) == testCase.expected)
    }

    @Test("Sigue igual restarts the clock")
    func confirmationResetsClock() {
        let old = report(.hasGas, minutesAgo: 3 * 60)
        let reconfirmed = report(.hasGas, minutesAgo: 3 * 60, confirmedMinutesAgo: 10)
        #expect(policy.evaluate(old, now: now) == .stale)
        #expect(policy.evaluate(reconfirmed, now: now) == .fresh)
    }

    @Test("An unconfirmed outage report decays like any point report")
    func unconfirmedOutageReportDecays() {
        #expect(policy.evaluate(report(.noPower, minutesAgo: 5 * 60), now: now) == .stale)
    }

    // MARK: - Owner and official

    @Test("An owner post lasts until its stated end")
    func ownerStatedEnd() {
        let end = now.addingTimeInterval(.hours(1))
        #expect(policy.evaluate(report(.businessOnGenerator, minutesAgo: 60, source: .owner, statedEnd: end), now: now).isCurrent)
        let ended = now.addingTimeInterval(-.minutes(1))
        #expect(policy.evaluate(report(.businessOnGenerator, minutesAgo: 60, source: .owner, statedEnd: ended), now: now) == .stale)
    }

    @Test("An owner post without an end lasts 12 hours, not the community 4")
    func ownerDefaultWindow() {
        #expect(policy.evaluate(report(.businessOpen, minutesAgo: 5 * 60, source: .owner), now: now).isCurrent)
        #expect(policy.evaluate(report(.businessOpen, minutesAgo: 5 * 60), now: now) == .stale)
        #expect(policy.evaluate(report(.businessOpen, minutesAgo: 13 * 60, source: .owner), now: now) == .stale)
    }

    @Test("Official items never go stale by age; a late feed only turns them aging")
    func officialDoesNotDecay() {
        #expect(policy.evaluate(report(.closed, minutesAgo: 30, source: .official(.dtop)), now: now) == .fresh)
        #expect(policy.evaluate(report(.closed, minutesAgo: 10 * 24 * 60, source: .official(.dtop)), now: now) == .aging)
        let handEntry = now.addingTimeInterval(-.hours(71))
        #expect(policy.evaluateOfficial(updatedAt: handEntry, isFeed: false, now: now) == .fresh)
        #expect(policy.evaluateOfficial(updatedAt: handEntry, isFeed: true, now: now) == .aging)
    }

    // MARK: - Outage areas are states

    @Test("A confirmed area stays drawn past its window, with the age promoted")
    func confirmedAreaAgesButStays() {
        let confirmed = VerificationLabel.communityConfirmed(neighbours: 6)
        #expect(policy.evaluate(area(openedHoursAgo: 3, evidenceHoursAgo: 1), label: confirmed, isCrisis: false, now: now) == .fresh)
        #expect(policy.evaluate(area(openedHoursAgo: 12, evidenceHoursAgo: 9), label: confirmed, isCrisis: false, now: now) == .aging)
    }

    @Test("Reaching the ceiling moves the area behind older reports; crisis extends it")
    func outageCeiling() {
        let official = VerificationLabel.official(.luma)
        let old = area(openedHoursAgo: 73, evidenceHoursAgo: 20)
        #expect(policy.evaluate(old, label: official, isCrisis: false, now: now) == .stale)
        #expect(policy.evaluate(old, label: official, isCrisis: true, now: now) == .aging)
        let ancient = area(openedHoursAgo: 72 + 24 * 8, evidenceHoursAgo: 100)
        #expect(policy.evaluate(ancient, label: official, isCrisis: false, now: now) == .expired)
    }

    @Test("An unverified area decays like its reports")
    func unverifiedAreaDecays() {
        let stale = area(lifecycle: .open, openedHoursAgo: 6, evidenceHoursAgo: 5)
        #expect(policy.evaluate(stale, label: .unverified, isCrisis: false, now: now) == .stale)
    }

    @Test("A closed area is history, never current")
    func closedArea() {
        let closed = area(lifecycle: .closed, openedHoursAgo: 5, evidenceHoursAgo: 1)
        #expect(policy.evaluate(closed, label: .official(.luma), isCrisis: false, now: now) == .stale)
    }
}
