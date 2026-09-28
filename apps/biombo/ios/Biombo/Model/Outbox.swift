import Foundation

/// A report waiting for a network, with its capture time and where (§4.6).
/// The id is the idempotency key the server de-duplicates on.
nonisolated struct QueuedReport: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let kind: ReportKind
    /// Where it was captured, as the user would say it ("Calle Betances").
    let placeName: String
    let capturedAt: Date
    /// The report to replay. Sample items made before this build stand for
    /// reports the server would take as they are, so they carry none.
    var report: Report?

    init(id: UUID, kind: ReportKind, placeName: String, capturedAt: Date) {
        self.id = id
        self.kind = kind
        self.placeName = placeName
        self.capturedAt = capturedAt
    }

    init(_ report: Report, placeName: String) {
        self.init(id: report.id, kind: report.kind, placeName: placeName, capturedAt: report.capturedAt)
        self.report = report
    }
}

/// The outbox: every report persisted until the network returns (§4.6).
/// Items older than `overdueAfter` wait for the user to send or discard.
nonisolated struct Outbox: Codable, Hashable, Sendable {
    private(set) var items: [QueuedReport]
    /// Overdue items the user chose to send anyway. They keep their capture
    /// time: the server judges late reports by it (§4.6).
    private(set) var approved: Set<QueuedReport.ID> = []

    /// *Proposed*: past this, a queued report asks before it is sent.
    nonisolated static let overdueAfter: TimeInterval = .hours(24)

    init(items: [QueuedReport] = []) {
        self.items = items.sorted { $0.capturedAt > $1.capturedAt }
    }

    /// Going out on their own when the network returns, newest first.
    func pending(now: Date) -> [QueuedReport] {
        items.filter { !isOverdue($0, now: now) }
    }

    /// Older than a day and not yet approved: listed to send or discard.
    func overdue(now: Date) -> [QueuedReport] {
        items.filter { isOverdue($0, now: now) }
    }

    var isEmpty: Bool { items.isEmpty }

    func contains(_ id: QueuedReport.ID) -> Bool {
        items.contains { $0.id == id }
    }

    /// A report made offline joins the queue, newest first.
    mutating func enqueue(_ item: QueuedReport) {
        guard !contains(item.id) else { return }
        items.insert(item, at: items.firstIndex { $0.capturedAt <= item.capturedAt } ?? items.endIndex)
    }

    /// "Añadir detalle" on a queued report changes what will be sent.
    mutating func update(_ id: QueuedReport.ID, value: ReportValue?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].report?.value = value
    }

    /// Descartar, or Deshacer on a report that never left.
    mutating func discard(_ id: QueuedReport.ID) {
        items.removeAll { $0.id == id }
        approved.remove(id)
    }

    mutating func send(_ id: QueuedReport.ID) {
        guard contains(id) else { return }
        approved.insert(id)
    }

    /// The network is back: everything pending or approved leaves the
    /// queue to be sent, oldest first. Overdue items stay to be asked about.
    mutating func takeReplayable(now: Date) -> [QueuedReport] {
        let leaving = items.filter { !isOverdue($0, now: now) }
        let ids = Set(leaving.map(\.id))
        items.removeAll { ids.contains($0.id) }
        approved.subtract(ids)
        return leaving.reversed()
    }

    private func isOverdue(_ item: QueuedReport, now: Date) -> Bool {
        !approved.contains(item.id) && now.timeIntervalSince(item.capturedAt) >= Self.overdueAfter
    }
}

/// When a replay retries after a failure: exponential backoff with jitter,
/// so a whole island coming back online doesn't retry in step (§4.6, §8).
nonisolated enum ReplaySchedule {
    nonisolated static let base: TimeInterval = 2
    nonisolated static let cap: TimeInterval = 300

    /// The wait before try `attempt` (0 is the first), given `jitter` in 0…1:
    /// half the backoff, plus up to the other half at random.
    static func delay(attempt: Int, jitter: Double) -> TimeInterval {
        let backoff = min(cap, base * pow(2, Double(max(0, attempt))))
        return backoff * (0.5 + 0.5 * min(1, max(0, jitter)))
    }
}
