import SwiftUI

extension EnvironmentValues {
    /// Litres in Puerto Rico by default; a separate setting from language (§2).
    @Entry var priceUnit: PriceUnit = .litre
}

extension PriceUnit {
    /// "$0.99/L": the unit said once per section (§3).
    func perUnit(_ price: String) -> LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("\(price)/L", comment: "A price per litre, e.g. '$0.99/L'")
        case .gallon: LocalizedStringResource("\(price)/gal", comment: "A price per gallon, e.g. '$3.75/gal'")
        }
    }

    /// "/L" set small beside a large price (the gas widget).
    var suffix: LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("/L", comment: "Beside a large price: per litre")
        case .gallon: LocalizedStringResource("/gal", comment: "Beside a large price: per gallon")
        }
    }

    var sectionAside: LocalizedStringResource {
        switch self {
        case .litre: LocalizedStringResource("por litro", comment: "Section aside: prices below are per litre")
        case .gallon: LocalizedStringResource("por galón", comment: "Section aside: prices below are per gallon")
        }
    }
}

extension PlaceAnswer {
    /// The trailing value of a place row and a pin's label: "$0.99", "Funciona".
    func valueText(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        switch value {
        case .price(let price):
            let amount = GlanceNumbers.price(price, unit: unit, locale: locale)
            return price.grade == .regular
                ? LocalizedStringResource("\(amount)", comment: "A regular-grade price shown alone, e.g. '$0.99'")
                : LocalizedStringResource("\(amount) \(price.grade.title)", comment: "A price with its grade, e.g. '$1.12 premium'")
        case .status(let kind):
            return kind.word
        }
    }

    /// The pin glyph: the status variant when the answer is a problem.
    var glyph: String {
        if case .status(let kind) = value { kind.glyph } else { layer.symbol }
    }

    /// Event rows speak a sentence about the place (§3 "Two row grammars").
    var eventSentence: LocalizedStringResource {
        kind.eventSentence(at: place.displayName)
    }
}

extension FuelGrade {
    /// The grade leading a line or row: "Regular a $1.03/L", "Diésel".
    var capitalizedTitle: LocalizedStringResource {
        switch self {
        case .regular: LocalizedStringResource("Regular", comment: "Fuel grade, leading a line")
        case .premium: LocalizedStringResource("Premium", comment: "Fuel grade, leading a line")
        case .diesel: LocalizedStringResource("Diésel", comment: "Fuel grade, leading a line")
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .regular: LocalizedStringResource("regular", comment: "Fuel grade")
        case .premium: LocalizedStringResource("premium", comment: "Fuel grade")
        case .diesel: LocalizedStringResource("diésel", comment: "Fuel grade")
        }
    }
}

extension AreaStatus {
    /// The map label word: "Sin luz", or "Volviendo" while service returns.
    var word: LocalizedStringResource {
        if area.lifecycle == .restoring {
            return LocalizedStringResource("Volviendo", comment: "Outage area label: service is coming back in part")
        }
        return outageKind.word
    }

    var glyph: String { area.lifecycle == .restoring ? layer.symbol : outageKind.glyph }

    private var outageKind: ReportKind {
        switch layer {
        case .water: .noWater
        case .signal: .noSignal
        default: .noPower
        }
    }

    /// The event-row sentence: "Bairoa sigue sin luz".
    var sentence: LocalizedStringResource {
        let name = placeName
        switch (layer, area.lifecycle) {
        case (.power, .restoring):
            return LocalizedStringResource("La luz está volviendo en \(name)", comment: "Outage row: power is coming back in the named area")
        case (.water, .restoring):
            return LocalizedStringResource("El agua está volviendo en \(name)", comment: "Outage row: water is coming back in the named area")
        case (.water, _) where area.isPlanned:
            return LocalizedStringResource("\(name) está en el plan de interrupciones de agua", comment: "Outage row: the named area is in the water-interruption plan")
        case (.water, _):
            return LocalizedStringResource("\(name) sigue sin agua", comment: "Outage row: the named area is still without water")
        case (.signal, _):
            if let carrier = area.carrier {
                return LocalizedStringResource("\(carrier.displayName) no tiene señal en \(name)", comment: "Outage row: a carrier has no signal in the named area")
            }
            return LocalizedStringResource("\(name) sigue sin señal", comment: "Outage row: the named area is still without signal")
        default:
            return LocalizedStringResource("\(name) sigue sin luz", comment: "Outage row: the named area is still without power")
        }
    }

    /// The answer sentence, with since when: "Bairoa sigue sin luz desde las 3:10 p. m."
    func answerSentence(now: Date, locale: Locale) -> LocalizedStringResource {
        let name = placeName
        let sameDay = PuertoRico.calendar.isDate(area.openedAt, inSameDayAs: now)
        let since = sameDay ? area.openedAt.islandClock(locale: locale) : area.openedAt.island(.dateTime.weekday(.wide), locale: locale)
        switch (layer, area.lifecycle, area.isPlanned) {
        case (.power, .restoring, _), (.water, .restoring, _), (.signal, _, _), (.water, _, true):
            return sentence
        case (.water, _, _):
            return sameDay
                ? LocalizedStringResource("\(name) sigue sin agua desde las \(since)", comment: "Answer: the area has had no water since a clock time today")
                : LocalizedStringResource("\(name) sigue sin agua desde el \(since)", comment: "Answer: the area has had no water since a weekday")
        default:
            return sameDay
                ? LocalizedStringResource("\(name) sigue sin luz desde las \(since)", comment: "Answer: the area has had no power since a clock time today")
                : LocalizedStringResource("\(name) sigue sin luz desde el \(since)", comment: "Answer: the area has had no power since a weekday")
        }
    }
}

extension AnswerFact {
    /// One clause of the area's answer. An official warning is the agency's own sentence.
    func sentence(now: Date, unit: PriceUnit, locale: Locale) -> Text {
        switch self {
        case .warning(let notice):
            return Text(verbatim: notice.headline)
        case .outage(let status):
            return Text(status.answerSentence(now: now, locale: locale))
        case .road(let answer):
            return Text(answer.eventSentence)
        case .cheapestGas(let answer):
            let price = answer.price.map { GlanceNumbers.price($0, unit: unit, locale: locale) } ?? ""
            return Text(LocalizedStringResource("Gasolina desde \(unit.perUnit(price)) cerca", comment: "Answer: the cheapest gas nearby, e.g. 'Gasolina desde $0.97/L cerca'"))
        case .nearestFuel(let answer, let distance):
            let away = GlanceNumbers.distance(meters: distance, locale: locale)
            return Text(LocalizedStringResource("La gasolina más cerca está en \(answer.place.name), a \(away).", comment: "Crisis answer: the nearest station selling fuel and how far it is, e.g. 'La gasolina más cerca está en Puma Los Filtros, a 2.1 km.'"))
        case .quiet:
            return Text(LocalizedStringResource("No hay reportes recientes cerca", comment: "Answer when nothing current is reported nearby"))
        }
    }
}
