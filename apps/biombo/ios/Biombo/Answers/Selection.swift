import Foundation

/// What the sheet is answering for besides the area: a place on one layer,
/// or an outage area. A place with no current answer can still be selected
/// (from search or an older report), so its empty state can say what to do.
nonisolated enum Selection: Hashable, Sendable {
    case place(Place.ID, Layer)
    case area(OutageArea.ID, Layer)

    var layer: Layer {
        switch self {
        case .place(_, let layer), .area(_, let layer): layer
        }
    }

    /// The id the map's pin or area carries, so it can draw as selected.
    var mapID: String {
        switch self {
        case .place(let id, let layer): PlaceAnswer.currentID(place: id, layer: layer)
        case .area(let id, _): id
        }
    }
}

extension NearbyItem {
    /// Selecting a row or pin; an older report selects its place.
    nonisolated var selection: Selection {
        switch self {
        case .place(let answer): .place(answer.place.id, answer.layer)
        case .area(let status): .area(status.id, status.layer)
        }
    }
}
