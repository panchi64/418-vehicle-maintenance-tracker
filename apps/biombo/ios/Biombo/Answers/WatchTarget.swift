import Foundation

/// What "Vigilar" on a detail watches (PRODUCT.md §9): the station, charger
/// or business itself, or for an outage area the barrio it is named for, so
/// the watch outlives the outage.
nonisolated extension PlaceDetail {
    /// The place a watch targets, found in `places`.
    func watchTarget(in places: [Place]) -> Place? {
        switch subject {
        case .place(let place):
            return place
        case .area(let status):
            return places.first { status.area.covers($0) && $0.barrio == status.placeName }
                ?? places.first(where: status.area.covers)
        }
    }

    /// A new watch on this detail's place.
    func watchDraft(in places: [Place]) -> WatchedPlace? {
        watchTarget(in: places).map(WatchedPlace.draft(for:))
    }
}

nonisolated extension WatchedPlace {
    /// A new watch on a place, named for it and with the default layers;
    /// the user renames it in setup ("Casa de Mamá").
    static func draft(for place: Place) -> WatchedPlace {
        WatchedPlace(
            name: place.displayName,
            location: place.anchor,
            municipio: place.municipio,
            barrio: place.barrio,
            placeID: place.id
        )
    }

    /// A new watch on a whole municipio, picked from search.
    static func draft(municipio: String, at anchor: GeoPoint) -> WatchedPlace {
        WatchedPlace(name: municipio, location: anchor, municipio: municipio)
    }
}
