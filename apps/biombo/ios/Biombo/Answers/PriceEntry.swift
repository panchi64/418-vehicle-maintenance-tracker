import Foundation

/// A typed pump price (PRODUCT.md §4.2, §6.1): read in the user's unit,
/// stored in ¢/L, and checked against DACO's island range before it can
/// enter the answer. Pure.
nonisolated enum PriceEntry {
    nonisolated enum Check: Hashable, Sendable {
        case ok
        /// Not a pump price at all ("9.99" per litre): asked again, never sent.
        case implausible
        /// Far outside DACO's island range: sent, but held out of the median until reviewed.
        case heldForReview
    }

    /// "0.99", "0,99", "$0.99" or "99" (cents) in `unit`, as ¢/L.
    static func parse(_ text: String, grade: FuelGrade, unit: PriceUnit) -> FuelPrice? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "¢", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let number = Double(cleaned), number > 0 else { return nil }
        // Whole numbers of 10 or more are cents ("99"); anything else is dollars.
        let cents = number >= 10 && !cleaned.contains(".") ? number : number * 100
        let perLitre = unit == .litre ? cents : cents / FuelPrice.litresPerGallon
        return FuelPrice(grade: grade, centsPerLitre: perLitre)
    }

    /// A pump price at all, before any comparison with DACO.
    static func isPlausible(_ price: FuelPrice) -> Bool {
        ContributionRules.plausiblePrice.contains(price.centsPerLitre)
    }

    static func check(_ price: FuelPrice, references: [DacoReference], now: Date) -> Check {
        guard isPlausible(price) else { return .implausible }
        guard let range = DacoRange(references, grade: price.grade, now: now) else { return .ok }
        let margin = ContributionRules.priceOutlierMargin
        let allowed = (range.cents.lowerBound - margin)...(range.cents.upperBound + margin)
        return allowed.contains(price.centsPerLitre) ? .ok : .heldForReview
    }

    /// The text a field starts with for a price already known ("0.99").
    static func text(for price: FuelPrice, unit: PriceUnit) -> String {
        let cents = GlanceNumbers.cents(price, unit: unit)
        return String(format: "%d.%02d", cents / 100, cents % 100)
    }
}
