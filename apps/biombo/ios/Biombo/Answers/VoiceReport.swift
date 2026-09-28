import Foundation

/// A report said to Siri (PRODUCT.md §11 `ReportConditionIntent`): what,
/// where and when, as the confirmation card shows it before anything is
/// sent. Where is the place of that kind nearest the point: where you stand,
/// or a saved place, since a background location fix is unverified (open
/// decision 16). Nothing of that kind in reach means no report.
nonisolated struct VoiceReport: Hashable, Sendable {
    let kind: ReportKind
    let target: ReportTarget
    /// Its client id, which the outbox and the server de-duplicate on.
    let id: UUID
    let capturedAt: Date

    static func make(
        _ kind: ReportKind,
        at point: GeoPoint,
        snapshot: PlacesSnapshot,
        areas: [AreaStatus],
        id: UUID = UUID()
    ) -> VoiceReport? {
        let context = ReportContextBuilder(snapshot: snapshot, areas: areas, vantage: point).context(for: .whereYouAre)
        guard let target = context.target(for: kind), target.isInReach else { return nil }
        return VoiceReport(kind: kind, target: target, id: id, capturedAt: snapshot.generatedAt)
    }

    /// The report that joins the outbox, marked as said to Siri.
    var report: Report {
        Report(id: id, kind: kind, placeID: target.place.id, capturedAt: capturedAt, channel: .siri)
    }

    /// The outbox entry: every voice report is persisted first and filed
    /// by the app like any other (§4.6).
    var queued: QueuedReport {
        QueuedReport(report, placeName: target.place.displayName)
    }
}
