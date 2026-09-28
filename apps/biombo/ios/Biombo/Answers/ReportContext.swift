import Foundation

/// What Quick Report is about, answered before any choice (direction §3.6
/// "Put the answer first"): where the report will land, and the three
/// verbs that fit there. Reports snap to the nearest place of the right kind
/// within its radius (§4.1); a place out of reach can't take a report (§5).
nonisolated struct ReportContext: Hashable, Sendable {
    /// What the report is about: where you stand, or the place a detail showed.
    nonisolated enum Focus: Hashable, Sendable {
        case whereYouAre
        case place(Place.ID, Layer)
        case area(OutageArea.ID)
    }

    let focus: Focus
    /// The layer the one-tap verbs speak for; nil when nothing is in reach,
    /// and the verbs are the three anyone can make where they stand.
    let layer: Layer?
    /// The outage the report is about: the one you stand in, or the area a detail showed.
    let outage: AreaStatus?
    /// You stand inside `outage` ("Estás dentro de un área sin luz").
    let standsInOutage: Bool
    /// The place each layer's report lands on, when one is in reach.
    let targets: [Layer: ReportTarget]
    let oneTap: [ReportKind]
    let isCrisis: Bool

    /// Where a report on `layer` lands, if it can.
    func target(for layer: Layer) -> ReportTarget? { targets[layer] }

    func target(for kind: ReportKind) -> ReportTarget? { targets[kind.layer] }

    /// The place the context line names first.
    var lead: ReportTarget? { layer.flatMap { targets[$0] } ?? targets[.power] }
}

/// A place a report can land on, and how far it is.
nonisolated struct ReportTarget: Hashable, Sendable {
    let place: Place
    let distance: Double
    /// Near enough for the server to accept it (§5 "Proximity").
    let isInReach: Bool
}

/// Builds the context from the snapshot, the drawn areas and where you are. Pure.
nonisolated struct ReportContextBuilder: Sendable {
    let snapshot: PlacesSnapshot
    let areas: [AreaStatus]
    let vantage: GeoPoint
    var resolver = AnswerResolver()

    /// `chosen` holds places picked with Cambiar; they replace the nearest.
    func context(for focus: ReportContext.Focus, chosen: [Layer: Place.ID] = [:]) -> ReportContext {
        let isCrisis = snapshot.crisis.isActive
        var targets = nearestTargets()
        for (layer, id) in chosen {
            if let place = snapshot.places.first(where: { $0.id == id }) { targets[layer] = target(place) }
        }
        var outage = areas.first { vantage.isInside($0.area.polygon) }
        var layer: Layer?

        switch focus {
        case .whereYouAre:
            layer = outage?.layer ?? Self.pointOrder.first { targets[$0]?.isInReach == true }
        case .place(let id, let focusLayer):
            if let place = snapshot.places.first(where: { $0.id == id }) {
                targets[focusLayer] = target(place)
            }
            layer = focusLayer
            outage = nil
        case .area(let id):
            guard let status = areas.first(where: { $0.id == id }) else { break }
            outage = status
            layer = status.layer
            if let place = barrioPlace(for: status) {
                let inside = vantage.isInside(status.area.polygon)
                let distance = inside ? 0 : vantage.distance(to: status.anchor)
                targets[status.layer] = ReportTarget(place: place, distance: distance, isInReach: inside || distance <= ConfirmRules.areaRadius)
            }
        }

        let oneTap: [ReportKind]
        if let layer {
            let current = outage?.layer == layer ? outageKind(layer) : currentKind(on: targets[layer]?.place, layer: layer)
            oneTap = ReportVocabulary.oneTap(for: layer, current: current, isCrisis: isCrisis)
        } else {
            oneTap = ReportVocabulary.whereYouStand
        }
        return ReportContext(
            focus: focus, layer: layer, outage: outage,
            standsInOutage: outage.map { vantage.isInside($0.area.polygon) } ?? false,
            targets: targets, oneTap: oneTap, isCrisis: isCrisis
        )
    }

    /// Point layers are tried in this order when nothing else says which one you mean.
    nonisolated static let pointOrder: [Layer] = [.gas, .chargers, .businesses, .roads]

    /// The nearest place in reach for each layer. Area layers take the barrio
    /// you stand in, or the nearest one within reach.
    private func nearestTargets() -> [Layer: ReportTarget] {
        var targets: [Layer: ReportTarget] = [:]
        for layer in Layer.allCases {
            targets[layer] = candidates(for: layer).first
        }
        return targets
    }

    /// Cambiar's choices: every place of the layer's kind in reach, nearest first.
    func candidates(for layer: Layer) -> [ReportTarget] {
        snapshot.places
            .filter { $0.kind == placeKind(for: layer) }
            .map { target($0) }
            .filter(\.isInReach)
            .sorted { $0.distance < $1.distance }
    }

    private func target(_ place: Place) -> ReportTarget {
        let distance = vantage.distance(to: place.geometry)
        return ReportTarget(place: place, distance: distance, isInReach: distance <= ContributionRules.snapRadius(for: place.kind))
    }

    private func placeKind(for layer: Layer) -> Place.Kind {
        switch layer {
        case .gas: .station
        case .chargers: .charger
        case .businesses: .business
        case .roads: .roadSegment
        case .power, .water, .signal: .area
        }
    }

    /// The barrio place an outage area's reports attach to.
    private func barrioPlace(for status: AreaStatus) -> Place? {
        snapshot.places.first { $0.kind == .area && $0.municipio == status.area.municipio && status.area.barrios.contains($0.displayName) }
            ?? snapshot.places.filter { $0.kind == .area }.min { $0.anchor.distance(to: status.anchor) < $1.anchor.distance(to: status.anchor) }
    }

    private func outageKind(_ layer: Layer) -> ReportKind? {
        switch layer {
        case .power: .noPower
        case .water: .noWater
        case .signal: .noSignal
        default: nil
        }
    }

    /// The answer standing on a place, so its reversal can come first.
    private func currentKind(on place: Place?, layer: Layer) -> ReportKind? {
        guard let place else { return nil }
        let answer = resolver.answers(for: place, reports: snapshot.reports, now: snapshot.generatedAt).first { $0.layer == layer }
        if case .status(let kind) = answer?.value { return kind }
        return nil
    }
}
