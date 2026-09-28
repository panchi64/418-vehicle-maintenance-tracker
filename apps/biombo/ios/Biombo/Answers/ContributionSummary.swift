import Foundation

/// What "Tu aporte" says (PRODUCT.md §10, Contribute-Progress): the report
/// that helped most lately, the level and what's next, three numbers, and
/// the newest reports (≤3 before "Ver todos"). Private to the device; there
/// is no comparison with anyone. Pure.
nonisolated struct ContributionSummary: Hashable, Sendable {
    let progress: Progress
    /// "Tu reporte ayudó a 38 personas": the most-seen report of the last week.
    let highlight: MyReport?
    /// Newest first.
    let reports: [MyReport]

    /// Reports shown before "Ver todos (N)" (§3 row caps).
    nonisolated static let recentCap = 3
    /// How far back the highlight looks (*proposed*).
    nonisolated static let highlightWindow: TimeInterval = .days(7)

    init(reports: [MyReport], votes: [MyVote], now: Date, ledger: ProgressLedger = ProgressLedger()) {
        progress = ledger.progress(reports: reports, votes: votes)
        self.reports = reports.sorted { $0.report.capturedAt > $1.report.capturedAt }
        highlight = reports
            .filter { now.timeIntervalSince($0.report.capturedAt) <= Self.highlightWindow && $0.helped > 0 }
            .max { ($0.helped, $0.report.capturedAt) < ($1.helped, $1.report.capturedAt) }
    }

    /// The newest reports under the highlight, which isn't repeated (§3:
    /// each fact once per screen).
    var recent: [MyReport] {
        Array(reports.filter { $0.id != highlight?.id }.prefix(Self.recentCap))
    }

    /// Reports "Ver todos" would add to what the screen already shows.
    var hasMore: Bool { reports.count > recent.count + (highlight == nil ? 0 : 1) }
}
