import Foundation

/// The area's answer sentence and its official cards.
nonisolated extension NearbyBuilder {
    /// Crisis: the official warning, then the nearest fuel (§8), which is
    /// "Gasolina y planta"'s own answer so both screens say the same station.
    /// Otherwise utilities first, then roads, then the cheapest gas; two facts at most.
    func facts(from rows: [NearbyRow], notices: [OfficialNotice], isCrisis: Bool, nearestFuel: FuelStop?) -> [AnswerFact] {
        if isCrisis, let warning = notices.filter({ $0.kind == .weatherWarning }).max(by: { $0.updatedAt < $1.updatedAt }) {
            let fuel = nearestFuel.map { AnswerFact.nearestFuel($0.answer, distance: $0.distance) }
            return [.warning(warning)] + [fuel].compactMap { $0 }
        }
        let outage = rows
            .compactMap { row -> (AreaStatus, Double)? in
                if case .area(let status) = row.item { (status, row.distance) } else { nil }
            }
            .min { ($0.0.isEstablished ? 0 : 1, $0.1) < ($1.0.isEstablished ? 0 : 1, $1.1) }
            .map { AnswerFact.outage($0.0) }
        let road = sorted(rows.filter { $0.layer == .roads }, for: .roads)
            .compactMap { row -> PlaceAnswer? in
                if case .place(let answer) = row.item, answer.kind != .reopened { answer } else { nil }
            }
            .first.map(AnswerFact.road)
        let gas = sorted(rows.filter { belongs($0, to: .cheapestGas) }, for: .cheapestGas)
            .compactMap { row -> PlaceAnswer? in
                if case .place(let answer) = row.item { answer } else { nil }
            }
            .first.map(AnswerFact.cheapestGas)
        let facts = [outage ?? road, gas].compactMap { $0 }
        return facts.isEmpty ? [.quiet] : facts
    }

    // MARK: - Official

    /// Active notices for the municipios within reach, or island-wide.
    func relevantNotices(_ notices: [OfficialNotice], near rows: [NearbyRow], now: Date) -> [OfficialNotice] {
        let municipios = Set(rows.map { row in
            switch row.item {
            case .place(let answer): answer.place.municipio
            case .area(let status): status.area.municipio
            }
        })
        return notices.filter { notice in
            notice.isActive(at: now) && (notice.municipios.isEmpty || !municipios.isDisjoint(with: notice.municipios))
        }
    }

    /// One card per agency, actionable first, then newest; capped (§3).
    func officials(_ notices: [OfficialNotice]) -> [AgencyNotices] {
        Dictionary(grouping: notices, by: \.agency)
            .map { agency, group in
                AgencyNotices(agency: agency, notices: group.sorted { lhs, rhs in
                    (lhs.guidance != nil ? 0 : 1, rhs.updatedAt) < (rhs.guidance != nil ? 0 : 1, lhs.updatedAt)
                })
            }
            .sorted { lhs, rhs in
                let left = lhs.notices.contains { $0.guidance != nil } ? 0 : 1
                let right = rhs.notices.contains { $0.guidance != nil } ? 0 : 1
                return left != right ? left < right : lhs.latestUpdate > rhs.latestUpdate
            }
            .prefix(Self.officialCap)
            .map { $0 }
    }
}

extension AnswerFact {
    /// The event row this fact states, so the sections don't repeat it.
    nonisolated var eventItemID: String? {
        switch self {
        case .outage(let status): status.id
        case .road(let answer): answer.id
        case .warning, .cheapestGas, .nearestFuel, .quiet: nil
        }
    }

    /// Whether this fact already says what `notice` says. Actionable notices
    /// always keep their card, since the answer doesn't carry the guidance.
    nonisolated func states(_ notice: OfficialNotice) -> Bool {
        switch self {
        case .warning(let warning):
            return warning.id == notice.id
        case .outage(let status):
            return status.states(notice)
        case .road, .cheapestGas, .nearestFuel, .quiet:
            return false
        }
    }
}

extension [AnswerFact] {
    nonisolated func states(_ notice: OfficialNotice) -> Bool {
        contains { $0.states(notice) }
    }
}

extension AreaStatus {
    /// Whether this official area already says what `notice` says: the same
    /// agency, layer and municipio. Actionable notices keep their card.
    nonisolated func states(_ notice: OfficialNotice) -> Bool {
        guard case .official(let agency) = label, notice.guidance == nil else { return false }
        return notice.agency == agency && notice.layer == layer && notice.municipios.contains(area.municipio)
    }
}

extension NearbyItem {
    /// Whether this row already says what `notice` says (an official area's own notice).
    nonisolated func states(_ notice: OfficialNotice) -> Bool {
        if case .area(let status) = self { status.states(notice) } else { false }
    }

    /// The place a place row is about; nil for an area.
    nonisolated var placeID: Place.ID? {
        if case .place(let answer) = self { answer.place.id } else { nil }
    }
}
