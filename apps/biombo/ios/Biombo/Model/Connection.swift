import Foundation

/// How well the device reaches Biombo right now (PRODUCT.md §4.6, §8).
nonisolated enum ConnectionStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case online
    /// A constrained network: utilities load first, the rest is cached.
    case weak
    case offline
}

/// What the device knows about its connection: the status, when it last
/// synced, and its own clock. Offline, the cached snapshot is judged at the
/// device's clock, so it ages under the same freshness rules as ever (§4.6).
nonisolated struct ConnectionState: Hashable, Sendable {
    var status: ConnectionStatus
    /// When the snapshot on screen was fetched.
    var lastSyncedAt: Date
    /// The device's clock.
    var now: Date

    var isOnline: Bool { status == .online }

    /// How old the newest data is.
    var dataAge: TimeInterval { max(0, now.timeIntervalSince(lastSyncedAt)) }

    /// A report sent now goes straight out, or waits in the outbox (§4.6).
    var queuesReports: Bool { status == .offline }
}
