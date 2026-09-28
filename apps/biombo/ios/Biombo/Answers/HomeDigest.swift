import Foundation

/// Everything the home screen shows, derived once from a snapshot and handed
/// down to the map, the sheet and Capas so they can never disagree. Only
/// "Cerca de ti" depends on the drawn layers; `showing(_:)` rebuilds just that.
nonisolated struct HomeDigest: Sendable {
    let now: Date
    let vantage: GeoPoint
    let isCrisis: Bool
    /// Every current answer on the island, for pins.
    let answers: [PlaceAnswer]
    /// Every current, drawable outage area.
    let areas: [AreaStatus]
    /// The seven Capas rows, answered for hidden layers too.
    let layers: [LayerDigest]
    /// "Gasolina y planta": fuel and generators within reach (§6.5).
    let availability: AvailabilityDigest
    /// Every active notice, for watched places anywhere on the island (§9).
    let notices: [OfficialNotice]
    private(set) var visibleLayers: Set<Layer>
    private(set) var nearby: NearbyDigest

    private var input: NearbyBuilder.Input
    private let builder: NearbyBuilder

    init(
        snapshot: PlacesSnapshot,
        vantage: GeoPoint,
        visibleLayers: Set<Layer>,
        resolver: AnswerResolver = AnswerResolver(),
        builder: NearbyBuilder = NearbyBuilder()
    ) {
        let now = snapshot.generatedAt
        let isCrisis = snapshot.crisis.isActive
        let answers = snapshot.places.flatMap { resolver.answers(for: $0, reports: snapshot.reports, now: now) }
        let availability = AvailabilityBuilder(resolver: resolver, radius: builder.radius).make(snapshot: snapshot, vantage: vantage)
        let input = NearbyBuilder.Input(
            vantage: vantage,
            answers: answers,
            staleAnswers: snapshot.places.flatMap { resolver.staleAnswers(for: $0, reports: snapshot.reports, now: now) },
            areas: resolver.areaStatuses(snapshot.outageAreas, isCrisis: isCrisis, now: now),
            notices: snapshot.notices,
            dacoReferences: snapshot.dacoReferences,
            isCrisis: isCrisis,
            visibleLayers: visibleLayers,
            now: now,
            nearestFuel: availability.gasoline.lead
        )
        let output = builder.make(input)

        self.now = now
        self.vantage = vantage
        self.isCrisis = isCrisis
        self.answers = answers
        self.areas = input.areas
        self.visibleLayers = visibleLayers
        self.nearby = output.nearby
        self.layers = LayerDigest.make(rows: output.allRows, notices: output.notices, now: now, defaultGrade: builder.defaultGrade)
        self.availability = availability
        self.notices = snapshot.notices.filter { $0.isActive(at: now) }
        self.input = input
        self.builder = builder
    }

    /// The same digest with a different set of drawn layers.
    func showing(_ layers: Set<Layer>) -> HomeDigest {
        guard layers != visibleLayers else { return self }
        var copy = self
        copy.input.visibleLayers = layers
        copy.visibleLayers = layers
        copy.nearby = builder.make(copy.input).nearby
        return copy
    }

    /// Resolves a map or row selection back to what it points at.
    func item(withID id: String) -> NearbyItem? {
        if let answer = answers.first(where: { $0.id == id }) { return .place(answer) }
        if let status = areas.first(where: { $0.id == id }) { return .area(status) }
        return nil
    }

    /// The open outage area a barrio place belongs to, which a search for it
    /// opens instead of the barrio's point reports.
    func area(covering place: Place) -> AreaStatus? {
        areas.first { $0.area.covers(place) }
    }

    /// What choosing a search result selects: an outage area over its barrio,
    /// else the place on its answered layer.
    func selection(forSearched place: Place) -> Selection {
        if let status = area(covering: place) {
            return .area(status.id, status.layer)
        }
        return .place(place.id, answer(forPlace: place.id)?.layer ?? place.kind.layer)
    }

    /// A searched place's answer: on a drawn layer first, then on the layer
    /// its kind stands for, then in layer order.
    func answer(forPlace id: Place.ID) -> PlaceAnswer? {
        let own = answers.filter { $0.place.id == id }
        return own.first { visibleLayers.contains($0.layer) }
            ?? own.first { $0.layer == $0.place.kind.layer }
            ?? own.first
    }
}
