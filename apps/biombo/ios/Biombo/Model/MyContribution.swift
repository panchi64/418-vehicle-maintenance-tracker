import Foundation

/// A report this device made, as Tu aporte lists it (PRODUCT.md §10). It
/// lives on the device only; nothing public links it to the reporter (§13).
nonisolated struct MyReport: Identifiable, Codable, Hashable, Sendable {
    var report: Report
    var outcome: ReportOutcome
    /// "Tu reporte ayudó a N personas": an estimate of the distinct devices
    /// that saw it as a place's answer while it was fresh. Feedback only.
    var helped: Int
    /// Where it was, as the user would say it ("PR-52, km 14").
    var placeName: String

    var id: Report.ID { report.id }
}

/// What became of a report (§5 "Review and removals", §10).
nonisolated enum ReportOutcome: Codable, Hashable, Sendable {
    /// Nobody has confirmed or disputed it yet.
    case waiting
    /// Others confirmed it, or it matched official data.
    case confirmed
    /// Votes or reversals went against it.
    case resolvedAgainst
    /// Taken down in review, with the reason from the fixed list.
    case removed(RemovalReason)
    /// It arrived after its window had passed, so it went to history only (§4.6).
    case late

    var isConfirmed: Bool { self == .confirmed }
}

/// The fixed list a reviewer picks from (§5).
nonisolated enum RemovalReason: String, CaseIterable, Codable, Hashable, Sendable {
    case mismatch
    case wrongPlace
    case duplicate
    case inappropriate
    case resolved
}

/// A Sigue igual / Ya no this device gave (§4.3). Keyed by what was voted
/// on: a report's id, or an outage area's.
nonisolated struct MyVote: Codable, Hashable, Sendable {
    nonisolated enum Target: Codable, Hashable, Sendable {
        case report(Report.ID)
        case area(OutageArea.ID)
    }

    let target: Target
    var agrees: Bool
    var castAt: Date
    /// A vote can be changed once (§4.3).
    var hasChanged = false
    /// Whether it matched how the item was finally resolved; nil until then.
    var matchedResolution: Bool?
}

/// One vote per reporter per item, changeable once, never on your own
/// report (§4.3). Pure: the store keeps the book, this decides.
nonisolated struct VoteBook: Codable, Hashable, Sendable {
    private(set) var votes: [MyVote.Target: MyVote] = [:]

    init(_ votes: [MyVote] = []) {
        self.votes = Dictionary(votes.map { ($0.target, $0) }) { _, latest in latest }
    }

    nonisolated enum Refusal: Error, Hashable, Sendable {
        case ownReport
        case alreadyChanged
    }

    func vote(on target: MyVote.Target) -> MyVote? { votes[target] }

    /// Records a vote, or changes the standing one once. A repeat of the
    /// same answer changes nothing. Returns the vote it replaced (nil when
    /// there was none), which Deshacer puts back.
    @discardableResult
    mutating func cast(_ agrees: Bool, on target: MyVote.Target, at date: Date, ownReports: Set<Report.ID>) throws(Refusal) -> MyVote? {
        if case .report(let id) = target, ownReports.contains(id) { throw .ownReport }
        guard var existing = votes[target] else {
            votes[target] = MyVote(target: target, agrees: agrees, castAt: date)
            return nil
        }
        let previous = existing
        guard existing.agrees != agrees else { return previous }
        guard !existing.hasChanged else { throw .alreadyChanged }
        existing.agrees = agrees
        existing.castAt = date
        existing.hasChanged = true
        votes[target] = existing
        return previous
    }

    /// Deshacer: the book goes back to the vote that stood before, or to
    /// none when there wasn't one.
    mutating func restore(_ previous: MyVote?, on target: MyVote.Target) {
        votes[target] = previous
    }

    var all: [MyVote] { Array(votes.values) }
}
