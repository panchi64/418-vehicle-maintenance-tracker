import Foundation

nonisolated extension GeoPoint {
    /// Mean Earth radius in metres, for haversine distances.
    private static let earthRadius = 6_371_000.0

    /// Great-circle distance in metres.
    func distance(to other: GeoPoint) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * Self.earthRadius * atan2(a.squareRoot(), (1 - a).squareRoot())
    }

    /// Whether this point falls inside a ring (even-odd rule; fine at barrio scale).
    func isInside(_ ring: [GeoPoint]) -> Bool {
        guard ring.count >= 3 else { return false }
        var inside = false
        var j = ring.count - 1
        for i in ring.indices {
            let a = ring[i], b = ring[j]
            if (a.latitude > latitude) != (b.latitude > latitude),
               longitude < (b.longitude - a.longitude) * (latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    /// Metres to a place's geometry: zero inside an area, the nearest
    /// vertex of a line, the point itself otherwise.
    func distance(to geometry: Geometry) -> Double {
        switch geometry {
        case .point(let point): distance(to: point)
        case .line(let points): points.map(distance(to:)).min() ?? .infinity
        case .polygon(let ring): isInside(ring) ? 0 : (ring.map(distance(to:)).min() ?? .infinity)
        }
    }

    /// The vertex centroid of a set of points; nil when empty.
    static func centroid(of points: [GeoPoint]) -> GeoPoint? {
        guard !points.isEmpty else { return nil }
        let count = Double(points.count)
        return GeoPoint(
            points.map(\.latitude).reduce(0, +) / count,
            points.map(\.longitude).reduce(0, +) / count
        )
    }
}

/// The island's clock. Clock times ("desde las 3:10 p. m.") are always Puerto
/// Rico time, so a diaspora user reads the same time their family does.
nonisolated enum PuertoRico {
    nonisolated static let timeZone = TimeZone(identifier: "America/Puerto_Rico")!

    nonisolated static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()
}
