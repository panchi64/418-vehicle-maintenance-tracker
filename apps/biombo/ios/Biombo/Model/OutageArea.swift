import Foundation

/// A reconciled affected area for power, water or signal (PRODUCT.md §7).
/// Community and official evidence stay separate inside it; nothing is averaged.
nonisolated struct OutageArea: Identifiable, Codable, Hashable, Sendable {
    /// Persists across splits and merges so watches and history stay attached.
    let id: String
    let layer: Layer
    /// Signal areas are per carrier (§6.4).
    var carrier: Carrier?
    var municipio: String
    var barrios: [String]
    var region: Region
    var polygon: [GeoPoint]
    var lifecycle: Lifecycle
    /// Set when an official area (LUMA sectors or feeders, AAA zones, an authority entry) is part of it.
    var officialAgency: Agency?
    var evidence: Evidence
    var openedAt: Date
    /// The newest report or feed update behind the area.
    var latestEvidenceAt: Date
    /// An official estimate only; a community estimate is never a restore time (§11).
    var estimatedRestore: DateInterval?
    /// A planned or load-shed outage, named as such (§6.2).
    var isPlanned: Bool = false
    /// When the agency first said so, for the timeline in depth.
    var officialSince: Date?
    /// Where neighbours report the outage past the official outline (§7
    /// reconciliation 5): one area, each part with its own label.
    var communityExtension: CommunityExtension?

    /// The part of an official area only neighbours report.
    nonisolated struct CommunityExtension: Codable, Hashable, Sendable {
        var barrios: [String]
        var polygon: [GeoPoint]
        var distinctDevices: Int
    }

    nonisolated enum Lifecycle: String, Codable, Hashable, Sendable {
        case open
        case confirmed
        case restoring
        case closed
    }

    /// What the confidence and label rules read.
    nonisolated struct Evidence: Codable, Hashable, Sendable {
        var distinctDevices: Int
        /// Share of "Ya no" / "Volvió" weight, 0...1.
        var disputeShare: Double
        /// Inside an official hazard area (an NWS warning, say), which lowers the Media bar.
        var insideOfficialHazard: Bool = false
        /// Official geometry agrees with the community cluster ("Coincide con LUMA").
        var matchesOfficial: Bool = false
    }

    var isOfficial: Bool { officialAgency != nil }

    /// Every barrio the area reaches: the outline's, then the neighbours' extension.
    var allBarrios: [String] { barrios + (communityExtension?.barrios ?? []) }

    /// Whether `place` is one of this area's barrios, so its reports are the area's evidence.
    func covers(_ place: Place) -> Bool {
        guard place.kind == .area, place.municipio == municipio, let barrio = place.barrio else { return false }
        return allBarrios.contains(barrio)
    }
}

/// Polygon confidence, shown in depth only and always in words (§7).
nonisolated enum AreaConfidence: String, Codable, Hashable, Sendable, Comparable {
    case low
    case medium
    case high

    private var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}
