import Foundation

/// One observation about one place on one layer (PRODUCT.md §4.2).
/// The reporter is never part of the public model.
nonisolated struct Report: Identifiable, Codable, Hashable, Sendable {
    /// The client id, which doubles as the idempotency key.
    let id: UUID
    let kind: ReportKind
    var value: ReportValue?
    let placeID: Place.ID
    let capturedAt: Date
    /// The latest "Sigue igual", which restarts the freshness clock (§4.3, §4.4).
    var lastConfirmedAt: Date?
    var channel: Channel
    let source: Source
    var votes: Votes
    /// Owner posts can state when they end ("Abierto con planta hasta las 8 p. m.").
    var statedEnd: Date?

    init(
        id: UUID = UUID(),
        kind: ReportKind,
        value: ReportValue? = nil,
        placeID: Place.ID,
        capturedAt: Date,
        lastConfirmedAt: Date? = nil,
        channel: Channel = .tap,
        source: Source = .community,
        votes: Votes = Votes(),
        statedEnd: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.value = value
        self.placeID = placeID
        self.capturedAt = capturedAt
        self.lastConfirmedAt = lastConfirmedAt
        self.channel = channel
        self.source = source
        self.votes = votes
        self.statedEnd = statedEnd
    }

    var layer: Layer { kind.layer }

    /// Freshness counts from the latest of capture or the last "Sigue igual" (§4.4).
    var freshnessAnchor: Date {
        max(capturedAt, lastConfirmedAt ?? capturedAt)
    }
}

/// The optional value a report carries.
nonisolated enum ReportValue: Codable, Hashable, Sendable {
    case price(FuelPrice)
    case carrier(Carrier)
    case queueMinutes(Int)
    case connector(Connector)
    /// Owner free text (a product, an event title). Owner posts only (§5).
    case ownerText(String)
    /// An owner's event: title, start and end (§6.8).
    case event(OwnerEvent)
}

/// "Noche de bomba y plena", Saturday 8 to 11 p.m. Owner posts only.
nonisolated struct OwnerEvent: Codable, Hashable, Sendable {
    var title: String
    var start: Date
    var end: Date
}

/// Sigue igual / Ya no tallies on a report (§4.3). Weights are reputation-weighted
/// and exclude the author; counts are distinct voters.
nonisolated struct Votes: Codable, Hashable, Sendable {
    var confirmWeight: Double = 0
    var disputeWeight: Double = 0
    var confirmCount: Int = 0
    var disputeCount: Int = 0

    var total: Int { confirmCount + disputeCount }
}

nonisolated enum FuelGrade: String, CaseIterable, Codable, Hashable, Sendable {
    case regular
    case premium
    case diesel
}

/// A pump price. Stored in ¢/L, DACO's unit, and converted before rounding (§4.2).
nonisolated struct FuelPrice: Codable, Hashable, Sendable {
    var grade: FuelGrade
    var centsPerLitre: Double

    nonisolated static let litresPerGallon = 3.78541

    var centsPerGallon: Double { centsPerLitre * Self.litresPerGallon }
}

extension Report {
    /// The price this report states, if it is one.
    nonisolated var price: FuelPrice? {
        if case .price(let price) = value { price } else { nil }
    }

    nonisolated var connector: Connector? {
        if case .connector(let connector) = value { connector } else { nil }
    }
}

nonisolated enum Carrier: String, CaseIterable, Codable, Hashable, Sendable {
    case claro
    case liberty
    case tMobile
    case att

    /// Carriers are proper names in both languages, so this is not localized.
    var displayName: String {
        switch self {
        case .claro: "Claro"
        case .liberty: "Liberty"
        case .tMobile: "T-Mobile"
        case .att: "AT&T"
        }
    }
}

nonisolated enum Connector: String, CaseIterable, Codable, Hashable, Sendable {
    case j1772
    case ccs1
    case nacs
    case chademo
}
