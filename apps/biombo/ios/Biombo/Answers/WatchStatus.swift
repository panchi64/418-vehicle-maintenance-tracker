import Foundation

/// One confirmed change at a watched place (PRODUCT.md §9). Only what could
/// notify counts: Sin verificar is never news here, and prices never are.
nonisolated enum WatchNews: Hashable, Sendable {
    /// An NWS warning covering the place.
    case warning(OfficialNotice)
    /// A confirmed or official power or water area over the place's barrio.
    case outage(AreaStatus)
    /// An active AAA boil-water notice for the municipio.
    case boilWater(OfficialNotice)
    /// A confirmed road problem within reach.
    case road(PlaceAnswer, distance: Double)
}

/// A watched place and what changed there, most urgent first; no news reads "Todo normal".
nonisolated struct WatchStatus: Identifiable, Hashable, Sendable {
    let place: WatchedPlace
    let news: [WatchNews]

    var id: WatchedPlace.ID { place.id }
    var isNormal: Bool { news.isEmpty }
}

/// Answers every watched place from the same gated digest the map reads.
nonisolated struct WatchStatusBuilder: Sendable {
    /// "Carreteras cerca": problems within this distance (§9).
    var roadRadius: Double = 2_000

    func statuses(for places: [WatchedPlace], digest: HomeDigest) -> [WatchStatus] {
        places.map { WatchStatus(place: $0, news: news(for: $0, digest: digest)) }
    }

    /// The list as it reads: a warning that covers every watched place is
    /// said once above them, not repeated on each (§3 "Say each fact once").
    func overview(for places: [WatchedPlace], digest: HomeDigest) -> WatchOverview {
        let statuses = statuses(for: places, digest: digest)
        guard statuses.count > 1 else { return WatchOverview(sharedWarnings: [], statuses: statuses) }
        let shared = digest.notices.filter { notice in
            notice.kind == .weatherWarning && statuses.allSatisfy { $0.news.contains(.warning(notice)) }
        }
        let rest = statuses.map { status in
            WatchStatus(place: status.place, news: status.news.filter { news in
                if case .warning(let notice) = news { !shared.contains(notice) } else { true }
            })
        }
        return WatchOverview(sharedWarnings: shared, statuses: rest)
    }

    func news(for place: WatchedPlace, digest: HomeDigest) -> [WatchNews] {
        // A warning covering the place is always news, whatever layers are on.
        var news = digest.notices
            .filter { $0.kind == .weatherWarning && covers($0, place) }
            .map(WatchNews.warning)
        news += digest.areas
            .filter { place.layers.contains($0.layer) && $0.label.canNotify && covers($0, place) }
            .sorted { $0.area.openedAt < $1.area.openedAt }
            .map(WatchNews.outage)
        if place.layers.contains(.water) {
            news += digest.notices
                .filter { $0.kind == .boilWater && covers($0, place) }
                .map(WatchNews.boilWater)
        }
        if place.layers.contains(.roads) {
            news += digest.answers
                .filter { $0.layer == .roads && $0.kind != .reopened && $0.label.canNotify }
                .map { ($0, place.location.distance(to: $0.anchor)) }
                .filter { $0.1 <= roadRadius }
                .sorted { $0.1 < $1.1 }
                .map { WatchNews.road($0.0, distance: $0.1) }
        }
        return news
    }

    /// The neighbours-only barrios past an official outline count only while
    /// that part is drawn (3 phones or more), so a watch never hears the
    /// agency's label for a barrio one or two neighbours named.
    private func covers(_ status: AreaStatus, _ place: WatchedPlace) -> Bool {
        let area = status.area
        guard area.municipio == place.municipio else { return false }
        guard let barrio = place.barrio else { return true }
        let barrios = status.extensionConfidence != nil ? area.allBarrios : area.barrios
        return barrios.contains(barrio)
    }

    private func covers(_ notice: OfficialNotice, _ place: WatchedPlace) -> Bool {
        notice.municipios.isEmpty || notice.municipios.contains(place.municipio)
    }
}

/// Every watched place's status, with warnings they all share lifted out.
nonisolated struct WatchOverview: Hashable, Sendable {
    let sharedWarnings: [OfficialNotice]
    let statuses: [WatchStatus]

    var summary: WatchSummary { WatchSummary(statuses, hasSharedWarning: !sharedWarnings.isEmpty) }
}

/// The watch list's answer: which places have news, and how many are fine.
nonisolated struct WatchSummary: Hashable, Sendable {
    /// Names with news, in list order.
    let withNews: [String]
    let normalCount: Int
    /// A warning covers them all, so a quiet place is "sin otros cambios", never "todo normal".
    let hasSharedWarning: Bool

    init(_ statuses: [WatchStatus], hasSharedWarning: Bool = false) {
        withNews = statuses.filter { !$0.isNormal }.map(\.place.name)
        normalCount = statuses.filter(\.isNormal).count
        self.hasSharedWarning = hasSharedWarning
    }

    var isEmpty: Bool { withNews.isEmpty && normalCount == 0 }
}
