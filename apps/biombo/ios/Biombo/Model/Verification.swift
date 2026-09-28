import Foundation

/// Exactly one label per item, always shown as a symbol plus a word (PRODUCT.md §4.5).
/// "Disputed" is a state (`DisputeState`), not a fifth label.
nonisolated enum VerificationLabel: Codable, Hashable, Sendable {
    case official(Agency)
    case verifiedOwner
    /// "Confirmado por la comunidad"; the neighbour count shows in detail only.
    case communityConfirmed(neighbours: Int)
    case unverified

    /// Labels that keep an outage area open past its window (§4.4).
    var holdsOutageOpen: Bool {
        switch self {
        case .official, .communityConfirmed: true
        case .verifiedOwner, .unverified: false
        }
    }

    /// Only confirmed state changes notify; Sin verificar never pushes (§9).
    var canNotify: Bool { self != .unverified }

    /// Which report states an answer: owner first on an owned place, then
    /// official, then confirmed, then unverified (§4.5).
    var leadRank: Int {
        switch self {
        case .verifiedOwner: 3
        case .official: 2
        case .communityConfirmed: 1
        case .unverified: 0
        }
    }
}

/// Where a report stands after Sigue igual / Ya no votes (§4.3).
nonisolated enum DisputeState: String, Codable, Hashable, Sendable {
    case none
    /// Stays visible with the dispute promoted as the news.
    case disputed
    /// Resolved against: hidden from the answer.
    case resolved
}

/// The confirmation and dispute thresholds. All *proposed* (§4.3, §4.5, §7).
nonisolated struct VerificationRules: Sendable {
    var confirmWeight: Double = 2.0
    var highHarmConfirmWeight: Double = 3.0
    var disputeShare: Double = 0.3
    var disputeMinVotes: Int = 2
    var resolveMinVotes: Int = 3
    /// Neighbours' "no hay" that turn an owner's "hay" into disputed news (§6.5).
    var ownerContradictions: Int = 3

    /// The label a report carries. `placeHasVerifiedOwner` guards the owner
    /// label: an owner speaks only about their own place.
    func label(for report: Report, placeHasVerifiedOwner: Bool) -> VerificationLabel {
        switch report.source {
        case .official(let agency):
            return .official(agency)
        case .owner:
            return placeHasVerifiedOwner ? .verifiedOwner : .unverified
        case .community:
            let needed = report.kind.isHighHarmNegative ? highHarmConfirmWeight : confirmWeight
            return report.votes.confirmWeight >= needed
                ? .communityConfirmed(neighbours: Self.confirmingNeighbours(report.votes))
                : .unverified
        }
    }

    /// "Confirmado por N vecinos": everyone who said Sigue igual, you
    /// included, and not the author. The one count every surface states.
    static func confirmingNeighbours(_ votes: Votes) -> Int {
        votes.confirmCount
    }

    /// Official items are never voted on, so they are never disputed here;
    /// a contradiction shows both and flags the agency instead.
    func disputeState(for report: Report) -> DisputeState {
        guard report.source.agency == nil else { return .none }
        let votes = report.votes
        if votes.total >= resolveMinVotes, votes.disputeWeight > votes.confirmWeight {
            return .resolved
        }
        let totalWeight = votes.confirmWeight + votes.disputeWeight
        if votes.total >= disputeMinVotes, totalWeight > 0, votes.disputeWeight / totalWeight >= disputeShare {
            return .disputed
        }
        return .none
    }

    /// Polygon confidence; `nil` below 3 distinct devices, when nothing is drawn (§7).
    func confidence(for area: OutageArea) -> AreaConfidence? {
        let evidence = area.evidence
        if evidence.matchesOfficial { return .high }
        return confidence(devices: evidence.distinctDevices, disputeShare: evidence.disputeShare, insideOfficialHazard: evidence.insideOfficialHazard)
    }

    /// The part past an official outline stands on neighbours alone (§7 reconciliation 5).
    func confidence(for extension: OutageArea.CommunityExtension) -> AreaConfidence? {
        confidence(devices: `extension`.distinctDevices, disputeShare: 0, insideOfficialHazard: false)
    }

    private func confidence(devices: Int, disputeShare: Double, insideOfficialHazard: Bool) -> AreaConfidence? {
        guard devices >= 3 else { return nil }
        if devices >= 10, disputeShare < 0.2 { return .high }
        if devices >= 5 || insideOfficialHazard { return .medium }
        return .low
    }

    /// Any official part makes the area Oficial; Media or Alta is Confirmado; Baja is Sin verificar.
    func label(for area: OutageArea) -> VerificationLabel? {
        if let agency = area.officialAgency { return .official(agency) }
        switch confidence(for: area) {
        case .high, .medium: return .communityConfirmed(neighbours: area.evidence.distinctDevices)
        case .low: return .unverified
        case nil: return nil
        }
    }
}
