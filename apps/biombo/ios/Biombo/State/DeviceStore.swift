import Foundation
import Observation

/// The device's side of the network: its connection and its outbox (PRODUCT.md
/// §4.6). Pure state: the app replays the outbox when the network returns.
/// On sample data the connection comes from the Muestra switches in Ajustes.
@Observable
final class DeviceStore {
    var connection: ConnectionStatus
    private(set) var outbox: Outbox
    /// The device's clock while offline; nil reads the last sync time. On
    /// sample data it is `SampleData.offlineNow`, handed in by the app.
    let offlineClock: Date?

    init(connection: ConnectionStatus = .online, outbox: Outbox = Outbox(), offlineClock: Date? = nil) {
        self.connection = connection
        self.outbox = outbox
        self.offlineClock = offlineClock
    }

    /// The connection as the app shows it. Offline, the device's clock runs
    /// past the last sync, so what is on screen ages (§4.6); online and on
    /// weak signal it is the sync time.
    func state(lastSyncedAt: Date) -> ConnectionState {
        let now = connection == .offline ? max(offlineClock ?? lastSyncedAt, lastSyncedAt) : lastSyncedAt
        return ConnectionState(status: connection, lastSyncedAt: lastSyncedAt, now: now)
    }

    func discard(_ id: QueuedReport.ID) {
        outbox.discard(id)
    }

    func send(_ id: QueuedReport.ID) {
        outbox.send(id)
    }

    func enqueue(_ item: QueuedReport) {
        outbox.enqueue(item)
    }

    func update(_ id: QueuedReport.ID, value: ReportValue?) {
        outbox.update(id, value: value)
    }

    /// "Borrar mis datos" (§13): reports still waiting never leave.
    func eraseOutbox() {
        outbox = Outbox()
    }

    /// The network is back: what leaves the queue now, for the app to send.
    func takeReplayable(now: Date) -> [QueuedReport] {
        outbox.takeReplayable(now: now)
    }
}
