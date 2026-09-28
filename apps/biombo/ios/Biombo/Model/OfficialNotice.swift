import Foundation

/// One official item: a card per agency, one sentence plus agency · time,
/// with a guidance line only when actionable (PRODUCT.md §3).
nonisolated struct OfficialNotice: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var agency: Agency
    var kind: Kind
    var layer: Layer
    /// The agency's sentence, entered in the language it was published in.
    var headline: String
    /// "Hierve el agua 3 minutos" — only when there is something to do.
    var guidance: String?
    var municipios: [String]
    var area: [GeoPoint]?
    var issuedAt: Date
    var updatedAt: Date
    /// Dashboard notices carry a mandatory expiry (§12); feed items may not.
    var expiresAt: Date?
    /// Ingested feeds age by feed lateness; hand entries by days without update (§4.4).
    var isFeed: Bool
    /// Staff transcriptions say so, with the release time (§4.5).
    var isStaffTranscription: Bool = false
    /// The places the notice is about (a closed road segment); empty when it
    /// speaks for whole municipios.
    var placeIDs: [Place.ID] = []

    nonisolated enum Kind: String, Codable, Hashable, Sendable {
        case boilWater
        case waterInterruptionPlan
        case roadClosure
        case weatherWarning
        case priceFreeze
        case shelter
        case distributionPoint
    }

    func isActive(at now: Date) -> Bool {
        issuedAt <= now && (expiresAt.map { now < $0 } ?? true)
    }
}

/// DACO's one estimated pump price per brand, grade and day, island-wide.
/// Always "la referencia de DACO", never a legal price (§6.1).
nonisolated struct DacoReference: Codable, Hashable, Sendable {
    var brand: String
    var price: FuelPrice
    var publishedOn: Date

    /// The reference drops out of every answer past this age (*proposed*, §6.1).
    nonisolated static let maxAge: TimeInterval = .days(3)

    func isCurrent(at now: Date) -> Bool {
        now.timeIntervalSince(publishedOn) < Self.maxAge
    }
}
