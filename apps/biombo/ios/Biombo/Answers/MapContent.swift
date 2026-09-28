import Foundation

/// The three zoom bands §7 "By zoom" names, read from the visible span's
/// narrower side (a portrait map shows far more latitude than longitude).
nonisolated enum ZoomTier: Hashable, Sendable {
    /// Per-municipio outage counts, no polygons.
    case island
    /// Confirmed and official areas.
    case municipio
    /// Open areas too.
    case street

    /// Span thresholds in degrees (*proposed*).
    nonisolated static let islandSpan = 0.6
    nonisolated static let streetSpan = 0.12

    init(latitudeDelta: Double, longitudeDelta: Double) {
        let span = min(latitudeDelta, longitudeDelta)
        if span >= Self.islandSpan {
            self = .island
        } else if span >= Self.streetSpan {
            self = .municipio
        } else {
            self = .street
        }
    }
}

/// "Caguas · 1 área sin luz": what island zoom draws instead of polygons.
nonisolated struct MunicipioCount: Identifiable, Hashable, Sendable {
    let municipio: String
    let layer: Layer
    let count: Int
    let anchor: GeoPoint

    var id: String { "\(municipio)#\(layer.rawValue)" }
}

/// What the map draws. Every input is already freshness-gated by
/// `AnswerResolver`; this only applies layer visibility and zoom.
nonisolated struct MapContent: Hashable, Sendable {
    let pins: [PlaceAnswer]
    let areas: [AreaStatus]
    let counts: [MunicipioCount]

    init(answers: [PlaceAnswer], areas: [AreaStatus], visibleLayers: Set<Layer>, tier: ZoomTier) {
        pins = answers.filter { $0.freshness.isCurrent && visibleLayers.contains($0.layer) }
        let visibleAreas = areas.filter { $0.freshness.isCurrent && visibleLayers.contains($0.layer) }
        switch tier {
        case .island:
            self.areas = []
            counts = Self.counts(visibleAreas)
        case .municipio:
            self.areas = visibleAreas.filter(\.isEstablished)
            counts = []
        case .street:
            self.areas = visibleAreas
            counts = []
        }
    }

    private static func counts(_ areas: [AreaStatus]) -> [MunicipioCount] {
        let groups = Dictionary(grouping: areas) { "\($0.area.municipio)#\($0.layer.rawValue)" }
        return groups.values.compactMap { group in
            guard let first = group.first, let anchor = GeoPoint.centroid(of: group.map(\.anchor)) else { return nil }
            return MunicipioCount(municipio: first.area.municipio, layer: first.layer, count: group.count, anchor: anchor)
        }
        .sorted { $0.id < $1.id }
    }
}
