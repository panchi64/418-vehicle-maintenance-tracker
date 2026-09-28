@testable import Biombo
import Foundation
import Testing

@Suite("Capas live answers and search")
struct CapasAndSearchTests {
    let snapshot = SampleData.snapshot()

    @Test("Capas answers every layer, hidden ones included, and flags news")
    func liveAnswers() {
        let digest = HomeDigest(snapshot: snapshot, vantage: SampleData.vantage, visibleLayers: [])
        let live = Dictionary(uniqueKeysWithValues: digest.layers.map { ($0.layer, $0) })
        #expect(digest.layers.map(\.layer) == Layer.allCases)
        #expect(live[.power]?.live == .powerOutages(1))
        #expect(live[.water]?.live == .boilWater)
        #expect(live[.roads]?.live == .roadEvents(2))
        #expect(live[.gas]?.live == .gasFrom(FuelPrice(grade: .regular, centsPerLitre: 97)))
        #expect(live[.chargers]?.live == .chargersWorking(1))
        #expect(live[.signal]?.live == .nothingNew)
        #expect(live[.power]?.hasNews == true)
        #expect(live[.gas]?.hasNews == false)
    }

    @Test("A reopened road alone is not news")
    func reopenedIsNotNews() throws {
        let rincon = HomeDigest(
            snapshot: snapshot, vantage: GeoPoint(18.3402, -67.2499), visibleLayers: [],
            builder: NearbyBuilder(radius: 5_000)
        )
        let roads = try #require(rincon.layers.first { $0.layer == .roads })
        guard case .roadEvent(let answer) = roads.live else {
            Issue.record("Expected one road event")
            return
        }
        #expect(answer.kind == .reopened)
        #expect(!roads.hasNews)
    }

    @Test("Search ignores case and accents")
    func accents() {
        let results = PlaceSearch().results(for: "rio piedras", in: snapshot.places, near: SampleData.vantage)
        #expect(Set(results.map(\.id)) == [SampleData.ID.shellRioPiedras, SampleData.ID.rioPiedras])
    }

    @Test("Word-start matches come before matches inside a word")
    func wordStartFirst() throws {
        let results = PlaceSearch().results(for: "rio", in: snapshot.places, near: SampleData.vantage).map(\.id)
        let rioPiedras = try #require(results.firstIndex(of: SampleData.ID.rioPiedras))
        let comerio = try #require(results.firstIndex(of: "municipio#Comerío"))
        #expect(rioPiedras < comerio)
    }

    @Test("Road news counts problems, not roads reported open again")
    func reopenedNotCounted() throws {
        let station = SampleData.stations[0]
        let road = SampleData.roads[0]
        func answer(_ kind: ReportKind, _ place: Place) -> PlaceAnswer {
            PlaceAnswer(place: place, layer: .roads, lead: Report(kind: kind, placeID: place.id, capturedAt: SampleData.now),
                        value: .status(kind), label: .unverified, freshness: .fresh, dispute: .none)
        }
        let rows = [answer(.flooded, road), answer(.reopened, station)].map { NearbyRow(item: .place($0), distance: 100) }
        let roads = try #require(LayerDigest.make(rows: rows, notices: [], now: SampleData.now).first { $0.layer == .roads })
        guard case .roadEvent(let event) = roads.live else {
            Issue.record("Expected the one problem said as its sentence")
            return
        }
        #expect(event.kind == .flooded)
        #expect(roads.hasNews)
    }

    @Test("Municipios come first, then places by match and distance")
    func ordering() {
        let caguas = PlaceSearch().results(for: "Caguas", in: snapshot.places, near: SampleData.vantage)
        #expect(caguas.first?.id == "municipio#Caguas")

        let puma = PlaceSearch().results(for: "puma", in: snapshot.places, near: SampleData.vantage)
        #expect(puma.map(\.id) == [SampleData.ID.pumaLosFiltros, SampleData.ID.pumaCayey])
    }

    @Test("An empty query finds nothing")
    func empty() {
        #expect(PlaceSearch().results(for: "   ", in: snapshot.places, near: SampleData.vantage).isEmpty)
    }
}
