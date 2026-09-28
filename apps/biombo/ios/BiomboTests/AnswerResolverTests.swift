@testable import Biombo
import Foundation
import Testing

@Suite("Answer resolution and the freshness gate")
struct AnswerResolverTests {
    let resolver = AnswerResolver()
    let snapshot = SampleData.snapshot()
    let now = SampleData.now

    private func place(_ id: String) -> Place {
        snapshot.places.first { $0.id == id }!
    }

    private func answers(_ id: String) -> [PlaceAnswer] {
        resolver.answers(for: place(id), reports: snapshot.reports, now: now)
    }

    @Test("A station answers with its default-grade price")
    func stationPrice() throws {
        let gas = try #require(answers(SampleData.ID.gulfBairoa).first { $0.layer == .gas })
        #expect(gas.price == FuelPrice(grade: .regular, centsPerLitre: 97))
        #expect(gas.label == .communityConfirmed(neighbours: 4))
        #expect(gas.freshness == .fresh)
    }

    @Test("A stale price never answers; a current status does instead")
    func stalePriceGated() throws {
        let gas = try #require(answers(SampleData.ID.pumaCayey).first { $0.layer == .gas })
        #expect(gas.value == .status(.noGas))
        let stale = resolver.staleAnswers(for: place(SampleData.ID.pumaCayey), reports: snapshot.reports, now: now)
        #expect(stale.map(\.freshness) == [.stale])
        #expect(stale.first?.price?.centsPerLitre == 101)
    }

    @Test("A verified owner's status outranks a newer unverified negative")
    func ownerWins() throws {
        let business = try #require(answers(SampleData.ID.colmadoDonaCarmen).first)
        #expect(business.value == .status(.businessOpen))
        #expect(business.label == .verifiedOwner)
    }

    @Test("Outages on an area place live in the polygon, not in pins")
    func areaStatesNotPinned() {
        let bairoa = answers(SampleData.ID.bairoa)
        #expect(!bairoa.contains { $0.kind == .noPower })
        #expect(Set(bairoa.map(\.kind)) == [.lineDown, .waterPoint])
    }

    @Test("A disputed report stays, with the dispute promoted")
    func disputedStays() throws {
        let gas = try #require(answers(SampleData.ID.totalCaboRojo).first)
        #expect(gas.dispute == .disputed)
        #expect(TrustSuffix(gas, now: now).tone == .news)
    }

    @Test("Three fresh prices answer with their median")
    func median() throws {
        let station = place(SampleData.ID.pumaLosFiltros)
        let reports = [96.0, 100, 98].enumerated().map { index, cents in
            Report(kind: .price, value: .price(FuelPrice(grade: .regular, centsPerLitre: cents)), placeID: station.id,
                   capturedAt: now.addingTimeInterval(-.minutes(Double(10 + index))))
        }
        let gas = try #require(resolver.answers(for: station, reports: reports, now: now).first)
        #expect(gas.price?.centsPerLitre == 98)
    }

    @Test("A confirmed closed or dry station outranks an unverified price")
    func negativeGasOverridesPrice() throws {
        let station = place(SampleData.ID.pumaLosFiltros)
        let price = Report(kind: .price, value: .price(FuelPrice(grade: .regular, centsPerLitre: 99)), placeID: station.id,
                           capturedAt: now.addingTimeInterval(-.minutes(40)))
        let confirmed = Votes(confirmWeight: 6, disputeWeight: 0, confirmCount: 6, disputeCount: 0)
        for kind in [ReportKind.noGas, .stationClosed] {
            let negative = Report(kind: kind, placeID: station.id, capturedAt: now.addingTimeInterval(-.minutes(20)), votes: confirmed)
            let gas = try #require(resolver.answers(for: station, reports: [price, negative], now: now).first)
            #expect(gas.value == .status(kind))
            #expect(gas.price == nil)
        }
    }

    @Test("One unverified negative never flips a confirmed price")
    func unverifiedNegativeKeepsPrice() throws {
        let station = place(SampleData.ID.pumaLosFiltros)
        let price = Report(kind: .price, value: .price(FuelPrice(grade: .regular, centsPerLitre: 99)), placeID: station.id,
                           capturedAt: now.addingTimeInterval(-.minutes(40)),
                           votes: Votes(confirmWeight: 3, disputeWeight: 0, confirmCount: 3, disputeCount: 0))
        let negative = Report(kind: .noGas, placeID: station.id, capturedAt: now.addingTimeInterval(-.minutes(5)))
        let gas = try #require(resolver.answers(for: station, reports: [price, negative], now: now).first)
        #expect(gas.price?.centsPerLitre == 99)
    }

    @Test("A report resolved against is hidden from the answer")
    func resolvedHidden() {
        let station = place(SampleData.ID.pumaLosFiltros)
        let report = Report(kind: .noGas, placeID: station.id, capturedAt: now.addingTimeInterval(-.minutes(5)),
                            votes: Votes(confirmWeight: 0, disputeWeight: 3, confirmCount: 0, disputeCount: 3))
        #expect(resolver.answers(for: station, reports: [report], now: now).isEmpty)
    }

    @Test("Areas below 3 devices are never drawn; low confidence is Sin verificar")
    func areaStatuses() {
        let statuses = resolver.areaStatuses(snapshot.outageAreas, isCrisis: false, now: now)
        #expect(statuses.count == snapshot.outageAreas.count)
        let barranquitas = statuses.first { $0.id == "outage.signal.claro.barranquitas" }
        #expect(barranquitas?.label == .unverified)
        #expect(barranquitas?.isEstablished == false)

        var sparse = snapshot.outageAreas[0]
        sparse.evidence.distinctDevices = 2
        #expect(resolver.areaStatuses([sparse], isCrisis: false, now: now).isEmpty)
    }
}
