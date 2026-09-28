import AppIntents
import Foundation

/// Something to start watching, found the way the sheet's search finds it:
/// a municipio or a place (a barrio, a station, a business). Its id is the
/// search result's.
struct WatchTargetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Lugar" }
    static var defaultQuery: WatchTargetQuery { WatchTargetQuery() }

    let id: String
    let title: String
    let subtitle: String
    /// The watch it starts, with the default layers (§9).
    let draft: WatchedPlace

    init(_ result: PlaceSearch.Result) {
        id = result.id
        switch result {
        case .municipio(let name, let anchor):
            title = name
            subtitle = ""
            draft = .draft(municipio: name, at: anchor)
        case .place(let place):
            title = place.displayName
            subtitle = place.municipio
            draft = .draft(for: place)
        }
    }

    var displayRepresentation: DisplayRepresentation {
        subtitle.isEmpty
            ? DisplayRepresentation(title: "\(title)")
            : DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct WatchTargetQuery: EntityStringQuery {
    @Dependency var context: IntentContext

    func entities(for identifiers: [String]) async throws -> [WatchTargetEntity] {
        guard let snapshot = await context.snapshot() else { return [] }
        return Self.entities(for: identifiers, in: snapshot)
    }

    func entities(matching string: String) async throws -> [WatchTargetEntity] {
        guard let snapshot = await context.snapshot() else { return [] }
        return Self.search(string, in: snapshot)
    }

    func suggestedEntities() async throws -> [WatchTargetEntity] {
        []
    }

    /// A place by its id; a municipio by its search id ("municipio#Caguas"),
    /// found again by searching its name.
    static func entities(for identifiers: [String], in snapshot: PlacesSnapshot) -> [WatchTargetEntity] {
        identifiers.compactMap { id in
            if let place = snapshot.places.first(where: { $0.id == id }) {
                return WatchTargetEntity(.place(place))
            }
            return search(id.replacingOccurrences(of: "municipio#", with: ""), in: snapshot).first { $0.id == id }
        }
    }

    private static func search(_ text: String, in snapshot: PlacesSnapshot) -> [WatchTargetEntity] {
        PlaceSearch().results(for: text, in: snapshot.places, near: snapshot.vantage).map(WatchTargetEntity.init)
    }
}
