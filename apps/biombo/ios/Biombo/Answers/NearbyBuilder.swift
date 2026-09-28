import Foundation

/// Builds "Cerca de ti": the area's answer, official cards and sections grouped
/// by the user's question (PRODUCT.md §3). Pure: every input is passed in.
nonisolated struct NearbyBuilder: Sendable {
    /// How far "cerca" reaches from the vantage point (*proposed*).
    var radius: Double = 25_000
    var defaultGrade: FuelGrade = .regular
    /// Official cards shown at once (§3 row caps).
    nonisolated static let officialCap = 3

    struct Input: Sendable {
        var vantage: GeoPoint
        /// Current answers only (`AnswerResolver.answers`).
        var answers: [PlaceAnswer]
        var staleAnswers: [PlaceAnswer]
        var areas: [AreaStatus]
        var notices: [OfficialNotice]
        var dacoReferences: [DacoReference]
        var isCrisis: Bool
        var visibleLayers: Set<Layer>
        var now: Date
        /// "Gasolina y planta"'s answer, which the crisis answer repeats.
        var nearestFuel: FuelStop?
    }

    /// The digest, plus what Capas reads from the same pass.
    struct Output: Sendable {
        let nearby: NearbyDigest
        /// Every current row within reach, whatever layers are drawn.
        let allRows: [NearbyRow]
        /// Every active notice for the area, before the answer and the card cap trim them.
        let notices: [OfficialNotice]
    }

    func make(_ input: Input) -> Output {
        // Officials and the area's name don't depend on which layers are drawn.
        let everything = rows(input.answers.map(NearbyItem.place) + input.areas.map(NearbyItem.area), from: input.vantage)
        let near = everything.filter { input.visibleLayers.contains($0.layer) }
        let stale = rows(input.staleAnswers.map(NearbyItem.place), from: input.vantage)
            .filter { input.visibleLayers.contains($0.layer) }
        let notices = relevantNotices(input.notices, near: everything, now: input.now)
        let fuel = input.visibleLayers.contains(.gas) ? input.nearestFuel : nil
        let facts = facts(from: near, notices: notices, isCrisis: input.isCrisis, nearestFuel: fuel)
        // A fact the answer states is said once: not again as a row or a card (N7).
        let answeredIDs = Set(facts.compactMap(\.eventItemID))
        // An official area row already carries its agency's notice, so that
        // card goes; a notice about a place (a DTOP closure) outranks the
        // neighbours' row about it, so that row goes.
        let officials = officials(notices.filter { notice in
            !facts.states(notice) && !near.contains { $0.item.states(notice) }
        })
        let noticedPlaces = Set(officials.flatMap(\.notices).flatMap(\.placeIDs))
        let said = { (row: NearbyRow) in
            answeredIDs.contains(row.id) || row.item.placeID.map(noticedPlaces.contains) == true
        }

        // Crisis: prices step back and "Gasolina y planta" (availability and
        // generators) takes the places' turn after the services (§8).
        let order: [NearbySection.Kind] = input.isCrisis
            ? [.services, .roads, .chargers]
            : [.cheapestGas, .services, .roads, .chargers, .openNow]
        let sections = order.compactMap { kind -> NearbySection? in
            let current = sorted(near.filter { belongs($0, to: kind) && !said($0) }, for: kind)
            let older = stale.filter { belongs($0, to: kind, includeClosed: true) }
                .sorted { stamp($0) > stamp($1) }
            guard !current.isEmpty || !older.isEmpty else { return nil }
            return NearbySection(kind: kind, rows: current, staleRows: older)
        }

        let area = area(near: input.vantage, rows: everything + stale)
        let nearby = NearbyDigest(
            areaName: area.name,
            areaRegion: area.region,
            facts: facts,
            officials: officials,
            sections: sections,
            dacoRange: dacoRange(input.dacoReferences, now: input.now),
            isCrisis: input.isCrisis
        )
        return Output(nearby: nearby, allRows: everything, notices: notices)
    }

    // MARK: - Rows

    /// Items within `radius` of `vantage`, with their distance.
    func rows(_ items: [NearbyItem], from vantage: GeoPoint) -> [NearbyRow] {
        items.compactMap { item in
            let distance = vantage.distance(to: item.anchor)
            return distance <= radius ? NearbyRow(item: item, distance: distance) : nil
        }
    }

    func belongs(_ row: NearbyRow, to kind: NearbySection.Kind, includeClosed: Bool = false) -> Bool {
        switch (kind, row.item) {
        case (.cheapestGas, .place(let answer)):
            return answer.price?.grade == defaultGrade
        case (.services, _):
            return [.power, .water, .signal].contains(row.layer)
        case (.roads, _):
            return row.layer == .roads
        case (.chargers, _):
            return row.layer == .chargers
        case (.openNow, .place(let answer)):
            return answer.layer == .businesses && (includeClosed || [.businessOpen, .businessOnGenerator].contains(answer.kind))
        default:
            return false
        }
    }

    /// Sort by the section's question, never by insertion time (§3).
    func sorted(_ rows: [NearbyRow], for kind: NearbySection.Kind) -> [NearbyRow] {
        switch kind {
        case .cheapestGas:
            return rows.sorted { (price($0), $0.distance) < (price($1), $1.distance) }
        case .services:
            return rows.sorted { (serviceRank($0), $0.distance) < (serviceRank($1), $1.distance) }
        case .chargers:
            return rows.sorted { (chargerRank($0), $0.distance) < (chargerRank($1), $1.distance) }
        case .roads, .openNow:
            return rows.sorted { $0.distance < $1.distance }
        }
    }

    private func price(_ row: NearbyRow) -> Double {
        if case .place(let answer) = row.item, let price = answer.price { price.centsPerLitre } else { .infinity }
    }

    /// Official areas, then confirmed, then everything else.
    private func serviceRank(_ row: NearbyRow) -> Int {
        guard case .area(let status) = row.item else { return 3 }
        switch status.label {
        case .official: return 0
        case .communityConfirmed: return 1
        default: return 2
        }
    }

    private func chargerRank(_ row: NearbyRow) -> Int {
        if case .place(let answer) = row.item, answer.kind == .chargerWorks { 0 } else { 1 }
    }

    private func stamp(_ row: NearbyRow) -> Date {
        switch row.item {
        case .place(let answer): answer.asOf
        case .area(let status): status.area.latestEvidenceAt
        }
    }

    /// The municipio of the nearest place, or of the nearest area.
    /// The municipio and region of the nearest item, which name the area.
    private func area(near vantage: GeoPoint, rows: [NearbyRow]) -> (name: String, region: Region?) {
        let nearest = rows.min { $0.distance < $1.distance }
        switch nearest?.item {
        case .place(let answer): return (answer.place.municipio, answer.place.region)
        case .area(let status): return (status.area.municipio, status.area.region)
        case nil: return ("", nil)
        }
    }

    private func dacoRange(_ references: [DacoReference], now: Date) -> DacoRange? {
        DacoRange(references, grade: defaultGrade, now: now)
    }
}
