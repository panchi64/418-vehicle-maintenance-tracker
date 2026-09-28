import Foundation

/// The gas layer's one comparison visual (PRODUCT.md §6.1): this station's
/// price against "la referencia de DACO" for its brand and grade, and up to 5
/// nearby stations. DACO estimates one pump price per brand a day and sets
/// none, so the comparison states direction and size only, never a violation.
nonisolated struct PriceLadder: Hashable, Sendable {
    /// What this station is compared against.
    enum Reference: Hashable, Sendable {
        /// DACO's reference for this station's brand and grade.
        case brand(DacoReference)
        /// Off DACO's brand list: DACO's island range across brands.
        case islandRange(DacoRange, publishedOn: Date)
    }

    /// The headline's comparison. Sizes are in ¢/L; the view converts them.
    enum Verdict: Hashable, Sendable {
        case below(centsPerLitre: Double)
        case above(centsPerLitre: Double)
        /// Within `sameWithin` cents of the brand reference, in the unit shown.
        case same
        case withinRange
        case belowRange
        case aboveRange
        /// No current reference for this grade.
        case none
    }

    let this: FuelPrice
    let reference: Reference?
    /// Nearest stations' prices for the same grade, at most `nearbyCap`.
    let others: [FuelPrice]

    /// "Igual que la referencia" within this many cents of the unit shown
    /// (*proposed*): 1¢/L, or 1¢/gal, never 1¢/L read out as 4¢/gal.
    nonisolated static let sameWithin = 1.0
    nonisolated static let nearbyCap = 5
    /// Stations farther than this don't join the ladder (*proposed*).
    nonisolated static let nearbyRadius = 10_000.0

    /// `nearby` is every other station's price with its distance; the nearest
    /// same-grade ones join. Nil when there is nothing to compare with.
    init?(this: FuelPrice, brand: String?, references: [DacoReference], nearby: [(price: FuelPrice, distance: Double)], now: Date) {
        let reference = Self.reference(brand: brand, grade: this.grade, references: references, now: now)
        let others = nearby
            .filter { $0.price.grade == this.grade && $0.distance <= Self.nearbyRadius }
            .sorted { $0.distance < $1.distance }
            .prefix(Self.nearbyCap)
            .map(\.price)
        guard reference != nil || !others.isEmpty else { return nil }
        self.this = this
        self.reference = reference
        self.others = others
    }

    /// DACO's current reference for a brand and grade, else its island range
    /// across brands; nil when DACO has published nothing current.
    static func reference(brand: String?, grade: FuelGrade, references: [DacoReference], now: Date) -> Reference? {
        let current = references.filter { $0.price.grade == grade && $0.isCurrent(at: now) }
        if let brand, let own = current.first(where: { $0.brand == brand }) {
            return .brand(own)
        }
        if let range = DacoRange(current, grade: grade, now: now), let newest = current.map(\.publishedOn).max() {
            return .islandRange(range, publishedOn: newest)
        }
        return nil
    }

    /// The comparison as read in `unit`: "the same" is judged in the cents shown.
    func verdict(in unit: PriceUnit) -> Verdict {
        let cents = this.centsPerLitre
        switch reference {
        case .brand(let daco):
            let difference = cents - daco.price.centsPerLitre
            let shown = unit == .litre ? abs(difference) : abs(difference) * FuelPrice.litresPerGallon
            if shown <= Self.sameWithin { return .same }
            return difference < 0 ? .below(centsPerLitre: -difference) : .above(centsPerLitre: difference)
        case .islandRange(let range, _):
            if range.cents.contains(cents) { return .withinRange }
            return cents < range.cents.lowerBound ? .belowRange : .aboveRange
        case nil:
            return .none
        }
    }

    /// Cheapest of the stations on the ladder, when there are others to beat.
    var isCheapest: Bool {
        !others.isEmpty && others.allSatisfy { this.centsPerLitre <= $0.centsPerLitre }
    }

    /// Stations on the ladder, this one included.
    var stationCount: Int { others.count + 1 }

    /// When DACO published the reference; the view dates it when not today.
    var publishedOn: Date? {
        switch reference {
        case .brand(let daco): daco.publishedOn
        case .islandRange(_, let date): date
        case nil: nil
        }
    }

    /// The reference's span in ¢/L: one value for a brand, the range otherwise.
    var referenceCents: ClosedRange<Double>? {
        switch reference {
        case .brand(let daco): daco.price.centsPerLitre...daco.price.centsPerLitre
        case .islandRange(let range, _): range.cents
        case nil: nil
        }
    }

    /// The scale every mark sits on, padded so no mark touches an end.
    var scale: ClosedRange<Double> {
        let values = [this.centsPerLitre] + others.map(\.centsPerLitre) + (referenceCents.map { [$0.lowerBound, $0.upperBound] } ?? [])
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        let pad = max((high - low) * 0.12, 1)
        return (low - pad)...(high + pad)
    }

    /// A value's position along the scale, 0...1.
    func position(_ cents: Double) -> Double {
        let scale = self.scale
        return (cents - scale.lowerBound) / (scale.upperBound - scale.lowerBound)
    }
}
