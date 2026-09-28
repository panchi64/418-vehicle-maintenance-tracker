@testable import Biombo
import Foundation
import Testing

@Suite("Cerca de ti: answer, grouping and caps")
struct NearbyDigestTests {
    let defaults = Set(Layer.allCases.filter(\.isShownByDefault))

    private func digest(crisis: Bool = false, layers: Set<Layer>? = nil) -> HomeDigest {
        HomeDigest(snapshot: SampleData.snapshot(crisis: crisis), vantage: SampleData.vantage, visibleLayers: layers ?? defaults)
    }

    @Test("The answer leads with the nearest established outage, then the cheapest gas")
    func facts() {
        let nearby = digest().nearby
        #expect(nearby.areaName == "Guaynabo")
        guard case .outage(let status) = nearby.facts.first else {
            Issue.record("Expected an outage first")
            return
        }
        #expect(status.id == "outage.water.guaynabo-frailes")
        guard case .cheapestGas(let gas) = nearby.facts.last else {
            Issue.record("Expected the cheapest gas second")
            return
        }
        #expect(gas.place.id == SampleData.ID.gulfBairoa)
    }

    @Test("With nothing current nearby the answer is empty, not old")
    func quiet() {
        let far = HomeDigest(snapshot: SampleData.snapshot(), vantage: GeoPoint(17.9, -65.3), visibleLayers: defaults)
        #expect(far.nearby.facts == [.quiet])
        #expect(far.nearby.sections.isEmpty)
    }

    @Test("Ordinary sections: gas by price, then services, then roads; hidden layers leave")
    func ordinarySections() throws {
        let nearby = digest().nearby
        #expect(nearby.sections.map(\.kind) == [.cheapestGas, .services, .roads])
        let gas = try #require(nearby.section(.cheapestGas))
        let prices = gas.rows.compactMap { row -> Double? in
            if case .place(let answer) = row.item { answer.price?.centsPerLitre } else { nil }
        }
        #expect(prices == prices.sorted())
        #expect(prices.first == 97)
        #expect(gas.grammar == .place)
        #expect(nearby.section(.roads)?.grammar == .event)
    }

    @Test("Services rank official areas, then confirmed, then point events; the answered area is said once")
    func servicesOrder() throws {
        let services = try #require(digest().nearby.section(.services))
        #expect(!services.rows.contains { $0.id == "outage.water.guaynabo-frailes" })
        #expect(services.rows.first?.id == "outage.power.caguas-bairoa")
    }

    @Test("An official area in the answer drops its matching plan card, never actionable ones")
    func answeredNoticeOnce() {
        let notices = digest().nearby.officials.flatMap(\.notices).map(\.id)
        #expect(!notices.contains("notice.aaa.plan.guaynabo"))
        #expect(notices.contains("notice.aaa.boil.comerio"))
    }

    @Test("A card and a row never say the same fact: DTOP's closure drops the row, an official area drops its card")
    func noticesAndRowsSaidOnce() {
        let nearby = digest(crisis: true).nearby
        let cards = nearby.officials.flatMap(\.notices).map(\.id)
        #expect(cards.contains("notice.dtop.pr156"))
        #expect(!(nearby.section(.roads)?.rows.contains { $0.item.placeID == SampleData.ID.pr156Comerio } ?? false))
        #expect(nearby.section(.services)?.rows.contains { $0.id == "outage.water.guaynabo-frailes" } == true)
        #expect(!cards.contains("notice.aaa.plan.guaynabo"))
    }

    @Test("Crisis answers with the official warning, then the nearest fuel")
    func crisisAnswer() throws {
        let nearby = digest(crisis: true).nearby
        guard case .warning(let warning) = nearby.facts.first else {
            Issue.record("Expected the warning first")
            return
        }
        #expect(warning.kind == .weatherWarning)
        guard case .nearestFuel(let station, let distance) = nearby.facts.last else {
            Issue.record("Expected the nearest fuel second")
            return
        }
        #expect(station.place.id == SampleData.ID.pumaLosFiltros)
        #expect(distance > 0)
        #expect(!nearby.officials.flatMap(\.notices).contains { $0.id == warning.id })
        #expect(TrustSuffix(nearby.facts[0], now: SampleData.now)?.label == .official(.nws))
    }

    @Test("Changing the drawn layers rebuilds only Cerca de ti")
    func showing() {
        let full = digest()
        let noGas = full.showing(defaults.subtracting([.gas]))
        #expect(noGas.nearby.section(.cheapestGas) == nil)
        #expect(noGas.layers == full.layers)
        #expect(noGas.answers == full.answers)
        #expect(noGas.showing(defaults).nearby == full.nearby)
    }

    @Test("A searched place answers on a drawn layer first")
    func answerForPlace() {
        let digest = digest(layers: [.power])
        #expect(digest.answer(forPlace: SampleData.ID.bairoa)?.layer == .power)
        #expect(digest.answer(forPlace: SampleData.ID.pumaLosFiltros)?.layer == .gas)
    }

    @Test("Summary shows 3 rows then Ver todas (N); full shows 5; crisis caps at 3")
    func caps() throws {
        let gas = try #require(digest().nearby.section(.cheapestGas))
        #expect(gas.rows.count == 5)
        #expect(gas.shownRows(cap: DisclosureTier.summary.rowCap(isCrisis: false)).count == 3)
        #expect(gas.overflowCount(cap: 3) == 5)
        #expect(gas.overflowCount(cap: DisclosureTier.full.rowCap(isCrisis: false)) == 0)
        #expect(DisclosureTier.full.rowCap(isCrisis: true) == 3)
        #expect(digest(layers: Set(Layer.allCases)).nearby.sections(for: .summary).count == 3)
    }

    @Test("Crisis puts services and roads before places")
    func crisisOrder() {
        let nearby = digest(crisis: true).nearby
        #expect(nearby.isCrisis)
        #expect(Array(nearby.sections.map(\.kind).prefix(2)) == [.services, .roads])
    }

    @Test("Official cards: one per agency, actionable first")
    func officials() throws {
        let officials = digest().nearby.officials
        #expect(officials.map(\.agency) == [.aaa, .dtop])
        let aaa = try #require(officials.first)
        #expect(aaa.notices.first?.kind == .boilWater)
        #expect(digest(crisis: true).nearby.officials.count == NearbyBuilder.officialCap)
    }

    @Test("Capas keeps the boil-water notice when more agencies than cards speak")
    func boilNoticeBeyondCap() throws {
        var snapshot = SampleData.snapshot()
        let others: [Agency] = [.luma, .dtop, .nmead, .nws]
        snapshot.notices += others.enumerated().map { index, agency in
            OfficialNotice(
                id: "notice.extra.\(index)", agency: agency, kind: .shelter, layer: .roads,
                headline: "Aviso \(index).", guidance: "Sigue las instrucciones.", municipios: [],
                issuedAt: SampleData.ago(minutes: 30), updatedAt: SampleData.ago(minutes: Double(10 + index)), isFeed: false
            )
        }
        let digest = HomeDigest(snapshot: snapshot, vantage: SampleData.vantage, visibleLayers: defaults)
        #expect(!digest.nearby.officials.contains { $0.agency == .aaa })
        let water = try #require(digest.layers.first { $0.layer == .water })
        #expect(water.live == .boilWater)
    }

    @Test("DACO's range covers today's regular references")
    func dacoRange() {
        #expect(digest().nearby.dacoRange == DacoRange(grade: .regular, cents: 99...102))
    }

    @Test("Stale reports sit behind their section, newest first, never in its rows")
    func staleRows() throws {
        let now = SampleData.now
        let station = SampleData.stations[0]
        let old = PlaceAnswer(
            place: station, layer: .gas,
            lead: Report(kind: .price, value: .price(FuelPrice(grade: .regular, centsPerLitre: 95)), placeID: station.id, capturedAt: now.addingTimeInterval(-.days(3))),
            value: .price(FuelPrice(grade: .regular, centsPerLitre: 95)), label: .unverified, freshness: .stale, dispute: .none
        )
        let nearby = NearbyBuilder().make(.init(
            vantage: station.anchor, answers: [], staleAnswers: [old], areas: [], notices: [], dacoReferences: [],
            isCrisis: false, visibleLayers: [.gas], now: now
        )).nearby
        let gas = try #require(nearby.section(.cheapestGas))
        #expect(gas.rows.isEmpty)
        #expect(gas.staleRows.count == 1)
        #expect(nearby.facts == [.quiet])
    }
}
