@testable import Biombo
import Foundation
import Testing

@Suite("Quick Report: what one tap reports, and where")
struct QuickReportTests {
    private func builder(crisis: Bool = false, vantage: GeoPoint = SampleData.vantage) -> ReportContextBuilder {
        let snapshot = SampleData.snapshot(crisis: crisis, vantage: vantage)
        let digest = HomeDigest(snapshot: snapshot, vantage: vantage, visibleLayers: Layer.defaultVisible(inCrisis: crisis))
        return ReportContextBuilder(snapshot: snapshot, areas: digest.areas, vantage: vantage)
    }

    /// Beside Puma Los Filtros, inside AAA's Frailes water plan.
    private let atPuma = GeoPoint(18.3755, -66.1190)

    @Test("Where the sample stands, nothing snaps but the barrio: the three area reports, landing on Pueblo Viejo")
    func whereYouStand() throws {
        let context = builder().context(for: .whereYouAre)
        #expect(context.layer == nil)
        #expect(context.oneTap == [.noPower, .noWater, .noSignal])
        let target = try #require(context.target(for: .noPower))
        #expect(target.place.id == SampleData.ID.puebloViejo)
        #expect(target.isInReach)
        #expect(context.target(for: .gas) == nil)
    }

    @Test("Inside an outage the reversal comes first; the station in reach takes gas reports")
    func insideOutage() throws {
        let context = builder(vantage: atPuma).context(for: .whereYouAre)
        #expect(context.layer == .water)
        #expect(context.standsInOutage)
        #expect(context.oneTap.first == .waterBack)
        #expect(context.target(for: .water)?.place.id == SampleData.ID.frailes)
        let gas = try #require(context.target(for: .gas))
        #expect(gas.place.id == SampleData.ID.pumaLosFiltros)
        #expect(gas.distance < ContributionRules.snapRadius(for: .station))
    }

    @Test("Gas asks the price on ordinary days and availability in crisis")
    func gasVocabulary() {
        #expect(ReportVocabulary.oneTap(for: .gas, current: nil, isCrisis: false) == [.price, .queue, .noGas])
        #expect(ReportVocabulary.oneTap(for: .gas, current: nil, isCrisis: true) == [.hasGas, .noGas, .queue])
        #expect(ReportVocabulary.oneTap(for: .gas, current: .noGas, isCrisis: false).first == .hasGas)
        #expect(!ReportVocabulary.primary(for: .gas, isCrisis: true).contains(.price))
    }

    @Test("A reported road problem puts Abierta otra vez first, still three verbs")
    func roadReversal() {
        let verbs = ReportVocabulary.oneTap(for: .roads, current: .flooded, isCrisis: false)
        #expect(verbs == [.reopened, .flooded, .landslide])
    }

    @Test("Every layer: at most four verbs up front, the rest in Más, owner-only kinds never", arguments: Layer.allCases)
    func everyKindReachable(layer: Layer) {
        for crisis in [false, true] {
            let primary = ReportVocabulary.primary(for: layer, isCrisis: crisis)
            let more = ReportVocabulary.more(for: layer, isCrisis: crisis)
            #expect(primary.count <= 4)
            #expect(Set(primary).isDisjoint(with: more))
            let offered = Set(primary + more)
            #expect(offered == Set(ReportKind.kinds(for: layer).filter { !$0.isOwnerOnly }))
            #expect(ReportVocabulary.oneTap(for: layer, current: nil, isCrisis: crisis).count == 3)
        }
    }

    @Test("From a detail, the report is about that place; far away it can't be sent")
    func placeFocus() throws {
        let context = builder().context(for: .place(SampleData.ID.gulfBairoa, .gas))
        #expect(context.layer == .gas)
        let target = try #require(context.target(for: .gas))
        #expect(target.place.id == SampleData.ID.gulfBairoa)
        #expect(!target.isInReach)
    }

    @Test("Cambiar lists the places in reach, nearest first, and a pick replaces the nearest")
    func change() throws {
        // Between Frailes and Pueblo Viejo, in reach of both barrios.
        let builder = builder(vantage: GeoPoint(18.3885, -66.1120))
        let areas = builder.candidates(for: .water)
        #expect(areas.map(\.place.id) == [SampleData.ID.frailes, SampleData.ID.puebloViejo])
        #expect(areas.map(\.distance) == areas.map(\.distance).sorted())
        let other = try #require(areas.dropFirst().first)
        let context = builder.context(for: .whereYouAre, chosen: [.water: other.place.id])
        #expect(context.target(for: .water)?.place.id == other.place.id)
    }

    @Test("A point inside a ring is inside; a line's distance is to its nearest vertex")
    func geometry() {
        #expect(SampleData.vantage.isInside(SampleData.puebloViejoRing))
        #expect(!SampleData.vantage.isInside(SampleData.frailesRing))
        #expect(SampleData.vantage.distance(to: .polygon(SampleData.puebloViejoRing)) == 0)
    }
}
