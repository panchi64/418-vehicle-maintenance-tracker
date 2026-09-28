import SwiftUI

/// Words for the detail sheet's comparisons and states (PRODUCT.md §6).
/// Differences are words with direction and size, never signed numbers.
extension PriceLadder {
    /// "3¢ menos que la referencia de DACO". Never "precio oficial", "máximo"
    /// or anything that implies a violation (§6.1).
    func headline(unit: PriceUnit) -> LocalizedStringResource? {
        switch verdict(in: unit) {
        case .below(let cents):
            let size = GlanceNumbers.difference(centsPerLitre: cents, unit: unit)
            return LocalizedStringResource("\(size)¢ menos que la referencia de DACO", comment: "Price ladder headline: this station is cheaper than DACO's reference by N cents")
        case .above(let cents):
            let size = GlanceNumbers.difference(centsPerLitre: cents, unit: unit)
            return LocalizedStringResource("\(size)¢ más que la referencia de DACO", comment: "Price ladder headline: this station costs N cents more than DACO's reference")
        case .same:
            return LocalizedStringResource("Igual que la referencia de DACO", comment: "Price ladder headline: within a cent of DACO's reference")
        case .withinRange:
            return LocalizedStringResource("Dentro del rango que publica DACO", comment: "Price ladder headline: a brand DACO doesn't list, inside DACO's island range")
        case .belowRange:
            return LocalizedStringResource("Por debajo del rango que publica DACO", comment: "Price ladder headline: below DACO's island range")
        case .aboveRange:
            return LocalizedStringResource("Por encima del rango que publica DACO", comment: "Price ladder headline: above DACO's island range")
        case .none:
            return nil
        }
    }

    /// "La más barata de 5 cerca."
    var cheapestLine: LocalizedStringResource? {
        guard isCheapest else { return nil }
        return LocalizedStringResource("La más barata de \(stationCount) cerca.", comment: "Price ladder: this station is the cheapest of N nearby, this one included")
    }

    /// The reference's label on the ladder.
    var referenceLabel: LocalizedStringResource {
        switch reference {
        case .islandRange: LocalizedStringResource("Rango de DACO", comment: "Tight ladder label: DACO's island range")
        default: LocalizedStringResource("Ref. DACO", comment: "Tight ladder label: DACO's reference for this brand")
        }
    }

    /// VoiceOver reads the whole ladder as one sentence (§3 "Compare with shapes").
    func spokenSummary(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        let price = GlanceNumbers.price(this, unit: unit, locale: locale)
        let others = others.map { GlanceNumbers.price($0, unit: unit, locale: locale) }.formatted(.list(type: .and).locale(locale))
        return others.isEmpty
            ? LocalizedStringResource("Esta estación cuesta \(price).", comment: "VoiceOver ladder: this station's price, nothing nearby to compare")
            : LocalizedStringResource("Esta estación cuesta \(price). Cerca cuestan \(others).", comment: "VoiceOver ladder: this station's price, then nearby prices as a list")
    }
}

extension PriceTrend {
    /// "Bajó 4¢ en 30 días.", over the days the trend actually covers.
    func headline(unit: PriceUnit) -> LocalizedStringResource {
        let size = GlanceNumbers.difference(centsPerLitre: abs(change), unit: unit)
        if size == 0 {
            return LocalizedStringResource("Sin cambios en \(days) días.", comment: "Price trend: no change over N days")
        }
        return change < 0
            ? LocalizedStringResource("Bajó \(size)¢ en \(days) días.", comment: "Price trend: the price fell N cents over M days")
            : LocalizedStringResource("Subió \(size)¢ en \(days) días.", comment: "Price trend: the price rose N cents over M days")
    }

    /// The trend's direction as a shape, beside its words.
    func symbol(unit: PriceUnit) -> String {
        if GlanceNumbers.difference(centsPerLitre: change, unit: unit) == 0 { return "chart.line.flattrend.xyaxis" }
        return change < 0 ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis"
    }
}

extension PriceLadder.Reference {
    /// DACO's reference in words, with when it was published (§6.1).
    func line(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        switch self {
        case .brand(let daco):
            let price = unit.perUnit(GlanceNumbers.price(daco.price, unit: unit, locale: locale))
            let date = daco.publishedOn.island(.dateTime.day().month(.abbreviated).hour().minute(), locale: locale)
            return LocalizedStringResource("\(daco.brand), \(daco.price.grade.title): \(price), publicada el \(date)", comment: "DACO's reference for a brand and grade, then when it was published")
        case .islandRange(let range, let published):
            let low = GlanceNumbers.price(range.low, unit: unit, locale: locale)
            let high = GlanceNumbers.price(range.high, unit: unit, locale: locale)
            let date = published.island(.dateTime.day().month(.abbreviated), locale: locale)
            return LocalizedStringResource("Esta marca no está en la lista de DACO. Su rango del \(date) es de \(low) a \(high).", comment: "Off-brand station: DACO's island range and its date")
        }
    }
}

extension PlaceAnswer {
    /// What a single report said: "Regular a $1.03/L", "Sin luz".
    func said(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        switch value {
        case .price(let price): price.gradedText(unit: unit, locale: locale)
        case .status(let kind): kind.word
        }
    }
}

extension ChargerReliability {
    var text: LocalizedStringResource {
        switch self {
        case .usuallyWorks: LocalizedStringResource("Suele funcionar", comment: "Charger reliability: it usually works")
        case .sometimesFails: LocalizedStringResource("A veces falla", comment: "Charger reliability: it sometimes fails")
        case .oftenFails: LocalizedStringResource("Falla a menudo", comment: "Charger reliability: it often fails")
        case .unknown: LocalizedStringResource("Todavía no sabemos si suele funcionar", comment: "Charger reliability: too few reports to say")
        }
    }

    var symbol: String {
        switch self {
        case .usuallyWorks: "checkmark.circle"
        case .sometimesFails: "exclamationmark.circle"
        case .oftenFails: "xmark.circle"
        case .unknown: "questionmark.circle"
        }
    }
}

extension CoarseAge {
    var text: LocalizedStringResource {
        switch self {
        case .thisMorning: LocalizedStringResource("hoy en la mañana", comment: "Coarse age: this morning")
        case .thisAfternoon: LocalizedStringResource("hoy en la tarde", comment: "Coarse age: this afternoon")
        case .tonight: LocalizedStringResource("esta noche", comment: "Coarse age: tonight")
        case .yesterday: LocalizedStringResource("ayer", comment: "Age: yesterday")
        case .earlier: LocalizedStringResource("hace unos días", comment: "Coarse age: a few days ago")
        }
    }
}

extension NeighbourCount {
    /// "2 vecinos dicen: Cerrado". Counts only, with a coarse age (§6.8).
    var sentence: LocalizedStringResource {
        LocalizedStringResource("\(count) vecinos dicen: \(kind.word)", comment: "Neighbours' reports on an owned business: how many said a status word")
    }
}

extension ChargerPort {
    /// "CCS1 · 50 kW". Connector names are standards, the same in both languages.
    var title: LocalizedStringResource {
        LocalizedStringResource("\(connector.displayName) · \(kilowatts) kW", comment: "A charger port: connector standard, then its power")
    }
}

extension Connector {
    var displayName: String {
        switch self {
        case .j1772: "J1772"
        case .ccs1: "CCS1"
        case .nacs: "NACS"
        case .chademo: "CHAdeMO"
        }
    }
}

extension PriceUnit {
    /// The unit beside the hero price: "/L regular".
    func heroSuffix(_ grade: FuelGrade) -> LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("/L \(grade.title)", comment: "Beside the hero price: per litre, then the grade")
        case .gallon: LocalizedStringResource("/gal \(grade.title)", comment: "Beside the hero price: per gallon, then the grade")
        }
    }

    /// VoiceOver for the hero: "$0.99 el litro de regular".
    func spoken(_ price: String, grade: FuelGrade) -> LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("\(price) el litro de \(grade.title)", comment: "VoiceOver: a price per litre of a grade")
        case .gallon: LocalizedStringResource("\(price) el galón de \(grade.title)", comment: "VoiceOver: a price per gallon of a grade")
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("Por litro", comment: "Settings: show prices per litre")
        case .gallon: LocalizedStringResource("Por galón", comment: "Settings: show prices per gallon")
        }
    }
}

extension FuelPrice {
    /// "Regular a $1.03/L": an older price, stated with its grade.
    func gradedText(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        let amount = GlanceNumbers.price(self, unit: unit, locale: locale)
        return LocalizedStringResource("\(grade.capitalizedTitle) a \(unit.perUnit(amount))", comment: "A graded price, e.g. 'Regular a $1.03/L'")
    }
}
