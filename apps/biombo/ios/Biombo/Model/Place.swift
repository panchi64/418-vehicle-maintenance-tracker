import Foundation

/// Anything a person can ask "what's the answer here?" about (PRODUCT.md §4.1).
/// Every report, watch and verification attaches to one.
nonisolated struct Place: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var kind: Kind
    /// Proper noun as people say it ("Puma Los Filtros", "PR-52").
    var name: String
    var municipio: String
    var barrio: String?
    var region: Region
    var geometry: Geometry
    /// Station brand from the directory, never from OCR.
    var brand: String?
    /// A verified owner holds this place, so their status is its answer (§4.5).
    var hasVerifiedOwner: Bool = false
    /// A charger's ports, from the directory (§6.7).
    var ports: [ChargerPort] = []
    /// The phone shown on the map; owner verification calls it (open decision 22).
    var publicPhone: String?

    nonisolated enum Kind: String, CaseIterable, Codable, Hashable, Sendable {
        case station
        case charger
        case business
        case roadSegment
        case area
    }

    /// The point pins and distance use: the point itself, a line's midpoint
    /// vertex or a polygon's vertex centroid.
    var anchor: GeoPoint { geometry.anchor }

    /// The name people say: an area goes by its barrio, everything else by its own name.
    var displayName: String {
        kind == .area ? (barrio ?? name) : name
    }
}

extension Place.Kind {
    /// The layer whose mark stands for a place with no current answer.
    nonisolated var layer: Layer {
        switch self {
        case .station: .gas
        case .charger: .chargers
        case .business: .businesses
        case .roadSegment: .roads
        case .area: .power
        }
    }
}

/// One kind of plug on a charger: "CCS1 · 50 kW", two of them.
nonisolated struct ChargerPort: Codable, Hashable, Sendable {
    var connector: Connector
    var kilowatts: Int
    var count: Int = 1
}

/// A WGS84 coordinate. Kept free of CoreLocation so the model stays pure.
nonisolated struct GeoPoint: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    init(_ latitude: Double, _ longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

nonisolated enum Geometry: Codable, Hashable, Sendable {
    case point(GeoPoint)
    case line([GeoPoint])
    case polygon([GeoPoint])

    var anchor: GeoPoint {
        switch self {
        case .point(let point):
            return point
        case .line(let points):
            return points[points.count / 2]
        case .polygon(let ring):
            let count = Double(ring.count)
            return GeoPoint(
                ring.map(\.latitude).reduce(0, +) / count,
                ring.map(\.longitude).reduce(0, +) / count
            )
        }
    }
}

/// Island regions used to spread sample coverage and, later, crisis scopes.
nonisolated enum Region: String, CaseIterable, Codable, Hashable, Sendable {
    case metro
    case central
    case west
    case north
    case south
    case east
}
