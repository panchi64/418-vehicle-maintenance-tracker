@testable import Biombo
import Foundation
import Testing

@Suite("Verification labels")
struct VerificationLabelTests {
    let rules = VerificationRules()

    private func report(_ kind: ReportKind = .price, source: Source = .community, votes: Votes = Votes()) -> Report {
        Report(kind: kind, placeID: "test.place", capturedAt: SampleData.now, source: source, votes: votes)
    }

    private func votes(confirm: Double, confirmCount: Int, dispute: Double = 0, disputeCount: Int = 0) -> Votes {
        Votes(confirmWeight: confirm, disputeWeight: dispute, confirmCount: confirmCount, disputeCount: disputeCount)
    }

    private func area(devices: Int, dispute: Double = 0, hazard: Bool = false, matches: Bool = false, agency: Agency? = nil) -> OutageArea {
        OutageArea(
            id: "test.area", layer: .power, municipio: "Caguas", barrios: [], region: .central, polygon: [],
            lifecycle: .open, officialAgency: agency,
            evidence: .init(distinctDevices: devices, disputeShare: dispute, insideOfficialHazard: hazard, matchesOfficial: matches),
            openedAt: SampleData.now, latestEvidenceAt: SampleData.now
        )
    }

    // MARK: - Report labels

    @Test("Official sources carry their agency, whatever the votes")
    func official() {
        #expect(rules.label(for: report(source: .official(.daco)), placeHasVerifiedOwner: false) == .official(.daco))
    }

    @Test("An owner label needs a verified owner of that place")
    func owner() {
        #expect(rules.label(for: report(.businessOpen, source: .owner), placeHasVerifiedOwner: true) == .verifiedOwner)
        #expect(rules.label(for: report(.businessOpen, source: .owner), placeHasVerifiedOwner: false) == .unverified)
    }

    @Test("Every new community report starts Sin verificar, even on an owned place")
    func newCommunityReport() {
        #expect(rules.label(for: report(), placeHasVerifiedOwner: true) == .unverified)
    }

    @Test("Community reports confirm at weight 2.0 from other people")
    func communityThreshold() {
        let almost = report(votes: votes(confirm: 1.9, confirmCount: 3))
        let enough = report(votes: votes(confirm: 2.0, confirmCount: 2))
        #expect(rules.label(for: almost, placeHasVerifiedOwner: false) == .unverified)
        #expect(rules.label(for: enough, placeHasVerifiedOwner: false) == .communityConfirmed(neighbours: 2))
    }

    @Test("High-harm negatives need weight 3.0", arguments: [
        ReportKind.noGas, .noDiesel, .businessClosed, .chargerBroken, .closed, .landslide,
    ])
    func highHarmThreshold(kind: ReportKind) {
        #expect(rules.label(for: report(kind, votes: votes(confirm: 2.5, confirmCount: 3)), placeHasVerifiedOwner: false) == .unverified)
        #expect(rules.label(for: report(kind, votes: votes(confirm: 3, confirmCount: 3)), placeHasVerifiedOwner: false) == .communityConfirmed(neighbours: 3))
    }

    // MARK: - Dispute state

    @Test("Disputed at ≥30% Ya no with ≥2 votes; the item stays visible")
    func disputed() {
        #expect(rules.disputeState(for: report(votes: votes(confirm: 2, confirmCount: 2, dispute: 1, disputeCount: 1))) == .disputed)
        #expect(rules.disputeState(for: report(votes: votes(confirm: 3, confirmCount: 3, dispute: 1, disputeCount: 1))) == .none)
    }

    @Test("One Ya no alone never disputes")
    func singleDispute() {
        #expect(rules.disputeState(for: report(votes: votes(confirm: 0, confirmCount: 0, dispute: 1, disputeCount: 1))) == .none)
    }

    @Test("Resolved when Ya no outweighs Sigue igual with ≥3 votes")
    func resolved() {
        #expect(rules.disputeState(for: report(votes: votes(confirm: 1, confirmCount: 1, dispute: 2, disputeCount: 2))) == .resolved)
        #expect(rules.disputeState(for: report(votes: votes(confirm: 0, confirmCount: 0, dispute: 2, disputeCount: 2))) == .disputed)
    }

    @Test("Official items are never voted into dispute")
    func officialNeverDisputed() {
        let contradicted = report(source: .official(.luma), votes: votes(confirm: 0, confirmCount: 0, dispute: 5, disputeCount: 5))
        #expect(rules.disputeState(for: contradicted) == .none)
    }

    // MARK: - Area confidence and labels

    @Test("Nothing is drawn below 3 devices")
    func belowThreshold() {
        #expect(rules.confidence(for: area(devices: 2)) == nil)
        #expect(rules.label(for: area(devices: 2)) == nil)
    }

    @Test("Baja is Sin verificar; Media and Alta are Confirmado")
    func areaLabels() {
        #expect(rules.confidence(for: area(devices: 3)) == .low)
        #expect(rules.label(for: area(devices: 4)) == .unverified)
        #expect(rules.confidence(for: area(devices: 5)) == .medium)
        #expect(rules.confidence(for: area(devices: 3, hazard: true)) == .medium)
        #expect(rules.label(for: area(devices: 5)) == .communityConfirmed(neighbours: 5))
        #expect(rules.confidence(for: area(devices: 10, dispute: 0.1)) == .high)
        #expect(rules.confidence(for: area(devices: 10, dispute: 0.25)) == .medium)
        #expect(rules.confidence(for: area(devices: 0, matches: true)) == .high)
    }

    @Test("Any official part makes the area Oficial")
    func officialArea() {
        #expect(rules.label(for: area(devices: 0, agency: .aaa)) == .official(.aaa))
    }

    @Test("Only Sin verificar is kept from notifying and from holding an outage open")
    func labelConsequences() {
        #expect(!VerificationLabel.unverified.canNotify)
        #expect(VerificationLabel.verifiedOwner.canNotify)
        #expect(VerificationLabel.official(.luma).holdsOutageOpen)
        #expect(VerificationLabel.communityConfirmed(neighbours: 3).holdsOutageOpen)
        #expect(!VerificationLabel.unverified.holdsOutageOpen)
    }
}
