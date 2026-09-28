import Foundation

/// Everything a place's or area's detail sheet says, derived once per
/// selection (PRODUCT.md §3 tiers, §6 per layer). The answer comes first;
/// each layer adds its one comparison and what makes it complete in depth.
nonisolated struct PlaceDetail: Hashable, Sendable {
    enum Subject: Hashable, Sendable {
        case place(Place)
        case area(AreaStatus)
    }

    let subject: Subject
    let layer: Layer
    /// Metres from where "cerca" is measured.
    let distance: Double
    let now: Date

    /// The place's one current answer on this layer; nil is the empty state.
    let answer: PlaceAnswer?
    /// Older reports, newest first, behind "Ver reportes anteriores (N)".
    let stale: [PlaceAnswer]
    /// Every current report on this layer, newest first (depth). An area
    /// carries the reports filed on its barrio.
    let evidence: [PlaceAnswer]
    /// Boil-water notices, which sit directly under the answer (§6.3).
    let boilNotices: [OfficialNotice]
    /// The other active official items for this layer and municipio, one card per agency.
    let otherNotices: [AgencyNotices]
    let question: ConfirmQuestion?
    /// Within reach to vote (§4.3); otherwise the replies are disabled.
    let canConfirm: Bool

    // Gas (§6.1)
    let ladder: PriceLadder?
    /// DACO's reference for a station with no current price, so the empty
    /// state still says what a fair price is (Flows-StaleState).
    let reference: PriceLadder.Reference?
    let trend: PriceTrend?
    /// Current prices for the other grades.
    let otherGrades: [FuelPrice]
    /// DACO's island range today across brands, for a station: what "What
    /// is DACO?" quotes to a visitor.
    let dacoRange: DacoRange?
    /// Other current statuses at the station ("Hay fila", "Solo efectivo").
    let alsoReported: [PlaceAnswer]

    // Outage areas (§7)
    /// Who says it is out, barrio by barrio; nil for a place.
    let sourceMix: SourceMix?
    /// "¿Cómo ha ido?" in depth; nil for a place.
    let timeline: AreaTimeline?

    // Roads (§6.6)
    /// An active closure for this stretch; without one the answer is
    /// followed by "Todavía no hay aviso oficial para este tramo."
    let hasRoadNotice: Bool

    // Water (§6.3)
    /// Current water distribution points in the municipio.
    let waterPoints: [PlaceAnswer]

    // Chargers (§6.7)
    let reliability: ChargerReliability?
    let tally: ChargerTally?
    let ports: [PortStatus]

    // Businesses (§6.8)
    let events: [OwnerEvent]
    let products: [String]
    let neighbours: [NeighbourCount]

    var place: Place? {
        if case .place(let place) = subject { place } else { nil }
    }

    var area: AreaStatus? {
        if case .area(let status) = subject { status } else { nil }
    }

    var name: String {
        switch subject {
        case .place(let place): place.displayName
        case .area(let status): status.placeName
        }
    }

    var municipio: String {
        switch subject {
        case .place(let place): place.municipio
        case .area(let status): status.area.municipio
        }
    }

    var region: Region {
        switch subject {
        case .place(let place): place.region
        case .area(let status): status.area.region
        }
    }

    var anchor: GeoPoint {
        switch subject {
        case .place(let place): place.anchor
        case .area(let status): status.anchor
        }
    }

    /// Nothing current here: one sentence and one verb (§3).
    var isEmpty: Bool { answer == nil && area == nil }

    /// Stations, chargers and businesses hand off to a maps app (§3 verbs).
    var offersDirections: Bool {
        guard let place else { return false }
        return [.station, .charger, .business].contains(place.kind)
    }

    /// Every flood item always says "No cruces carreteras inundadas." (§6.6).
    var isFlood: Bool { answer?.kind == .flooded }

    /// A downed line whose answer it is says to stay away and call 911 (§6.2
    /// safety). An outage area's answer is the outage, so it never does.
    var isLineDown: Bool { answer?.kind == .lineDown }

    /// A road segment no official closure covers says so under its answer,
    /// since official lists rarely retract closures (§6.6).
    var lacksRoadNotice: Bool { layer == .roads && place?.kind == .roadSegment && !hasRoadNotice }

    /// What the verified owner posted, apart from what neighbours say.
    var ownerReports: [PlaceAnswer] { evidence.filter { $0.lead.source == .owner } }
    var communityReports: [PlaceAnswer] { evidence.filter { $0.lead.source != .owner } }

    /// Neighbours' reports shown in full before the rest are left to depth (*proposed*).
    nonisolated static let fullReportCap = 3

    /// Outages, water, signal and roads list neighbours' reports in full
    /// (§6.2–§6.6), leaving out distribution points, which have their own
    /// section, and the report the answer already states.
    var neighbourReports: [PlaceAnswer] {
        guard [.power, .water, .signal, .roads].contains(layer) else { return [] }
        return communityReports.filter { !waterPoints.contains($0) && $0.lead.id != answer?.lead.id }
    }

    /// The neighbour rows the full tier shows.
    var fullNeighbourReports: [PlaceAnswer] { Array(neighbourReports.prefix(Self.fullReportCap)) }

    /// Depth's community reports: what the full tier didn't already list.
    var depthCommunityReports: [PlaceAnswer] {
        let shown = Set(fullNeighbourReports.map(\.lead.id))
        return communityReports.filter { !shown.contains($0.lead.id) }
    }

    var listsNeighbourReports: Bool { !neighbourReports.isEmpty }

    /// Whether the full tier has anything past the summary, so an empty
    /// block never leaves a gap.
    var hasFullSections: Bool {
        ladder != nil || !otherGrades.isEmpty || !alsoReported.isEmpty || !ports.isEmpty
            || !events.isEmpty || !products.isEmpty || !neighbours.isEmpty
            || area != nil || listsNeighbourReports || !waterPoints.isEmpty
    }
}
