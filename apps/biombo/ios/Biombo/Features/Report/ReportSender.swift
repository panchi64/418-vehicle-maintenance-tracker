import Foundation

/// Sends one report through the right door (PRODUCT.md §4.2, §4.6): a repeat
/// within 15 minutes becomes a confirmation, offline goes to the outbox, a
/// price far outside DACO's range is held, and everything else goes on the
/// map. Returns the receipt the sent state shows. A replayed outbox goes
/// through the same doors. Composes the pure rules with the two stores that
/// record the outcome.
struct ReportSender {
    let contributions: ContributionStore
    let device: DeviceStore
    /// The snapshot on screen, with this device's contributions folded in.
    let snapshot: PlacesSnapshot
    /// The drawn outage areas, to tell a lone outage report from one inside an area.
    let areas: [AreaStatus]
    let connection: ConnectionState

    func send(_ kind: ReportKind, value: ReportValue? = nil, to target: ReportTarget, photo: Data? = nil) -> ReportReceipt {
        let report = Report(
            kind: kind, value: value, placeID: target.place.id, capturedAt: connection.now,
            channel: photo == nil ? .tap : .photo
        )
        let name = target.place.displayName
        if connection.queuesReports {
            device.enqueue(QueuedReport(report, placeName: name))
            contributions.recordUnpublished(report, placeName: name)
            return ReportReceipt(reportID: report.id, kind: kind, placeName: name, delivery: .queued, price: report.price)
        }
        switch ReportFiling.file(report, among: snapshot.reports, ownReports: contributions.ownReportIDs) {
        case .repeatOfYours(let yours):
            return ReportReceipt(reportID: yours.id, kind: kind, placeName: name, delivery: .alreadySaid)
        case .confirmation(let standing):
            let replaced: MyVote?
            do {
                replaced = try contributions.vote(true, on: .report(standing.id), at: connection.now)
            } catch {
                return ReportReceipt(reportID: standing.id, kind: kind, placeName: name, delivery: .alreadySaid)
            }
            let neighbours = Self.neighbours(confirming: standing, replacing: replaced)
            return ReportReceipt(reportID: standing.id, kind: kind, placeName: name, delivery: .confirmed(neighbours: neighbours), replacedVote: replaced)
        case .new(let report):
            if isHeld(report) {
                contributions.recordUnpublished(report, placeName: name)
                return ReportReceipt(reportID: report.id, kind: kind, placeName: name, delivery: .heldForReview)
            }
            contributions.record(report, placeName: name)
            let isCovered = areas.contains { $0.layer == kind.layer && target.place.anchor.isInside($0.area.polygon) }
            return ReportReceipt(
                reportID: report.id, kind: kind, placeName: name, delivery: .sent,
                isAloneForNow: kind.isOutageState && !isCovered, price: report.price
            )
        }
    }

    /// The network is back and the outbox let these go, oldest first. Each is
    /// filed as if sent now: a repeat of a neighbour's report becomes their
    /// confirmation, a repeat of yours is dropped, and an outlier price stays
    /// held. Tu aporte already lists them, so only the outcome changes.
    func replay(_ items: [QueuedReport]) {
        var reports = snapshot.reports
        for item in items {
            guard let report = item.report else { continue }
            switch ReportFiling.file(report, among: reports, ownReports: contributions.ownReportIDs) {
            case .repeatOfYours:
                contributions.undo(report.id)
            case .confirmation(let standing):
                contributions.undo(report.id)
                _ = try? contributions.vote(true, on: .report(standing.id), at: report.capturedAt)
            case .new(let report):
                guard !isHeld(report) else { continue }
                contributions.delivered(report)
                reports.append(report)
            }
        }
    }

    /// Deshacer, within the 5-second window.
    func undo(_ receipt: ReportReceipt) {
        switch receipt.delivery {
        case .confirmed:
            contributions.restoreVote(receipt.replacedVote, on: .report(receipt.reportID))
        case .queued:
            device.discard(receipt.reportID)
            contributions.undo(receipt.reportID)
        case .sent, .heldForReview:
            contributions.undo(receipt.reportID)
        case .alreadySaid:
            break
        }
    }

    /// "Añadir detalle": the value goes with the report, queued or sent.
    func addDetail(_ value: ReportValue, to receipt: ReportReceipt) {
        if receipt.delivery == .queued {
            device.update(receipt.reportID, value: value)
        }
        contributions.update(receipt.reportID, value: value)
    }

    /// A price far outside DACO's range waits for review (§6.1).
    private func isHeld(_ report: Report) -> Bool {
        guard let price = report.price else { return false }
        return PriceEntry.check(price, references: snapshot.dacoReferences, now: connection.now) == .heldForReview
    }

    /// Everyone confirming the standing report once your Sigue igual counts.
    /// The snapshot already counts a Sigue igual you gave before, so only a
    /// new or changed vote adds you.
    private static func neighbours(confirming standing: Report, replacing replaced: MyVote?) -> Int {
        var votes = standing.votes
        if replaced?.agrees != true { votes.confirmCount += 1 }
        return VerificationRules.confirmingNeighbours(votes)
    }
}
