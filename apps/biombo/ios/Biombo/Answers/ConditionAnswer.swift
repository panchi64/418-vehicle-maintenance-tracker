import Foundation

/// "¿Hay luz en Caguas?" (PRODUCT.md §11 `CheckConditionIntent`): one answer
/// per service and municipio, from the current outage areas only, so stale
/// data is never spoken as current. An aging area is said age first.
nonisolated enum ConditionAnswer: Hashable, Sendable {
    /// Out, and the evidence is fresh.
    case out(AreaStatus)
    /// Out, but the last evidence is old: said with its age first.
    case aging(AreaStatus)
    /// Coming back in parts.
    case restoring(AreaStatus)
    /// Nothing current: "No hay reportes recientes de luz en Caguas."
    case noRecent

    /// The one area that speaks for the municipio: an outage over a
    /// restoring one, Oficial or Confirmado over Sin verificar, fresh over
    /// aging, then the oldest.
    static func make(service: Layer, municipio: String, areas: [AreaStatus]) -> ConditionAnswer {
        let lead = areas
            .filter { $0.layer == service && PlaceSearch.fold($0.area.municipio) == PlaceSearch.fold(municipio) }
            .min { rank($0) < rank($1) }
        guard let lead else { return .noRecent }
        if lead.area.lifecycle == .restoring { return .restoring(lead) }
        return lead.freshness == .aging ? .aging(lead) : .out(lead)
    }

    /// The area this answer is about, if any.
    var status: AreaStatus? {
        switch self {
        case .out(let status), .aging(let status), .restoring(let status): status
        case .noRecent: nil
        }
    }

    private static func rank(_ status: AreaStatus) -> (Int, Int, Int, Date) {
        (
            status.area.lifecycle == .restoring ? 1 : 0,
            status.isEstablished ? 0 : 1,
            status.freshness == .fresh ? 0 : 1,
            status.area.openedAt
        )
    }
}

extension PlacesSnapshot {
    /// The municipio of the place nearest `point`: where "¿Hay luz?" asks
    /// about when no municipio is said.
    nonisolated func municipio(nearest point: GeoPoint) -> String? {
        places.min { point.distance(to: $0.anchor) < point.distance(to: $1.anchor) }?.municipio
    }
}
