import Foundation

extension PuertoRico {
    /// The island's 78 municipios, as they are written. Siri resolves a
    /// municipio against this list even where the map has no place yet.
    nonisolated static let municipios: [String] = [
        "Adjuntas", "Aguada", "Aguadilla", "Aguas Buenas", "Aibonito", "Añasco",
        "Arecibo", "Arroyo", "Barceloneta", "Barranquitas", "Bayamón", "Cabo Rojo",
        "Caguas", "Camuy", "Canóvanas", "Carolina", "Cataño", "Cayey",
        "Ceiba", "Ciales", "Cidra", "Coamo", "Comerío", "Corozal",
        "Culebra", "Dorado", "Fajardo", "Florida", "Guánica", "Guayama",
        "Guayanilla", "Guaynabo", "Gurabo", "Hatillo", "Hormigueros", "Humacao",
        "Isabela", "Jayuya", "Juana Díaz", "Juncos", "Lajas", "Lares",
        "Las Marías", "Las Piedras", "Loíza", "Luquillo", "Manatí", "Maricao",
        "Maunabo", "Mayagüez", "Moca", "Morovis", "Naguabo", "Naranjito",
        "Orocovis", "Patillas", "Peñuelas", "Ponce", "Quebradillas", "Rincón",
        "Río Grande", "Sabana Grande", "Salinas", "San Germán", "San Juan", "San Lorenzo",
        "San Sebastián", "Santa Isabel", "Toa Alta", "Toa Baja", "Trujillo Alto", "Utuado",
        "Vega Alta", "Vega Baja", "Vieques", "Villalba", "Yabucoa", "Yauco"
    ]

    /// The municipio a name means, ignoring case and accents ("mayaguez").
    nonisolated static func municipio(named name: String) -> String? {
        let folded = PlaceSearch.fold(name.trimmingCharacters(in: .whitespacesAndNewlines))
        return municipios.first { PlaceSearch.fold($0) == folded }
    }
}
