@testable import Biombo
import Foundation
import Testing

@Suite("Map clustering edges, label collisions and island dates")
struct MapLabelTests {
    let now = SampleData.now

    private func pin(_ id: String, _ layer: Layer, _ latitude: Double, _ longitude: Double, kind: ReportKind = .price) -> PlaceAnswer {
        let place = Place(id: id, kind: .station, name: id, municipio: "Guaynabo", region: .metro, geometry: .point(GeoPoint(latitude, longitude)))
        let value: AnswerValue = kind == .price ? .price(FuelPrice(grade: .regular, centsPerLitre: 99)) : .status(kind)
        return PlaceAnswer(place: place, layer: layer, lead: Report(kind: kind, placeID: id, capturedAt: now),
                           value: value, label: .unverified, freshness: .fresh, dispute: .none)
    }

    @Test("Two same-layer pins either side of a grid line still cluster")
    func clusterAcrossCellEdge() {
        // Cells are 0.1° wide here; the pins sit 0.002° apart across the 18.3 line.
        let pins = [pin("a", .gas, 18.2990, -66.1), pin("b", .gas, 18.3010, -66.1)]
        let marks = PinClusterer().marks(for: pins, latitudeDelta: 1.2, longitudeDelta: 0.7)
        #expect(marks.count == 1)
        guard case .cluster(let cluster) = marks.first else {
            Issue.record("Expected one cluster")
            return
        }
        #expect(cluster.members.count == 2)
    }

    @Test("Where two labels would overlap, the lower-priority one is dropped")
    func overlappingLabels() {
        let viewport = MapLabelPlacer.Viewport(latitudeDelta: 0.35, longitudeDelta: 0.35, width: 400, height: 400)
        let price = pin("gas", .gas, 18.30, -66.10)
        // About 10 pt apart: close enough for the labels to collide, not one spot.
        let outage = pin("line", .power, 18.309, -66.10, kind: .lineDown)
        let far = pin("far", .gas, 18.45, -65.95)
        let layout = MapLabelPlacer().layout(
            marks: [.pin(price), .pin(outage), .pin(far)], areas: [], vantage: GeoPoint(17, -65),
            selectedID: nil, viewport: viewport
        )
        #expect(layout.hiddenLabels == [price.id])

        let selected = MapLabelPlacer().layout(
            marks: [.pin(price), .pin(outage)], areas: [], vantage: GeoPoint(17, -65),
            selectedID: price.id, viewport: viewport
        )
        #expect(selected.hiddenLabels == [outage.id])
    }

    @Test("Pins on one spot stack apart, and each keeps a label at its own width")
    func sameSpotStacks() {
        let viewport = MapLabelPlacer.Viewport(latitudeDelta: 0.1, longitudeDelta: 0.05, width: 402, height: 874)
        let power = pin("power", .power, 18.2565, -66.038, kind: .lineDown)
        let water = pin("water", .water, 18.2565, -66.038, kind: .waterPoint)
        let layout = MapLabelPlacer().layout(
            marks: [.pin(power), .pin(water)], areas: [], vantage: GeoPoint(17, -65), selectedID: nil,
            viewport: viewport, labelWidths: [power.id: 90, water.id: 120]
        )
        let offsets = [power.id, water.id].compactMap { layout.pinOffsets[$0] }
        #expect(offsets.count == 2 && offsets[0] != offsets[1])
        #expect(layout.hiddenLabels.isEmpty)
    }

    @Test("An area tag steps off a pin at its centre")
    func areaTagAvoidsPin() throws {
        let digest = HomeDigest(snapshot: SampleData.snapshot(), vantage: SampleData.vantage, visibleLayers: [.water, .gas])
        let frailes = try #require(digest.areas.first { $0.id == "outage.water.guaynabo-frailes" })
        let puma = pin("puma", .gas, frailes.anchor.latitude, frailes.anchor.longitude)
        let layout = MapLabelPlacer().layout(
            marks: [.pin(puma)], areas: [frailes], vantage: SampleData.vantage, selectedID: nil,
            viewport: .init(latitudeDelta: 0.75, longitudeDelta: 0.35, width: 402, height: 874)
        )
        #expect(layout.tagOffsets[frailes.id] != nil)
    }

    @Test("Island dates use Puerto Rico's zone and the given language, whatever the device's")
    func islandDates() throws {
        var components = DateComponents(year: 2026, month: 9, day: 27, hour: 23, minute: 30)
        components.timeZone = PuertoRico.timeZone
        let lateSunday = try #require(PuertoRico.calendar.date(from: components))
        // 23:30 AST is already Monday in UTC.
        #expect(lateSunday.island(.dateTime.weekday(.wide), locale: Locale(identifier: "es_PR")) == "domingo")
        #expect(lateSunday.island(.dateTime.weekday(.wide), locale: Locale(identifier: "en_US")) == "Sunday")
        #expect(lateSunday.islandClock(locale: Locale(identifier: "en_US")).hasPrefix("11:30"))
    }
}
