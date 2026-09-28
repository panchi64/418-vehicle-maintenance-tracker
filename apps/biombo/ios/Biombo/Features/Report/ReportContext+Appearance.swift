import SwiftUI

/// Quick Report's first words: where the report will land, said before any
/// choice (direction §3.6). One sentence, then where and how far.
extension ReportContext {
    func leadSentence(locale: Locale) -> LocalizedStringResource {
        if let outage, standsInOutage {
            switch outage.layer {
            case .water: return LocalizedStringResource("Estás dentro de un área sin agua.", comment: "Quick Report context: you stand inside a water outage")
            case .signal: return LocalizedStringResource("Estás dentro de un área sin señal.", comment: "Quick Report context: you stand inside a signal outage")
            default: return LocalizedStringResource("Estás dentro de un área sin luz.", comment: "Quick Report context: you stand inside a power outage")
            }
        }
        guard let lead else {
            return LocalizedStringResource("No sabemos en qué barrio estás.", comment: "Quick Report context: nothing in reach to report on")
        }
        guard lead.isInReach else {
            let away = GlanceNumbers.distance(meters: lead.distance, locale: locale)
            return LocalizedStringResource("Estás a \(away) de \(lead.place.displayName).", comment: "Quick Report context: the place is too far to report on")
        }
        switch lead.place.kind {
        case .area:
            return LocalizedStringResource("Estás en \(lead.place.displayName), \(lead.place.municipio).", comment: "Quick Report context: the barrio and municipio you stand in")
        default:
            return LocalizedStringResource("Estás en \(lead.place.displayName).", comment: "Quick Report context: the place you are at")
        }
    }

    /// The second line: where and how far, or why nothing can be sent.
    func whereLine(locale: Locale) -> LocalizedStringResource? {
        guard let lead else {
            return LocalizedStringResource("Acércate a un lugar para reportarlo.", comment: "Quick Report context: move closer to a place to report it")
        }
        guard lead.isInReach else {
            return LocalizedStringResource("Solo quien está cerca puede reportar.", comment: "Quick Report context: only people nearby can report")
        }
        guard lead.place.kind != .area else { return nil }
        let away = GlanceNumbers.distance(meters: lead.distance, locale: locale)
        return LocalizedStringResource("\(lead.place.municipio) · a \(away)", comment: "Quick Report context: municipio, then how far the place is")
    }

    /// The title over the sheet: "Reportar en Puma Los Filtros".
    var title: LocalizedStringResource {
        if let lead, lead.isInReach {
            return LocalizedStringResource("Reportar en \(lead.place.displayName)", comment: "Quick Report title: report at the named place")
        }
        return LocalizedStringResource("Reportar aquí", comment: "Map control: report something where you are")
    }
}

extension ReportTarget {
    /// Cambiar's row: the place and how far it is.
    func distanceLine(locale: Locale) -> LocalizedStringResource {
        let away = GlanceNumbers.distance(meters: distance, locale: locale)
        return LocalizedStringResource("a \(away)", comment: "Distance to a place, e.g. 'a 200 m'")
    }
}

extension Layer {
    /// "¿Sobre qué quieres avisar?" rows that need a place say which kind.
    var reachHint: LocalizedStringResource? {
        switch self {
        case .gas: LocalizedStringResource("Acércate a una gasolinera", comment: "Quick Report: gas needs a station within reach")
        case .chargers: LocalizedStringResource("Acércate a un cargador", comment: "Quick Report: chargers need one within reach")
        case .businesses: LocalizedStringResource("Acércate a un negocio", comment: "Quick Report: businesses need one within reach")
        case .roads: LocalizedStringResource("Acércate a la carretera", comment: "Quick Report: roads need one within reach")
        case .power, .water, .signal: nil
        }
    }
}
