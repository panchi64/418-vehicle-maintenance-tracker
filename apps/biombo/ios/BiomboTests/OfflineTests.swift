@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Offline: the outbox and the aging cached snapshot")
struct OfflineTests {
    let now = SampleData.offlineNow

    @Test("Reports within a day go out on their own; older ones wait to be sent or discarded")
    func outbox() {
        var outbox = SampleData.outbox
        #expect(outbox.pending(now: now).count == 2)
        #expect(outbox.pending(now: now).map(\.capturedAt) == outbox.pending(now: now).map(\.capturedAt).sorted(by: >))
        let old = outbox.overdue(now: now)
        #expect(old.map(\.kind) == [.noWater])

        outbox.send(old[0].id)
        #expect(outbox.overdue(now: now).isEmpty)
        #expect(outbox.pending(now: now).count == 3)

        outbox.discard(old[0].id)
        #expect(outbox.items.count == 2)
        outbox.send(UUID())
        #expect(outbox.items.count == 2)
    }

    @Test("The device store only changes the outbox through its transitions")
    func deviceStore() {
        let device = DeviceStore(connection: .offline, outbox: SampleData.outbox)
        let old = device.outbox.overdue(now: now)[0]
        device.discard(old.id)
        #expect(device.outbox.overdue(now: now).isEmpty)
        #expect(device.connection == .offline)
    }

    @Test("The device's clock runs past the sync only offline; queued reports are never in the future")
    func deviceClock() {
        let synced = SampleData.now
        let device = DeviceStore(connection: .offline, outbox: SampleData.outbox, offlineClock: now)
        #expect(device.state(lastSyncedAt: synced).now == now)
        #expect(device.state(lastSyncedAt: synced).lastSyncedAt == synced)
        device.connection = .weak
        #expect(device.state(lastSyncedAt: synced).now == synced)
        #expect(device.state(lastSyncedAt: synced).status == .weak)
        // A clock behind the sync never ages the snapshot backwards.
        let behind = DeviceStore(connection: .offline, offlineClock: synced.addingTimeInterval(-60))
        #expect(behind.state(lastSyncedAt: synced).now == synced)
        #expect(SampleData.outbox.items.allSatisfy { $0.capturedAt <= synced })
    }

    @Test("Offline, the cached snapshot ages at the device's clock: what passed its window leaves the answer")
    func aging() throws {
        let fresh = SampleData.snapshot()
        let aged = fresh.aged(to: now)
        #expect(aged.generatedAt == now)
        #expect(fresh.aged(to: fresh.generatedAt.addingTimeInterval(-60)).generatedAt == fresh.generatedAt)

        let connection = ConnectionState(status: .offline, lastSyncedAt: fresh.generatedAt, now: now)
        #expect(connection.dataAge == .minutes(40))
        #expect(!connection.isOnline)

        // Gulf Bairoa's line was reported 15 minutes before the sync: 55 minutes is past its 45.
        let station = try #require(fresh.places.first { $0.id == SampleData.ID.gulfBairoa })
        let resolver = AnswerResolver()
        let before = resolver.currentReports(for: station, layer: .gas, reports: fresh.reports, now: fresh.generatedAt)
        let after = resolver.currentReports(for: station, layer: .gas, reports: aged.reports, now: aged.generatedAt)
        #expect(before.contains { $0.kind == .queue })
        #expect(!after.contains { $0.kind == .queue })
    }

    @Test("Launch arguments pick the connection")
    func arguments() {
        #expect(LaunchArguments.connection(in: ["-offline"]) == .offline)
        #expect(LaunchArguments.connection(in: ["-weakSignal"]) == .weak)
        #expect(LaunchArguments.connection(in: []) == .online)
        #expect(LaunchArguments.connection(in: ["app", "-crisis", "-offline"]) == .offline)
    }
}
