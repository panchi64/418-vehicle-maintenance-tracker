@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("What the device keeps is saved as it changes, with or without a window", .serialized)
struct DevicePersistenceTests {
    /// Counts `onWatchesChange` calls (Siri's place names).
    private final class Counter {
        var count = 0
    }

    private func freshDefaults(_ name: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// Observation hands changes on asynchronously; waits up to a second.
    private func eventually(_ condition: () -> Bool) async throws -> Bool {
        for _ in 0..<100 {
            if condition() { return true }
            try await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }

    @Test("A voice report and a watch started by Siri are saved with no view on screen")
    func backgroundIntentWrites() async throws {
        let defaults = try freshDefaults("biombo.tests.persistence")
        let watches = WatchStore()
        let device = DeviceStore()
        let contributions = ContributionStore()
        let updates = Counter()
        let persistence = DevicePersistence(
            watches: watches, device: device, contributions: contributions, defaults: defaults,
            savesWatches: true, onWatchesChange: { updates.count += 1 }
        )
        let context = IntentContext(
            snapshots: SnapshotStore(), device: device, watches: watches, contributions: contributions,
            provider: { SamplePlacesProvider() }
        )

        let voice = try #require(await ReportConditionIntent.draft(.noPower, from: nil, in: context))
        context.queue(voice)
        let outcome = WatchPlaceIntent.watch(.draft(municipio: "Ponce", at: GeoPoint(18.01, -66.61)), named: "Trabajo", in: watches)
        guard case .started(let watch) = outcome else {
            Issue.record("Expected a new watch")
            return
        }

        #expect(try await eventually { DeviceStorage.outbox(defaults).load()?.contains(voice.id) == true })
        #expect(try await eventually { DeviceStorage.watchedPlaces(defaults).load() == [watch] })
        #expect(try await eventually { DeviceStorage.contributions(defaults).load() == contributions.ledger })
        #expect(try await eventually { updates.count > 0 }, "Siri learns the new place name")
        withExtendedLifetime(persistence) {}
    }

    @Test("The sample watch list is never saved over the real one")
    func sampleWatchesStayUnsaved() async throws {
        let defaults = try freshDefaults("biombo.tests.persistence.sample")
        let real = [WatchedPlace(name: "Casa", location: GeoPoint(18.2, -66.5), municipio: "Ponce")]
        DeviceStorage.watchedPlaces(defaults).save(real)
        let watches = WatchStore(places: SampleData.watchedPlaces)
        let device = DeviceStore()
        let persistence = DevicePersistence(
            watches: watches, device: device, contributions: ContributionStore(), defaults: defaults,
            savesWatches: false, onWatchesChange: {}
        )
        watches.remove(SampleData.watchedPlaces[0].id)
        device.eraseOutbox()
        #expect(try await eventually { DeviceStorage.outbox(defaults).load() != nil }, "Everything else is still saved")
        #expect(DeviceStorage.watchedPlaces(defaults).load() == real)
        withExtendedLifetime(persistence) {}
    }
}
