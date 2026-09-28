import Foundation

/// The gas widget's and Siri's one station (PRODUCT.md §11 "Gasolina cerca",
/// `CheckFuelIntent`): on an ordinary day the cheapest current regular
/// price within "cerca", nearest on a tie; in crisis, the nearest station
/// that has gas, since prices step back then (§8). Only current answers
/// count, so nothing stale is ever the pick.
nonisolated struct GasPick: Hashable, Sendable {
    let answer: PlaceAnswer
    /// Metres from where "cerca" is measured.
    let distance: Double
    /// Whether this is the crisis answer ("Hay gasolina") rather than a price.
    let isAvailability: Bool
    /// When the answer stops being current, on the snapshot's clock; nil
    /// for an official answer, which never goes stale by age.
    let currentUntil: Date?

    static func make(
        from digest: HomeDigest,
        radius: Double = NearbyBuilder().radius,
        grade: FuelGrade = NearbyBuilder().defaultGrade,
        policy: FreshnessPolicy = FreshnessPolicy()
    ) -> GasPick? {
        if digest.isCrisis {
            guard let stop = digest.availability.gasoline.lead, !stop.isDisputed else { return nil }
            return GasPick(answer: stop.answer, distance: stop.distance, isAvailability: true, currentUntil: policy.currentUntil(stop.answer.lead))
        }
        let best = digest.answers
            .compactMap { answer -> (answer: PlaceAnswer, price: FuelPrice, distance: Double)? in
                guard answer.layer == .gas, let price = answer.price, price.grade == grade else { return nil }
                let distance = digest.vantage.distance(to: answer.anchor)
                return distance <= radius ? (answer, price, distance) : nil
            }
            .min { ($0.price.centsPerLitre, $0.distance) < ($1.price.centsPerLitre, $1.distance) }
        return best.map { GasPick(answer: $0.answer, distance: $0.distance, isAvailability: false, currentUntil: policy.currentUntil($0.answer.lead)) }
    }
}
