import Foundation
import Observation

/// This device's contributions (PRODUCT.md §4.2, §4.3, §5, §10): the reports
/// it sent, its votes, the businesses it verified and any claim in review.
/// Pure state: sending, queueing, verifying and saving are the views', the
/// services' and the app's work; this only records what happened.
@Observable
final class ContributionStore {
    /// Every report this device made, newest outcomes included, for Tu aporte.
    private(set) var history: [MyReport]
    /// Reports sent since the snapshot was cut, folded into it until the
    /// next sync carries them (`LocalContributions`).
    private(set) var sent: [Report]
    private(set) var votes: VoteBook
    /// Places verified as owner, and until when (§5: 12 months).
    private(set) var ownedPlaces: [Place.ID: Date]
    /// Claims waiting for staff review.
    private(set) var claimsInReview: Set<Place.ID>
    private(set) var isSignedIn: Bool

    init(history: [MyReport] = [], votes: [MyVote] = [], ownedPlaces: [Place.ID: Date] = [:]) {
        self.history = history
        self.sent = []
        self.votes = VoteBook(votes)
        self.ownedPlaces = ownedPlaces
        self.claimsInReview = []
        self.isSignedIn = false
    }

    /// Picks up where the last launch left off.
    init(_ ledger: ContributionLedger) {
        history = ledger.history
        sent = ledger.sent
        votes = ledger.votes
        ownedPlaces = ledger.ownedPlaces
        claimsInReview = ledger.claimsInReview
        isSignedIn = ledger.isSignedIn
    }

    /// Everything the app saves, so a relaunch keeps votes, history and seals.
    var ledger: ContributionLedger {
        ContributionLedger(
            history: history, sent: sent, votes: votes, ownedPlaces: ownedPlaces,
            claimsInReview: claimsInReview, isSignedIn: isSignedIn
        )
    }

    var ownReportIDs: Set<Report.ID> { Set(history.map(\.id)) }

    func isOwner(of placeID: Place.ID, now: Date) -> Bool {
        ownedPlaces[placeID].map { $0 > now } ?? false
    }

    /// What the snapshot folds in. Only owner seals still valid at `now` count.
    func local(now: Date) -> LocalContributions {
        LocalContributions(
            reports: sent,
            votes: votes,
            ownedPlaces: Set(ownedPlaces.filter { $0.value > now }.keys)
        )
    }

    /// A snapshot as this device sees it: judged at the connection's clock,
    /// with what it sent and voted folded in.
    func shown(_ snapshot: PlacesSnapshot, at connection: ConnectionState) -> PlacesSnapshot {
        local(now: connection.now).applied(to: snapshot.aged(to: connection.now))
    }

    /// "Borrar mis datos" (§13): every report, vote, seal and claim this
    /// device kept is gone.
    func eraseAll() {
        history = []
        sent = []
        votes = VoteBook([])
        ownedPlaces = [:]
        claimsInReview = []
        isSignedIn = false
    }

    // MARK: - Reports

    /// A report went out: it joins the map and Tu aporte, where it waits for an outcome.
    func record(_ report: Report, placeName: String) {
        guard !sent.contains(where: { $0.id == report.id }) else { return }
        sent.append(report)
        history.append(MyReport(report: report, outcome: .waiting, helped: 0, placeName: placeName))
    }

    /// A report not on the map yet: made offline (it joins once the outbox
    /// replays it), or a price held for review (§6.1). Tu aporte lists it now.
    func recordUnpublished(_ report: Report, placeName: String) {
        guard !history.contains(where: { $0.id == report.id }) else { return }
        history.append(MyReport(report: report, outcome: .waiting, helped: 0, placeName: placeName))
    }

    /// The outbox replayed a queued report and it went on the map.
    func delivered(_ report: Report) {
        guard !sent.contains(where: { $0.id == report.id }) else { return }
        sent.append(report)
        if let index = history.firstIndex(where: { $0.id == report.id }) {
            history[index].report = report
        }
    }

    /// "Añadir detalle": the optional value, after the fact.
    func update(_ id: Report.ID, value: ReportValue?) {
        if let index = sent.firstIndex(where: { $0.id == id }) { sent[index].value = value }
        if let index = history.firstIndex(where: { $0.id == id }) { history[index].report.value = value }
    }

    /// Deshacer or Descartar: the report never happened.
    func undo(_ id: Report.ID) {
        sent.removeAll { $0.id == id }
        history.removeAll { $0.id == id }
    }

    // MARK: - Votes

    /// Sigue igual / Ya no. Throws when the rules refuse it (§4.3); returns
    /// the vote it replaced, for Deshacer.
    @discardableResult
    func vote(_ agrees: Bool, on target: MyVote.Target, at date: Date) throws(VoteBook.Refusal) -> MyVote? {
        try votes.cast(agrees, on: target, at: date, ownReports: ownReportIDs)
    }

    /// Deshacer: the vote that stood before comes back.
    func restoreVote(_ previous: MyVote?, on target: MyVote.Target) {
        votes.restore(previous, on: target)
    }

    // MARK: - Owners

    func signedIn() {
        isSignedIn = true
    }

    func verified(_ placeID: Place.ID, until: Date) {
        ownedPlaces[placeID] = until
        claimsInReview.remove(placeID)
    }

    func submittedClaim(_ placeID: Place.ID) {
        claimsInReview.insert(placeID)
    }

    /// Owner posts go out like any report, with the owner as source.
    func published(_ reports: [Report]) {
        sent += reports.filter { report in !sent.contains { $0.id == report.id } }
    }
}

/// What `ContributionStore` holds, as the app saves it on the device (§13:
/// nothing here leaves it).
nonisolated struct ContributionLedger: Codable, Hashable, Sendable {
    var history: [MyReport]
    var sent: [Report]
    var votes: VoteBook
    var ownedPlaces: [Place.ID: Date]
    var claimsInReview: Set<Place.ID>
    var isSignedIn: Bool
}
