import Foundation
import Observation

/// The places this device watches (PRODUCT.md §9). Pure state: the app
/// loads and saves them through `DeviceStorage.watchedPlaces`, and notifications
/// are the view layer's.
@Observable
final class WatchStore {
    private(set) var places: [WatchedPlace]

    init(places: [WatchedPlace] = []) {
        self.places = Array(places.prefix(WatchedPlace.limit))
    }

    var isFull: Bool { places.count >= WatchedPlace.limit }

    /// The watch on a place, found by the place it targets.
    func watch(for placeID: Place.ID) -> WatchedPlace? {
        places.first { $0.placeID == placeID }
    }

    /// The watch already on what `draft` targets: the same place, or for an
    /// area watch, the same municipio and barrio. A station inside a watched
    /// municipio is a watch of its own.
    func existing(like draft: WatchedPlace) -> WatchedPlace? {
        places.first { watch in
            watch.placeID == draft.placeID
                && (draft.placeID != nil || (watch.municipio == draft.municipio && watch.barrio == draft.barrio))
        }
    }

    /// Adds a watch, or replaces the one with the same id. A new watch past
    /// the limit is refused; the result says whether it was kept.
    @discardableResult
    func save(_ place: WatchedPlace) -> Bool {
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            places[index] = place
            return true
        }
        guard !isFull else { return false }
        places.append(place)
        return true
    }

    func remove(_ id: WatchedPlace.ID) {
        places.removeAll { $0.id == id }
    }

    func replaceAll(with places: [WatchedPlace]) {
        self.places = Array(places.prefix(WatchedPlace.limit))
    }
}
