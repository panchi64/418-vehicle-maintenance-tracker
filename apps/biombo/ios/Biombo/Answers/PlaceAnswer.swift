import Foundation

/// A place's one current answer on one layer (PRODUCT.md §3.1), with the
/// trust it carries. Stale answers exist only behind "Ver reportes anteriores".
nonisolated struct PlaceAnswer: Identifiable, Hashable, Sendable {
    let place: Place
    let layer: Layer
    /// The report that states the answer. For a median price, the newest report in the median.
    let lead: Report
    let value: AnswerValue
    let label: VerificationLabel
    let freshness: Freshness
    let dispute: DisputeState

    /// One pin and one row per place and layer; stale answers are keyed by report.
    var id: String {
        freshness.isCurrent ? Self.currentID(place: place.id, layer: layer) : "stale#\(lead.id.uuidString)"
    }

    /// The id of a place's current answer on a layer, which pins and selection share.
    static func currentID(place: Place.ID, layer: Layer) -> String {
        "\(place)#\(layer.rawValue)"
    }

    var kind: ReportKind { lead.kind }
    /// When the answer was last stated or confirmed.
    var asOf: Date { lead.freshnessAnchor }
    var anchor: GeoPoint { place.anchor }

    /// The price, when the answer is one.
    var price: FuelPrice? {
        if case .price(let price) = value { price } else { nil }
    }
}

/// What an answer says: a pump price or a reported status.
nonisolated enum AnswerValue: Hashable, Sendable {
    case price(FuelPrice)
    case status(ReportKind)
}

/// An outage area that is current and drawable, with its label and trust (§7).
nonisolated struct AreaStatus: Identifiable, Hashable, Sendable {
    let area: OutageArea
    let label: VerificationLabel
    let confidence: AreaConfidence?
    let freshness: Freshness
    /// The neighbours-only part past an official outline; nil below 3 devices,
    /// when it isn't drawn.
    var extensionConfidence: AreaConfidence?

    var id: String { area.id }
    var layer: Layer { area.layer }
    var anchor: GeoPoint { GeoPoint.centroid(of: area.polygon) ?? GeoPoint(0, 0) }
    /// The barrio people say, or the municipio when none is named.
    var placeName: String { area.barrios.first ?? area.municipio }

    /// Official or community-confirmed: what municipio zoom draws (§7 "By zoom").
    var isEstablished: Bool { label.holdsOutageOpen }

    /// The drawable neighbours-only part and its centroid, for its own tag.
    var drawnExtension: (polygon: [GeoPoint], anchor: GeoPoint)? {
        guard extensionConfidence != nil, let part = area.communityExtension,
              let anchor = GeoPoint.centroid(of: part.polygon) else { return nil }
        return (part.polygon, anchor)
    }
}
