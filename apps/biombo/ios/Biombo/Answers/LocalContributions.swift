import Foundation

/// What this device added to the island since the snapshot was cut: reports
/// sent, votes cast and places it verified as owner. Folded into the
/// snapshot so every answer, pin and row reads them under the same rules as
/// everyone else's (a new report is Sin verificar like any other). Pure.
nonisolated struct LocalContributions: Hashable, Sendable {
    /// Sent reports and owner posts, in the order they went out.
    var reports: [Report] = []
    var votes = VoteBook()
    /// Places this device holds as verified owner.
    var ownedPlaces: Set<Place.ID> = []
    /// This device's weight on a vote. Reputation is hidden and server-side
    /// (§5); sample data counts everyone at full weight.
    var voteWeight = 1.0

    var isEmpty: Bool { reports.isEmpty && votes.all.isEmpty && ownedPlaces.isEmpty }

    func applied(to snapshot: PlacesSnapshot) -> PlacesSnapshot {
        guard !isEmpty else { return snapshot }
        var copy = snapshot
        copy.places = copy.places.map { place in
            guard ownedPlaces.contains(place.id) else { return place }
            var place = place
            place.hasVerifiedOwner = true
            return place
        }
        let known = Set(copy.reports.map(\.id))
        copy.reports += reports.filter { !known.contains($0.id) }
        for vote in votes.all {
            guard case .report(let id) = vote.target else { continue }
            copy.reports = copy.reports.map { $0.id == id ? counted(vote.agrees, on: $0, at: vote.castAt) : $0 }
        }
        // A reversal is also a "Ya no" on the problem it reverses (§4.2).
        for reversal in reports {
            guard let reversed = reversal.kind.reverses,
                  let problem = copy.reports
                    .filter({ $0.placeID == reversal.placeID && $0.kind == reversed && $0.capturedAt <= reversal.capturedAt })
                    .max(by: { $0.capturedAt < $1.capturedAt }) else { continue }
            copy.reports = copy.reports.map { $0.id == problem.id ? counted(false, on: $0, at: reversal.capturedAt) : $0 }
        }
        return copy
    }

    /// Sigue igual adds confirming weight and restarts freshness; Ya no adds dispute weight (§4.3).
    private func counted(_ agrees: Bool, on report: Report, at date: Date) -> Report {
        var report = report
        if agrees {
            report.votes.confirmWeight += voteWeight
            report.votes.confirmCount += 1
            report.lastConfirmedAt = max(report.lastConfirmedAt ?? report.capturedAt, date)
        } else {
            report.votes.disputeWeight += voteWeight
            report.votes.disputeCount += 1
        }
        return report
    }
}
