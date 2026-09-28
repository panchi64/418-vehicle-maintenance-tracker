import Foundation

/// Builds "Gasolina y planta" (PRODUCT.md §6.5): for each fuel, which stations
/// within reach have it, nearest first, and which don't; then the places open
/// on a generator. Community and owner reports only, through the one freshness
/// gate in `AnswerResolver`. Pure: everything comes from the snapshot.
nonisolated struct AvailabilityBuilder: Sendable {
    var resolver = AnswerResolver()
    /// How far "cerca" reaches; the home digest passes its own.
    var radius: Double = NearbyBuilder().radius

    /// What a generator row can say.
    nonisolated static let generatorKinds: Set<ReportKind> = [.businessOnGenerator, .openOnGenerator, .hasIce, .hasCookingGas]

    func make(snapshot: PlacesSnapshot, vantage: GeoPoint) -> AvailabilityDigest {
        let now = snapshot.generatedAt
        let within = snapshot.places.filter { vantage.distance(to: $0.anchor) <= radius }
        let stations = within.filter { $0.kind == .station }
        return AvailabilityDigest(
            gasoline: availability(.gasoline, stations: stations, snapshot: snapshot, vantage: vantage, now: now),
            diesel: availability(.diesel, stations: stations, snapshot: snapshot, vantage: vantage, now: now),
            generators: generators(within, snapshot: snapshot, vantage: vantage, now: now)
        )
    }

    // MARK: - Fuel

    private func availability(_ fuel: FuelKind, stations: [Place], snapshot: PlacesSnapshot, vantage: GeoPoint, now: Date) -> FuelAvailability {
        let stops = stations.compactMap { stop(fuel, at: $0, snapshot: snapshot, vantage: vantage, now: now) }
            .sorted { $0.distance < $1.distance }
        let older = stations.flatMap { station in
            resolver.olderReports(for: station, layer: .gas, reports: snapshot.reports, now: now)
                .filter { fuel.statusKinds.contains($0.kind) }
                .map { NearbyRow(item: .place($0), distance: vantage.distance(to: station.anchor)) }
        }
        return FuelAvailability(
            fuel: fuel,
            stops: stops.filter { fuel.positiveKinds.contains($0.answer.kind) || $0.answer.price != nil },
            without: stops.filter { fuel.negativeKinds.contains($0.answer.kind) },
            older: older.sorted { stamp($0) > stamp($1) },
            window: fuel.window
        )
    }

    /// The station's answer for `fuel`: the highest-ranked, newest report that
    /// says yes or no. An owner's "hay" stays the answer when neighbours say
    /// "no hay", but enough of them make the dispute the news; neither is hidden.
    private func stop(_ fuel: FuelKind, at station: Place, snapshot: PlacesSnapshot, vantage: GeoPoint, now: Date) -> FuelStop? {
        let current = resolver.currentReports(for: station, layer: .gas, reports: snapshot.reports, now: now)
        // A price outlives availability (48 h against 2 h), so it only says
        // "hay" while an availability report would still count.
        let window = fuel.window
        let positive = current.filter { answer in
            fuel.positiveKinds.contains(answer.kind)
                || (answer.price.map { fuel.sells($0.grade) } == true && now.timeIntervalSince(answer.asOf) < window)
        }
        let negative = current.filter { fuel.negativeKinds.contains($0.kind) }
        guard let lead = (positive + negative).best else { return nil }
        let contradictions = negative
            .filter { $0.lead.source == .community }
            .reduce(0) { $0 + 1 + $1.lead.votes.confirmCount }
        let isDisputed = lead.label == .verifiedOwner && !negative.contains(lead)
            && contradictions >= resolver.verification.ownerContradictions
        // A line at the pumps is a gasoline report; it says nothing about diesel.
        let queue = current.first { fuel == .gasoline && $0.kind == .queue }.flatMap { answer -> Int? in
            if case .queueMinutes(let minutes) = answer.lead.value { minutes } else { nil }
        }
        return FuelStop(answer: lead, distance: vantage.distance(to: station.anchor), queueMinutes: queue, isDisputed: isDisputed)
    }

    // MARK: - Generators

    /// One row per place: its best current generator, ice or cooking-gas report.
    private func generators(_ places: [Place], snapshot: PlacesSnapshot, vantage: GeoPoint, now: Date) -> [NearbyRow] {
        places.compactMap { place -> NearbyRow? in
            let reports = [Layer.businesses, .gas].flatMap {
                resolver.currentReports(for: place, layer: $0, reports: snapshot.reports, now: now)
            }
            guard let best = reports.filter({ Self.generatorKinds.contains($0.kind) }).best else { return nil }
            return NearbyRow(item: .place(best), distance: vantage.distance(to: place.anchor))
        }
        .sorted { $0.distance < $1.distance }
    }

    private func stamp(_ row: NearbyRow) -> Date {
        if case .place(let answer) = row.item { answer.asOf } else { .distantPast }
    }
}

private extension [PlaceAnswer] {
    /// The highest-ranked label, then the newest (§4.5 lead order).
    nonisolated var best: PlaceAnswer? {
        self.max { ($0.label.leadRank, $0.asOf) < ($1.label.leadRank, $1.asOf) }
    }
}
