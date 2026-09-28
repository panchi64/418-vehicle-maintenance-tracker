@testable import Biombo
import Foundation
import Testing

@Suite("Sample data")
struct SampleDataTests {
    let snapshot = SampleData.snapshot()

    @Test("Every layer has reports or areas")
    func coversEveryLayer() {
        let layers = Set(snapshot.reports.map(\.layer)).union(snapshot.outageAreas.map(\.layer))
        #expect(layers == Set(Layer.allCases))
    }

    @Test("Places span the metro, central and western regions")
    func coversRegions() {
        #expect(Set(snapshot.places.map(\.region)).isSuperset(of: [.metro, .central, .west]))
    }

    @Test("Ids are unique and every report points at a known place")
    func referentialIntegrity() {
        let placeIDs = snapshot.places.map(\.id)
        #expect(Set(placeIDs).count == placeIDs.count)
        #expect(Set(snapshot.reports.map(\.id)).count == snapshot.reports.count)
        #expect(snapshot.reports.allSatisfy { Set(placeIDs).contains($0.placeID) })
    }

    @Test("The clock is fixed, so fixtures are deterministic")
    func fixedClock() {
        #expect(snapshot.generatedAt == SampleData.now)
        #expect(SampleData.snapshot() == snapshot)
        #expect(SampleData.now == ISO8601DateFormatter().date(from: "2026-09-27T21:30:00Z"))
    }

    @Test("The mix includes current and stale reports, for Ver reportes anteriores")
    func freshnessMix() {
        let policy = FreshnessPolicy()
        let states = Set(snapshot.reports.map { policy.evaluate($0, now: snapshot.generatedAt) })
        #expect(states.isSuperset(of: [.fresh, .aging, .stale]))
    }

    @Test("Crisis mode switches on and adds its notices")
    func crisisVariant() {
        let crisis = SampleData.snapshot(crisis: true)
        #expect(!snapshot.crisis.isActive)
        #expect(crisis.crisis.isActive)
        #expect(crisis.notices.count > snapshot.notices.count)
    }
}
