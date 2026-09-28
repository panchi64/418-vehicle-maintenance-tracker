@testable import Biombo
import Foundation
import Testing

@Suite("Contributions: votes, local reports folded into the snapshot, and progress")
struct ContributionTests {
    private let now = SampleData.now

    // MARK: - Votes

    @Test("One vote per item, changeable once, never on your own report")
    func voteBook() throws {
        var book = VoteBook()
        let target = MyVote.Target.report(SampleData.fixtureID(21))
        try book.cast(true, on: target, at: now, ownReports: [])
        try book.cast(true, on: target, at: now, ownReports: [])
        #expect(book.vote(on: target)?.hasChanged == false)
        try book.cast(false, on: target, at: now, ownReports: [])
        #expect(book.vote(on: target)?.agrees == false)
        #expect(throws: VoteBook.Refusal.alreadyChanged) { try book.cast(true, on: target, at: now, ownReports: []) }
        let mine = SampleData.fixtureID(900)
        #expect(throws: VoteBook.Refusal.ownReport) { try book.cast(true, on: .report(mine), at: now, ownReports: [mine]) }
        book.restore(nil, on: target)
        #expect(book.vote(on: target) == nil)
    }

    @Test("Deshacer puts back the vote that stood before, not nothing")
    func undoRestoresEarlierVote() throws {
        var book = VoteBook()
        let target = MyVote.Target.report(SampleData.fixtureID(21))
        #expect(try book.cast(false, on: target, at: now, ownReports: []) == nil)
        let first = try #require(book.vote(on: target))
        // Cambiar, then Deshacer: the first "Ya no" stands again, still changeable.
        let replaced = try book.cast(true, on: target, at: now, ownReports: [])
        #expect(replaced == first)
        book.restore(replaced, on: target)
        #expect(book.vote(on: target) == first)
        // A repeat of the same answer replaces it with itself, so Deshacer keeps it.
        let repeated = try book.cast(false, on: target, at: now, ownReports: [])
        book.restore(repeated, on: target)
        #expect(book.vote(on: target) == first)
    }

    @Test("Votes, history and the owner seal survive a relaunch")
    @MainActor
    func ledgerStorage() throws {
        let suite = "biombo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = DeviceStorage.contributions(defaults)
        let store = ContributionStore(history: SampleData.myReports, votes: SampleData.myVotes, ownedPlaces: SampleData.ownedPlaces)
        let target = MyVote.Target.report(SampleData.fixtureID(21))
        try store.vote(true, on: target, at: now)
        store.record(Report(kind: .noPower, placeID: SampleData.ID.puebloViejo, capturedAt: now), placeName: "Pueblo Viejo")
        storage.save(store.ledger)
        let relaunched = ContributionStore(try #require(storage.load()))
        #expect(relaunched.ledger == store.ledger)
        #expect(relaunched.votes.vote(on: target)?.agrees == true)
        #expect(relaunched.isOwner(of: try #require(SampleData.ownedPlaces.first?.key), now: now))
    }

    @Test("A standing vote shows on a later visit, with Cambiar while the change is left")
    func standing() {
        let vote = MyVote(target: .area("a"), agrees: true, castAt: now)
        #expect(ConfirmStep.shown(.asking, standing: vote, isRevising: false) == .standing(agrees: true, canChange: true))
        #expect(ConfirmStep.shown(.asking, standing: vote, isRevising: true) == .asking)
        #expect(ConfirmStep.shown(.answered(.same), standing: vote, isRevising: false) == .answered(.same))
        var changed = vote
        changed.hasChanged = true
        #expect(ConfirmStep.shown(.asking, standing: changed, isRevising: false) == .standing(agrees: true, canChange: false))
    }

    // MARK: - Folding into the snapshot

    @Test("A sent report joins the snapshot as Sin verificar, like anyone's; an outage waits for its area")
    func sentReport() throws {
        let snapshot = SampleData.snapshot()
        let hazard = Report(kind: .lineDown, placeID: SampleData.ID.puebloViejo, capturedAt: now)
        let outage = Report(kind: .noPower, placeID: SampleData.ID.puebloViejo, capturedAt: now)
        let applied = LocalContributions(reports: [hazard, outage]).applied(to: snapshot)
        #expect(applied.reports.count == snapshot.reports.count + 2)
        let place = try #require(applied.places.first { $0.id == SampleData.ID.puebloViejo })
        let answers = AnswerResolver().answers(for: place, reports: applied.reports, now: now)
        let answer = try #require(answers.first { $0.layer == .power })
        #expect(answer.kind == .lineDown)
        #expect(answer.label == .unverified)
        // One device's outage is not an area (§7): it shows once enough neighbours agree.
        #expect(!answers.contains { $0.kind == .noPower })
    }

    @Test("Sigue igual adds weight and restarts freshness; Ya no adds dispute weight")
    func votesFold() throws {
        let snapshot = SampleData.snapshot()
        let id = SampleData.fixtureID(21) // Bairoa, unverified, 35 minutes ago
        var votes = VoteBook()
        try votes.cast(true, on: .report(id), at: now, ownReports: [])
        let confirmed = try #require(LocalContributions(votes: votes).applied(to: snapshot).reports.first { $0.id == id })
        #expect(confirmed.votes.confirmCount == 1)
        #expect(confirmed.freshnessAnchor == now)
        votes = VoteBook()
        try votes.cast(false, on: .report(id), at: now, ownReports: [])
        let disputed = try #require(LocalContributions(votes: votes).applied(to: snapshot).reports.first { $0.id == id })
        #expect(disputed.votes.disputeCount == 1)
    }

    @Test("A reversal is also a Ya no on the problem it reverses")
    func reversal() throws {
        let snapshot = SampleData.snapshot()
        let back = Report(kind: .powerBack, placeID: SampleData.ID.bairoa, capturedAt: now)
        let applied = LocalContributions(reports: [back]).applied(to: snapshot)
        let latestOutage = try #require(applied.reports.first { $0.id == SampleData.fixtureID(21) })
        #expect(latestOutage.votes.disputeCount == 1)
    }

    @Test("A verified owner's place carries the seal, and an owner post becomes its answer")
    func ownership() throws {
        let snapshot = SampleData.snapshot()
        var draft = OwnerPostDraft(now: now)
        draft.status = .onGenerator
        let posts = draft.reports(for: SampleData.ID.farmaciaDelPueblo, now: now)
        let applied = LocalContributions(reports: posts, ownedPlaces: [SampleData.ID.farmaciaDelPueblo]).applied(to: snapshot)
        let place = try #require(applied.places.first { $0.id == SampleData.ID.farmaciaDelPueblo })
        #expect(place.hasVerifiedOwner)
        let answer = try #require(AnswerResolver().answers(for: place, reports: applied.reports, now: now).first)
        #expect(answer.label == .verifiedOwner)
        #expect(answer.kind == .businessOnGenerator)
    }

    // MARK: - Progress

    @Test("Points come from outcomes: +3 confirmed, +1 first of the day, −2 removed, votes +1")
    func ledger() {
        func mine(_ kind: ReportKind, daysAgo: Double, _ outcome: ReportOutcome) -> MyReport {
            MyReport(report: Report(kind: kind, placeID: "p", capturedAt: now.addingTimeInterval(-.days(daysAgo))), outcome: outcome, helped: 0, placeName: "p")
        }
        let ledger = ProgressLedger()
        #expect(ledger.progress(reports: [mine(.noPower, daysAgo: 1, .confirmed)], votes: []).points == 4)
        #expect(ledger.progress(reports: [mine(.flooded, daysAgo: 1, .confirmed)], votes: []).points == 3)
        #expect(ledger.progress(reports: [mine(.noPower, daysAgo: 1, .waiting), mine(.price, daysAgo: 1, .late)], votes: []).points == 0)
        let sameDay = (0..<6).map { _ in mine(.noPower, daysAgo: 1, .confirmed) }
        #expect(ledger.progress(reports: sameDay, votes: []).points == ProgressLedger.dailyCap)
        let vote = MyVote(target: .area("a"), agrees: true, castAt: now, matchedResolution: true)
        #expect(ledger.progress(reports: [], votes: [vote]).points == 1)
    }

    @Test("A level never goes down, even when points do")
    func levelFloor() {
        func mine(_ outcome: ReportOutcome, daysAgo: Double) -> MyReport {
            MyReport(report: Report(kind: .noPower, placeID: "p", capturedAt: now.addingTimeInterval(-.days(daysAgo))), outcome: outcome, helped: 0, placeName: "p")
        }
        let reports = [mine(.confirmed, daysAgo: 5), mine(.confirmed, daysAgo: 4), mine(.confirmed, daysAgo: 3), mine(.removed(.mismatch), daysAgo: 1)]
        let progress = ProgressLedger().progress(reports: reports, votes: [])
        #expect(progress.points == 10)
        #expect(progress.level == .two)
        let lower = ProgressLedger().progress(reports: reports + [mine(.resolvedAgainst, daysAgo: 0)], votes: [])
        #expect(lower.points == 8)
        #expect(lower.level == .two)
        #expect(lower.pointsToNextLevel == 32)
    }

    @Test("The sample device sits at level 3 with its best recent report as the highlight")
    func sampleSummary() throws {
        let summary = ContributionSummary(reports: SampleData.myReports, votes: SampleData.myVotes, now: now)
        #expect(summary.progress.level == .three)
        #expect(summary.progress.sentReports == SampleData.myReports.count)
        let highlight = try #require(summary.highlight)
        #expect(highlight.helped == 112)
        #expect(summary.recent.count == ContributionSummary.recentCap)
        #expect(!summary.recent.contains { $0.id == highlight.id })
        let others = SampleData.myReports.filter { $0.id != highlight.id }
        #expect(summary.recent.first?.report.capturedAt == others.map(\.report.capturedAt).max())
        #expect(summary.hasMore)
    }
}
