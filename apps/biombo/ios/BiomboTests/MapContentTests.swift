@testable import Biombo
import Foundation
import Testing

@Suite("Map content: zoom tiers, visibility and clustering")
struct MapContentTests {
    let digest = HomeDigest(snapshot: SampleData.snapshot(), vantage: SampleData.vantage, visibleLayers: Set(Layer.allCases))

    @Test("Zoom tiers read the narrower side of the span")
    func tiers() {
        #expect(ZoomTier(latitudeDelta: 1.8, longitudeDelta: 0.9) == .island)
        #expect(ZoomTier(latitudeDelta: 0.8, longitudeDelta: 0.35) == .municipio)
        #expect(ZoomTier(latitudeDelta: 0.2, longitudeDelta: 0.05) == .street)
    }

    @Test("Island zoom counts areas per municipio instead of drawing them")
    func islandCounts() {
        let content = MapContent(answers: digest.answers, areas: digest.areas, visibleLayers: Set(Layer.allCases), tier: .island)
        #expect(content.areas.isEmpty)
        #expect(content.counts.map(\.count).reduce(0, +) == digest.areas.count)
        #expect(content.counts.contains { $0.municipio == "Caguas" && $0.layer == .power && $0.count == 1 })
    }

    @Test("Municipio zoom draws only confirmed and official areas; street zoom adds open ones")
    func areaTiers() {
        let municipio = MapContent(answers: [], areas: digest.areas, visibleLayers: Set(Layer.allCases), tier: .municipio)
        #expect(!municipio.areas.contains { $0.id == "outage.signal.claro.barranquitas" })
        let street = MapContent(answers: [], areas: digest.areas, visibleLayers: Set(Layer.allCases), tier: .street)
        #expect(street.areas.count == digest.areas.count)
    }

    @Test("Hidden layers draw nothing, and nothing stale is ever a pin")
    func visibilityAndGate() {
        let content = MapContent(answers: digest.answers, areas: digest.areas, visibleLayers: [.gas], tier: .street)
        #expect(content.pins.allSatisfy { $0.layer == .gas && $0.freshness.isCurrent })
        #expect(content.areas.isEmpty)
        // The 3-day-old Puma Cayey price is stale, so its pin shows the current "no hay" instead.
        let cayey = content.pins.first { $0.place.id == SampleData.ID.pumaCayey }
        #expect(cayey?.value == .status(.noGas))
    }

    @Test("Same-layer pins in one cell cluster; other layers never merge")
    func clustering() {
        let metro = digest.answers.filter { [.gas, .chargers].contains($0.layer) && $0.place.region == .metro }
        let wide = PinClusterer().marks(for: metro, latitudeDelta: 2, longitudeDelta: 2)
        let clusters = wide.compactMap { if case .cluster(let cluster) = $0 { cluster } else { nil } }
        #expect(clusters.contains { $0.layer == .gas && $0.members.count == 4 })
        #expect(clusters.allSatisfy { cluster in cluster.members.allSatisfy { $0.layer == cluster.layer } })

        let close = PinClusterer().marks(for: metro, latitudeDelta: 0.01, longitudeDelta: 0.01)
        #expect(close.count == metro.count)
    }
}
