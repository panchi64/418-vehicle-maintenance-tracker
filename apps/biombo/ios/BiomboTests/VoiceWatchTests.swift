@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Siri: the phrases do what they say, and watching never doubles up")
struct VoiceWatchTests {
    private let spanish = Locale(identifier: "es_PR")

    private func context(watches: [WatchedPlace] = SampleData.watchedPlaces) -> IntentContext {
        IntentContext(
            snapshots: SnapshotStore(),
            device: DeviceStore(),
            watches: WatchStore(places: watches),
            contributions: ContributionStore(),
            provider: { SamplePlacesProvider() }
        )
    }

    @Test("«Pregúntale a Biombo si hay luz» names no service, so it asks about luz")
    func defaultService() {
        #expect(CheckConditionIntent().service == .power)
    }

    @Test("«Cómo están mis lugares» answers for every watched place, the quiet ones together")
    func everyWatchedPlace() async {
        let said = await CheckWatchedPlaceIntent.answer(for: nil, context: context(), locale: spanish)
        #expect(said.hasPrefix("En Casa de Mamá: "))
        #expect(said.contains("Todo normal en "))
        #expect(said.contains("Casa de Abuela"))
        #expect(said.hasSuffix("."))
        let none = await CheckWatchedPlaceIntent.answer(for: nil, context: context(watches: []), locale: spanish)
        #expect(none == "Todavía no vigilas ningún lugar.")
    }

    @Test("Quiet places are named as one list")
    func quietPlacesTogether() {
        let said = CheckWatchedPlaceIntent.sentences(for: [("Casa", []), ("Trabajo", [])], now: SampleData.now, locale: spanish)
        #expect(said == "Todo normal en Casa y Trabajo.")
    }

    @Test("A municipio watched by voice comes back from its search id")
    func municipioTarget() throws {
        let snapshot = SampleData.snapshot()
        let municipio = try #require(snapshot.places.first?.municipio)
        let found = WatchTargetQuery.entities(for: ["municipio#\(municipio)"], in: snapshot)
        #expect(found.map(\.id) == ["municipio#\(municipio)"])
        #expect(found.first?.draft.placeID == nil)
        #expect(found.first?.draft.municipio == municipio)
        #expect(WatchTargetQuery.entities(for: ["municipio#Narnia"], in: snapshot).isEmpty)
    }

    @Test("A municipio watch is found again by voice and by search; a station inside it is its own watch")
    func municipioDuplicates() throws {
        let station = try #require(SampleData.snapshot().places.first { $0.kind == .station })
        let store = WatchStore()
        guard case .started(let area) = WatchPlaceIntent.watch(.draft(municipio: station.municipio, at: station.anchor), named: nil, in: store) else {
            Issue.record("Expected a new municipio watch")
            return
        }
        let again = WatchedPlace.draft(municipio: station.municipio, at: station.anchor)
        #expect(WatchPlaceIntent.watch(again, named: nil, in: store) == .alreadyWatched(area))
        #expect(store.existing(like: again) == area, "Search opens the same watch to edit")

        guard case .started(let stationWatch) = WatchPlaceIntent.watch(.draft(for: station), named: nil, in: store) else {
            Issue.record("A station in a watched municipio is a new watch")
            return
        }
        #expect(store.existing(like: .draft(for: station)) == stationWatch)
        #expect(store.places.count == 2)
    }
}
