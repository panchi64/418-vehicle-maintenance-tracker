import Foundation

/// "Gasolina y planta"'s words (PRODUCT.md §6.5, V2-FuelGenerator).
extension FuelKind {
    var title: LocalizedStringResource {
        switch self {
        case .gasoline: LocalizedStringResource("Gasolina", comment: "Fuel switch: gasoline")
        case .diesel: LocalizedStringResource("Diésel", comment: "Fuel switch: diesel")
        }
    }

    /// "Hay gasolina" or "Hay diésel": a section title and a row's value.
    var hasTitle: LocalizedStringResource {
        switch self {
        case .gasoline: LocalizedStringResource("También hay gasolina", comment: "Section: other stations with gas, after the answer")
        case .diesel: LocalizedStringResource("También hay diésel", comment: "Section: other stations with diesel, after the answer")
        }
    }
}

extension FuelAvailability {
    /// "Hay gasolina en 2 estaciones cerca. La más cerca es Puma, a 0.8 km."
    func answer(locale: Locale) -> LocalizedStringResource {
        guard let lead else {
            switch fuel {
            case .gasoline: return LocalizedStringResource("Nadie ha reportado gasolina cerca hace poco.", comment: "Availability answer: no current reports of gas nearby")
            case .diesel: return LocalizedStringResource("Nadie ha reportado diésel cerca hace poco.", comment: "Availability answer: no current reports of diesel nearby")
            }
        }
        let name = lead.place.name
        let away = GlanceNumbers.distance(meters: lead.distance, locale: locale)
        switch (fuel, stops.count) {
        case (.gasoline, 1):
            return LocalizedStringResource("Hay gasolina en 1 estación cerca: \(name), a \(away).", comment: "Availability answer: one station with gas, its name and distance")
        case (.gasoline, let count):
            return LocalizedStringResource("Hay gasolina en \(count) estaciones cerca. La más cerca es \(name), a \(away).", comment: "Availability answer: several stations with gas, then the nearest and its distance")
        case (.diesel, 1):
            return LocalizedStringResource("Hay diésel en 1 estación cerca: \(name), a \(away).", comment: "Availability answer: one station with diesel, its name and distance")
        case (.diesel, let count):
            return LocalizedStringResource("Hay diésel en \(count) estaciones cerca. La más cerca es \(name), a \(away).", comment: "Availability answer: several stations with diesel, then the nearest and its distance")
        }
    }

    /// "1 estación sin gasolina": the bad news, collapsed into one row (§6.5).
    var withoutLine: LocalizedStringResource {
        switch fuel {
        case .gasoline: LocalizedStringResource("\(without.count) estaciones sin gasolina", comment: "Collapsed row: how many stations nearby are out of gas")
        case .diesel: LocalizedStringResource("\(without.count) estaciones sin diésel", comment: "Collapsed row: how many stations nearby are out of diesel")
        }
    }

    /// Why older reports are hidden, with the window stated plainly.
    func whyHidden(locale: Locale) -> LocalizedStringResource {
        let hours = Duration.seconds(window).formatted(.units(allowed: [.hours, .minutes], width: .wide).locale(locale))
        return LocalizedStringResource("Escondemos los reportes de más de \(hours), porque cambian rápido.", comment: "Availability: why older fuel reports are hidden, with the window, e.g. '2 horas'")
    }
}

extension FuelStop {
    /// "Fila de unos 20 min": the one extra atom a stop carries.
    var queueLine: LocalizedStringResource? {
        queueMinutes.map { LocalizedStringResource("Fila de unos \($0) min", comment: "Availability: the reported line at the station, in minutes") }
    }

    /// A row's trailing value: "No hay gasolina", the line, or "Hay gasolina".
    func value(for fuel: FuelKind) -> LocalizedStringResource {
        if fuel.negativeKinds.contains(answer.kind) { return answer.kind.word }
        if let queueMinutes {
            return LocalizedStringResource("Fila: \(queueMinutes) min", comment: "Availability row value: the reported line, in minutes")
        }
        return fuel == .gasoline ? ReportKind.hasGas.word : ReportKind.hasDiesel.word
    }

    /// The trust atom: the dispute is the news when neighbours contradict the owner.
    func trust(now: Date) -> TrustSuffix {
        TrustSuffix(
            label: answer.label, freshness: answer.freshness,
            dispute: isDisputed ? .disputed : answer.dispute, stamp: answer.asOf, now: now
        )
    }
}
