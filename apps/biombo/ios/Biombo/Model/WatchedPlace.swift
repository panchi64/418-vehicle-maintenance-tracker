import Foundation

/// A place the user watches ("Casa de Mamá"), stored on the device only (PRODUCT.md §9).
/// Its answer is the combined status of the areas and roads around it (§4.1).
nonisolated struct WatchedPlace: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    /// User-given name, shown in serif on its postcard.
    var name: String
    var location: GeoPoint
    var municipio: String
    var barrio: String?
    var layers: Set<Layer>
    /// Set when the watch targets a specific station, charger or business.
    var placeID: Place.ID?

    init(
        id: UUID = UUID(),
        name: String,
        location: GeoPoint,
        municipio: String,
        barrio: String? = nil,
        layers: Set<Layer> = Self.defaultLayers,
        placeID: Place.ID? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.municipio = municipio
        self.barrio = barrio
        self.layers = layers
        self.placeID = placeID
    }

    /// Luz, Agua and Carreteras cerca are on by default (§9).
    nonisolated static let defaultLayers: Set<Layer> = Set(Layer.allCases.filter(\.isWatchedByDefault))
    /// Up to 10 places per device (*proposed*).
    nonisolated static let limit = 10
}

/// Quiet hours (§9): from 10 p.m. to 7 a.m. in the device's own time zone,
/// on by default; only time-sensitive official items break through (*proposed*).
nonisolated enum QuietHours {
    static let start = 22
    static let end = 7
}
