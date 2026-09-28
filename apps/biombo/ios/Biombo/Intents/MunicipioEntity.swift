import AppIntents

/// A municipio, for "¿Hay luz en Caguas?". Its id is its written name.
struct MunicipioEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Municipio" }
    static var defaultQuery: MunicipioQuery { MunicipioQuery() }

    let id: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct MunicipioQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [MunicipioEntity] {
        identifiers.compactMap(PuertoRico.municipio(named:)).map(MunicipioEntity.init)
    }

    /// "rio grande" finds Río Grande; word starts first.
    func entities(matching string: String) async throws -> [MunicipioEntity] {
        let needle = PlaceSearch.fold(string.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return PuertoRico.municipios
            .filter { PlaceSearch.fold($0).contains(needle) }
            .sorted { PlaceSearch.fold($0).hasPrefix(needle) && !PlaceSearch.fold($1).hasPrefix(needle) }
            .map(MunicipioEntity.init)
    }

    func suggestedEntities() async throws -> [MunicipioEntity] {
        PuertoRico.municipios.map(MunicipioEntity.init)
    }
}
