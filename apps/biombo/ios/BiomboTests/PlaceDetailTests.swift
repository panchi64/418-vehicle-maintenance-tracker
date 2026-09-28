@testable import Biombo
import Foundation
import Testing

@Suite("Place detail per layer")
struct PlaceDetailTests {
    let snapshot = SampleData.snapshot()
    let builder = PlaceDetailBuilder()

    private var areas: [AreaStatus] {
        AnswerResolver().areaStatuses(snapshot.outageAreas, isCrisis: false, now: snapshot.generatedAt)
    }

    private func detail(_ selection: Selection, in snapshot: PlacesSnapshot? = nil) throws -> PlaceDetail {
        try #require(builder.detail(for: selection, snapshot: snapshot ?? self.snapshot, areas: areas))
    }

    @Test("Gas: hero price, DACO ladder for its brand, trend, directions, question")
    func station() throws {
        let puma = try detail(.place(SampleData.ID.pumaLosFiltros, .gas))
        #expect(puma.answer?.price?.centsPerLitre == 99)
        #expect(puma.ladder?.verdict(in: .litre) == .below(centsPerLitre: 3))
        #expect(puma.trend != nil)
        #expect(puma.offersDirections)
        #expect(puma.question == .price(FuelPrice(grade: .regular, centsPerLitre: 99)))
        #expect(!puma.isEmpty)
    }

    @Test("Gas: other grades and other statuses sit beside the answer, never repeat it")
    func stationExtras() throws {
        let gulf = try detail(.place(SampleData.ID.gulfBairoa, .gas))
        #expect(gulf.otherGrades == [FuelPrice(grade: .diesel, centsPerLitre: 108)])
        #expect(Set(gulf.alsoReported.map(\.kind)) == [.hasGas, .queue])
    }

    @Test("Off-brand station compares against DACO's island range")
    func offBrand() throws {
        let paseos = try detail(.place(SampleData.ID.losPaseos, .gas))
        #expect(paseos.ladder?.verdict(in: .litre) == .withinRange)
    }

    @Test("Nothing current: the empty state, with older reports newest first")
    func emptyState() throws {
        let cidra = try detail(.place(SampleData.ID.shellCidra, .gas))
        #expect(cidra.isEmpty)
        #expect(cidra.question == nil)
        #expect(cidra.ladder == nil)
        #expect(cidra.stale.count == 3)
        #expect(cidra.stale.map(\.asOf) == cidra.stale.map(\.asOf).sorted(by: >))
        #expect(cidra.stale.allSatisfy { !$0.freshness.isCurrent })
    }

    @Test("Chargers: reliability in words and each port's newest status")
    func charger() throws {
        let plaza = try detail(.place(SampleData.ID.chargerPlazaAmericas, .chargers))
        #expect(plaza.reliability == .usuallyWorks)
        #expect(plaza.ports.map(\.status) == [.chargerWorks, nil])
        let mall = try detail(.place(SampleData.ID.chargerMayaguezMall, .chargers))
        #expect(mall.reliability == .unknown)
        #expect(mall.ports.map(\.status) == [nil, .connectorDamaged])
    }

    @Test("Businesses: owner events and products; neighbours only as counts")
    func business() throws {
        let ceiba = try detail(.place(SampleData.ID.panaderiaLaCeiba, .businesses))
        #expect(ceiba.events == [SampleData.bombaNight])
        #expect(ceiba.products == ["Hielo"])
        let carmen = try detail(.place(SampleData.ID.colmadoDonaCarmen, .businesses))
        #expect(carmen.answer?.kind == .businessOpen)
        #expect(carmen.neighbours == [NeighbourCount(kind: .businessClosed, count: 1, age: .thisAfternoon)])
    }

    @Test("Water: the AAA boil-water notice sits under the answer")
    func boilWater() throws {
        let comerio = try detail(.place(SampleData.ID.comerioPueblo, .water))
        #expect(comerio.answer?.kind == .cloudyWater)
        #expect(comerio.boilNotices.map(\.id) == ["notice.aaa.boil.comerio"])
    }

    @Test("Roads: a flood always warns; DTOP's closure is an official card, not a vote")
    func roads() throws {
        #expect(try detail(.place(SampleData.ID.pr52Caguas, .roads)).isFlood)
        let comerio = try detail(.place(SampleData.ID.pr156Comerio, .roads))
        #expect(comerio.otherNotices.map(\.agency) == [.dtop])
    }

    @Test("Areas: an official area isn't voted on and its own plan isn't repeated")
    func areaDetails() throws {
        let frailes = try detail(.area("outage.water.guaynabo-frailes", .water))
        #expect(frailes.question == nil)
        #expect(frailes.otherNotices.isEmpty)
        let bairoa = try detail(.area("outage.power.caguas-bairoa", .power))
        #expect(bairoa.question == .outage(.power))
    }

    @Test("Confirming is for people nearby: 300 m of a place, 1 km of an area")
    func nearbyOnly() throws {
        #expect(try !detail(.place(SampleData.ID.pumaLosFiltros, .gas)).canConfirm)
        let near = SampleData.snapshot(vantage: GeoPoint(18.3755, -66.1190))
        #expect(try detail(.place(SampleData.ID.pumaLosFiltros, .gas), in: near).canConfirm)
        #expect(ConfirmRules.isNearby(distance: 900, isArea: true))
        #expect(!ConfirmRules.isNearby(distance: 900, isArea: false))
    }

    @Test("Unknown selections resolve to nothing")
    func unknown() {
        #expect(builder.detail(for: .place("nope", .gas), snapshot: snapshot, areas: areas) == nil)
        #expect(builder.detail(for: .area("nope", .power), snapshot: snapshot, areas: areas) == nil)
    }
}
