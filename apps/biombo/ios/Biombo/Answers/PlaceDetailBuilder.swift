import Foundation

/// Builds a `PlaceDetail` for a selection. Pure: the snapshot and the
/// already-gated areas are passed in, and every rule lives in the resolver,
/// `PriceLadder`, `PriceTrend`, `ConfirmRules` or `ChargerReliability`.
/// Everything that reads freshness goes through the one resolver.
nonisolated struct PlaceDetailBuilder: Sendable {
    var resolver = AnswerResolver()
    var nearby = NearbyBuilder()

    func detail(for selection: Selection, snapshot: PlacesSnapshot, areas: [AreaStatus]) -> PlaceDetail? {
        switch selection {
        case .place(let id, let layer):
            guard let place = snapshot.places.first(where: { $0.id == id }) else { return nil }
            return detail(for: place, layer: layer, snapshot: snapshot)
        case .area(let id, _):
            guard let status = areas.first(where: { $0.id == id }) else { return nil }
            return detail(for: status, snapshot: snapshot)
        }
    }

    // MARK: - Places

    private func detail(for place: Place, layer: Layer, snapshot: PlacesSnapshot) -> PlaceDetail {
        let now = snapshot.generatedAt
        let reports = snapshot.reports
        let answer = resolver.answers(for: place, reports: reports, now: now).first { $0.layer == layer }
        let evidence = resolver.currentReports(for: place, layer: layer, reports: reports, now: now)
        let distance = snapshot.vantage.distance(to: place.anchor)
        let price = answer?.price
        let owned = resolver.ownerPosts(for: place, reports: reports, now: now)
        let tally = snapshot.chargerTallies.first { $0.placeID == place.id }
        let ladder = price.flatMap { ladder(for: $0, place: place, snapshot: snapshot) }
        let notices = notices(snapshot, layer: layer, municipio: place.municipio, excluding: nil, road: layer == .roads ? place.id : nil)

        return PlaceDetail(
            subject: .place(place),
            layer: layer,
            distance: distance,
            now: now,
            answer: answer,
            stale: resolver.olderReports(for: place, layer: layer, reports: reports, now: now),
            evidence: evidence,
            boilNotices: notices.boil,
            otherNotices: notices.other,
            question: answer.flatMap(ConfirmQuestion.init),
            canConfirm: ConfirmRules.isNearby(distance: distance, isArea: place.kind == .area),
            ladder: ladder,
            reference: place.kind == .station && ladder == nil
                ? PriceLadder.reference(brand: place.brand, grade: resolver.defaultGrade, references: snapshot.dacoReferences, now: now)
                : nil,
            trend: price.flatMap { PriceTrend(reports: snapshot.history + reports, placeID: place.id, grade: $0.grade, now: now) },
            otherGrades: layer == .gas ? otherGrades(evidence, answered: price?.grade) : [],
            dacoRange: place.kind == .station ? DacoRange(snapshot.dacoReferences, grade: resolver.defaultGrade, now: now) : nil,
            alsoReported: layer == .gas ? alsoReported(evidence, answer: answer) : [],
            sourceMix: nil,
            timeline: nil,
            hasRoadNotice: layer == .roads && !notices.other.isEmpty,
            waterPoints: layer == .water ? waterPoints(municipio: place.municipio, snapshot: snapshot) : [],
            reliability: place.kind == .charger ? ChargerReliability(tally) : nil,
            tally: tally,
            ports: PortStatus.statuses(for: place, evidence: evidence),
            events: owned.compactMap { if case .event(let event) = $0.value { event } else { nil } }.sorted { $0.start < $1.start },
            products: owned.compactMap { $0.kind == .productAvailable ? ownerText($0) : nil },
            neighbours: place.hasVerifiedOwner ? NeighbourCount.counts(evidence, now: now) : []
        )
    }

    /// The nearest other stations' current prices join the ladder.
    private func ladder(for price: FuelPrice, place: Place, snapshot: PlacesSnapshot) -> PriceLadder? {
        let now = snapshot.generatedAt
        let nearby = snapshot.places
            .filter { $0.kind == .station && $0.id != place.id }
            .compactMap { other -> (price: FuelPrice, distance: Double)? in
                let answer = resolver.answers(for: other, reports: snapshot.reports, now: now).first { $0.layer == .gas }
                guard let otherPrice = answer?.price else { return nil }
                return (otherPrice, place.anchor.distance(to: other.anchor))
            }
        return PriceLadder(this: price, brand: place.brand, references: snapshot.dacoReferences, nearby: nearby, now: now)
    }

    /// One price per other grade: the newest current report for it.
    private func otherGrades(_ evidence: [PlaceAnswer], answered grade: FuelGrade?) -> [FuelPrice] {
        FuelGrade.allCases.filter { $0 != grade }.compactMap { grade in
            evidence.compactMap(\.price).first { $0.grade == grade }
        }
    }

    /// Statuses beside the answer, one per kind, never the answer itself.
    private func alsoReported(_ evidence: [PlaceAnswer], answer: PlaceAnswer?) -> [PlaceAnswer] {
        var seen = Set<ReportKind>()
        return evidence.filter { item in
            guard item.price == nil, item.kind != answer?.kind else { return false }
            return seen.insert(item.kind).inserted
        }
    }

    /// Current water distribution points in the municipio, newest first (§6.3).
    private func waterPoints(municipio: String, snapshot: PlacesSnapshot) -> [PlaceAnswer] {
        snapshot.places
            .filter { $0.municipio == municipio }
            .flatMap { resolver.currentReports(for: $0, layer: .water, reports: snapshot.reports, now: snapshot.generatedAt) }
            .filter { $0.kind == .waterPoint }
            .sorted { $0.asOf > $1.asOf }
    }

    private func ownerText(_ report: Report) -> String? {
        if case .ownerText(let text) = report.value { text } else { nil }
    }

    // MARK: - Areas

    /// An area's evidence is what was filed on its barrios, on its layer.
    private func detail(for status: AreaStatus, snapshot: PlacesSnapshot) -> PlaceDetail {
        let now = snapshot.generatedAt
        let distance = snapshot.vantage.distance(to: status.anchor)
        let barrios = snapshot.places.filter(status.area.covers)
        let evidence = barrios
            .flatMap { resolver.currentReports(for: $0, layer: status.layer, reports: snapshot.reports, now: now) }
            .sorted { $0.asOf > $1.asOf }
        let stale = barrios
            .flatMap { resolver.olderReports(for: $0, layer: status.layer, reports: snapshot.reports, now: now) }
            .sorted { $0.asOf > $1.asOf }
        let notices = notices(snapshot, layer: status.layer, municipio: status.area.municipio, excluding: status)
        return PlaceDetail(
            subject: .area(status),
            layer: status.layer,
            distance: distance,
            now: now,
            answer: nil,
            stale: stale,
            evidence: evidence,
            boilNotices: notices.boil,
            otherNotices: notices.other,
            question: ConfirmQuestion(status),
            canConfirm: ConfirmRules.isNearby(distance: distance, isArea: true),
            ladder: nil, reference: nil, trend: nil, otherGrades: [], dacoRange: nil, alsoReported: [],
            sourceMix: SourceMix(status.area),
            timeline: AreaTimeline(status.area),
            hasRoadNotice: false,
            waterPoints: status.layer == .water ? waterPoints(municipio: status.area.municipio, snapshot: snapshot) : [],
            reliability: nil, tally: nil, ports: [],
            events: [], products: [], neighbours: []
        )
    }

    // MARK: - Official

    /// Active notices on this layer for the municipio (or island-wide): boil-water
    /// notices on their own, the rest one card per agency. An official area's
    /// own notice is already its answer, unless it says what to do. A road
    /// segment hears only closures for its stretch (§6.6): warnings and
    /// shelters are the home answer's, and flood guidance is its safety line.
    private func notices(
        _ snapshot: PlacesSnapshot, layer: Layer, municipio: String, excluding status: AreaStatus?, road: Place.ID? = nil
    ) -> (boil: [OfficialNotice], other: [AgencyNotices]) {
        let active = snapshot.notices
            .filter { $0.layer == layer && $0.isActive(at: snapshot.generatedAt) }
            .filter { $0.municipios.isEmpty || $0.municipios.contains(municipio) }
            .filter { notice in
                guard let agency = status?.area.officialAgency else { return true }
                return notice.agency != agency || notice.guidance != nil
            }
            .filter { notice in
                guard let road else { return true }
                return notice.kind == .roadClosure && (notice.placeIDs.isEmpty || notice.placeIDs.contains(road))
            }
        let boil = active.filter { $0.kind == .boilWater }.sorted { $0.updatedAt > $1.updatedAt }
        return (boil, nearby.officials(active.filter { $0.kind != .boilWater }))
    }
}
