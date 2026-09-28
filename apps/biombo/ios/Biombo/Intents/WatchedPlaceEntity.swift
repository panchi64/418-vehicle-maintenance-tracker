import AppIntents
import Foundation

/// A place this device watches ("Casa de Mamá"), for "¿Cómo está Casa de
/// Mamá?" and as a saved place to report from. A snapshot of the watch;
/// the watch list itself stays on the device (§9).
struct WatchedPlaceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Lugar vigilado" }
    static var defaultQuery: WatchedPlaceQuery { WatchedPlaceQuery() }

    let id: UUID
    let name: String
    let municipio: String

    init(_ place: WatchedPlace) {
        id = place.id
        name = place.name
        municipio = place.municipio
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(municipio)")
    }
}

struct WatchedPlaceQuery: EntityStringQuery {
    @Dependency var context: IntentContext

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [WatchedPlaceEntity] {
        context.watches.places.filter { identifiers.contains($0.id) }.map(WatchedPlaceEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [WatchedPlaceEntity] {
        let needle = PlaceSearch.fold(string)
        return context.watches.places
            .filter { PlaceSearch.fold($0.name).contains(needle) || PlaceSearch.fold($0.municipio).contains(needle) }
            .map(WatchedPlaceEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [WatchedPlaceEntity] {
        context.watches.places.map(WatchedPlaceEntity.init)
    }
}
