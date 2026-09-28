import Foundation

/// A pin, or several same-layer pins too close to tell apart at this zoom.
nonisolated enum MapMark: Identifiable, Hashable, Sendable {
    case pin(PlaceAnswer)
    case cluster(PinCluster)

    var id: String {
        switch self {
        case .pin(let answer): answer.id
        case .cluster(let cluster): cluster.id
        }
    }

    var layer: Layer {
        switch self {
        case .pin(let answer): answer.layer
        case .cluster(let cluster): cluster.layer
        }
    }

    var anchor: GeoPoint {
        switch self {
        case .pin(let answer): answer.anchor
        case .cluster(let cluster): cluster.anchor
        }
    }
}

nonisolated struct PinCluster: Identifiable, Hashable, Sendable {
    let layer: Layer
    let members: [PlaceAnswer]
    let anchor: GeoPoint

    var id: String { "cluster#\(layer.rawValue)#" + members.map(\.id).sorted().joined(separator: ",") }

    /// The latitude and longitude spans that frame every member, for zooming in.
    var span: (latitude: Double, longitude: Double) {
        let lats = members.map(\.anchor.latitude)
        let lons = members.map(\.anchor.longitude)
        return ((lats.max()! - lats.min()!), (lons.max()! - lons.min()!))
    }
}

/// Distance clustering in map space. MapKit's SwiftUI `Map` has no clustering,
/// so same-layer pins within one cell's reach of a cluster's first pin merge
/// into one counted mark. Distance, not a fixed grid, so two pins either side
/// of a grid line still merge. Layers never merge with each other, so a
/// cluster keeps its pin shape (never colour alone).
nonisolated struct PinClusterer: Sendable {
    /// Cells across the visible span (*proposed*; about a pin's width
    /// plus its label on an iPhone in portrait).
    var columns = 7.0
    var rows = 12.0

    func marks(for pins: [PlaceAnswer], latitudeDelta: Double, longitudeDelta: Double) -> [MapMark] {
        let reachLat = max(latitudeDelta / rows, 1e-6)
        let reachLon = max(longitudeDelta / columns, 1e-6)
        var groups: [[PlaceAnswer]] = []
        for pin in pins.sorted(by: { $0.id < $1.id }) {
            let index = groups.firstIndex { group in
                let seed = group[0]
                return seed.layer == pin.layer
                    && abs(seed.anchor.latitude - pin.anchor.latitude) < reachLat
                    && abs(seed.anchor.longitude - pin.anchor.longitude) < reachLon
            }
            if let index {
                groups[index].append(pin)
            } else {
                groups.append([pin])
            }
        }
        return groups.map { members -> MapMark in
            guard members.count > 1, let anchor = GeoPoint.centroid(of: members.map(\.anchor)) else {
                return .pin(members[0])
            }
            return .cluster(PinCluster(layer: members[0].layer, members: members, anchor: anchor))
        }
        .sorted { $0.id < $1.id }
    }
}
