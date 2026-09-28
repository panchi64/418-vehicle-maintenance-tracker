@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Watching places: news, summary, store and storage")
struct WatchTests {
    private func digest(crisis: Bool = false) -> HomeDigest {
        let snapshot = SampleData.snapshot(crisis: crisis)
        return HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Layer.defaultVisible(inCrisis: crisis))
    }

    @Test("Only confirmed changes are news; the other places read Todo normal")
    func ordinaryNews() throws {
        let statuses = WatchStatusBuilder().statuses(for: SampleData.watchedPlaces, digest: digest())
        let mama = try #require(statuses.first { $0.place.name == "Casa de Mamá" })
        guard case .outage(let status) = mama.news.first else {
            Issue.record("Expected Miradero's outage")
            return
        }
        #expect(status.id == "outage.power.mayaguez-miradero")
        // PR-2 km 156 is 1 km away but Sin verificar: never news.
        #expect(!mama.news.contains { if case .road = $0 { true } else { false } })
        #expect(statuses.filter(\.isNormal).map(\.place.name) == ["Apartamento de Tití", "Casa de Abuela"])

        let summary = WatchSummary(statuses)
        #expect(summary.withNews == ["Casa de Mamá"])
        #expect(summary.normalCount == 2)
    }

    @Test("A barrio past the official outline is news only while that part is drawn", arguments: [(12, true), (2, false)])
    func extensionBarrio(devices: Int, isNews: Bool) {
        var snapshot = SampleData.snapshot(crisis: true)
        snapshot.outageAreas = snapshot.outageAreas.map { area in
            guard area.id == SampleData.crisisCaguas.id else { return area }
            var area = area
            area.communityExtension?.distinctDevices = devices
            return area
        }
        let digest = HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Layer.defaultVisible(inCrisis: true))
        let rioCanas = WatchedPlace(name: "Casa de Tío", location: GeoPoint(18.2400, -66.0380), municipio: "Caguas", barrio: "Río Cañas")
        let news = WatchStatusBuilder().news(for: rioCanas, digest: digest)
        #expect(news.contains { if case .outage(let status) = $0 { status.id == SampleData.crisisCaguas.id } else { false } } == isNews)
    }

    @Test("A warning covering the island is news everywhere; turned-off layers are not")
    func crisisAndLayers() {
        let crisisStatuses = WatchStatusBuilder().statuses(for: SampleData.watchedPlaces, digest: digest(crisis: true))
        #expect(crisisStatuses.allSatisfy { status in
            if case .warning = status.news.first { true } else { false }
        })

        // Said once above the list, not on every place.
        let overview = WatchStatusBuilder().overview(for: SampleData.watchedPlaces, digest: digest(crisis: true))
        #expect(overview.sharedWarnings.map(\.kind) == [.weatherWarning])
        #expect(overview.summary.withNews == ["Casa de Mamá"])
        #expect(overview.summary.hasSharedWarning)
        #expect(!overview.statuses.flatMap(\.news).contains { if case .warning = $0 { true } else { false } })
        let single = WatchStatusBuilder().overview(for: [SampleData.watchedPlaces[1]], digest: digest(crisis: true))
        #expect(single.sharedWarnings.isEmpty)
        #expect(!single.statuses[0].isNormal)

        var roadsOnly = SampleData.watchedPlaces[0]
        roadsOnly.layers = [.roads]
        #expect(WatchStatusBuilder().news(for: roadsOnly, digest: digest()).isEmpty)
    }

    @Test("A confirmed road problem within 2 km is news; farther is not")
    func roads() {
        let nearPR52 = WatchedPlace(name: "Casa", location: GeoPoint(18.2700, -66.0520), municipio: "Caguas", barrio: "Bairoa", layers: [.roads])
        let news = WatchStatusBuilder().news(for: nearPR52, digest: digest())
        #expect(news.count == 1)
        if case .road(let answer, let distance) = news.first {
            #expect(answer.place.id == SampleData.ID.pr52Caguas)
            #expect(distance <= 2_000)
        } else {
            Issue.record("Expected the flooded PR-52")
        }
        let far = WatchedPlace(name: "Lejos", location: GeoPoint(18.3200, -66.0520), municipio: "Caguas", layers: [.roads])
        #expect(WatchStatusBuilder().news(for: far, digest: digest()).isEmpty)
    }

    @Test("The store keeps at most 10, replaces by id and removes")
    func store() {
        let store = WatchStore()
        let places = (0..<WatchedPlace.limit).map {
            WatchedPlace(name: "Lugar \($0)", location: GeoPoint(18.4, -66.1), municipio: "Guaynabo")
        }
        places.forEach { store.save($0) }
        #expect(store.isFull)
        #expect(!store.save(WatchedPlace(name: "Otro", location: GeoPoint(18.4, -66.1), municipio: "Guaynabo")))
        var renamed = places[0]
        renamed.name = "Casa de Mamá"
        #expect(store.save(renamed))
        #expect(store.places[0].name == "Casa de Mamá")
        #expect(store.places.count == WatchedPlace.limit)
        store.remove(renamed.id)
        #expect(!store.isFull)
        store.replaceAll(with: SampleData.watchedPlaces)
        #expect(store.watch(for: SampleData.ID.miradero)?.name == "Casa de Mamá")
    }

    @Test("Watched places round-trip through device storage; nothing saved reads as nil")
    func storage() throws {
        let suite = "biombo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = DeviceStorage.watchedPlaces(defaults)
        #expect(storage.load() == nil)
        storage.save(SampleData.watchedPlaces)
        #expect(storage.load() == SampleData.watchedPlaces)
        storage.save([])
        #expect(storage.load() == [])
    }

    @Test("The promise and the preview name only what is switched on, for this place")
    func words() {
        var place = SampleData.watchedPlaces[0]
        let es = Locale(identifier: "es")
        #expect(String(localized: place.promise(locale: es)).contains("la luz"))
        place.layers = [.water]
        let promise = String(localized: place.promise(locale: es))
        #expect(!promise.contains("la luz"))
        #expect(String(localized: place.previewTitle).contains("Miradero"))
        #expect(String(localized: place.previewBody).contains("Casa de Mamá"))
    }
}
