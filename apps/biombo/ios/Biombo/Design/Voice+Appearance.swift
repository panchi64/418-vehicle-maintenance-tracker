import Foundation

/// What Siri says (PRODUCT.md §11): the app's own templates, never a
/// generated answer, and never stale data as current.
extension Layer {
    /// "luz", "agua", "señal": a service as said inside a sentence.
    var spokenNoun: LocalizedStringResource {
        switch self {
        case .water: LocalizedStringResource("agua", comment: "Spoken inside a sentence: running water")
        case .signal: LocalizedStringResource("señal", comment: "Spoken inside a sentence: cell signal")
        default: LocalizedStringResource("luz", comment: "Spoken inside a sentence: electric power")
        }
    }
}

extension ConditionAnswer {
    /// "LUMA dice que partes de Caguas están sin luz desde las 3:10 p. m."
    func sentence(service: Layer, municipio: String, now: Date, locale: Locale) -> LocalizedStringResource {
        let noun = service.spokenNoun.string(in: locale)
        switch self {
        case .noRecent:
            return LocalizedStringResource("No hay reportes recientes de \(noun) en \(municipio).", comment: "Siri: nothing current about a service in a municipio")
        case .restoring:
            return LocalizedStringResource("En partes de \(municipio) el servicio de \(noun) está volviendo.", comment: "Siri: a service is coming back in parts of a municipio")
        case .aging(let status):
            let age = Self.spokenAge(status.area.latestEvidenceAt, now: now, locale: locale)
            return LocalizedStringResource("El último reporte de que no hay \(noun) en \(municipio) es de \(age).", comment: "Siri: an aging outage, said age first, e.g. 'hace 9 horas'")
        case .out(let status):
            let since = status.area.openedAt.islandClock(locale: locale)
            switch status.label {
            case .official(let agency):
                return LocalizedStringResource("\(agency.displayName) dice que partes de \(municipio) están sin \(noun) desde las \(since).", comment: "Siri: an agency says parts of a municipio are without a service since a clock time")
            case .communityConfirmed, .verifiedOwner:
                return LocalizedStringResource("Vecinos confirman que partes de \(municipio) están sin \(noun) desde las \(since).", comment: "Siri: neighbours confirm parts of a municipio are without a service since a clock time")
            case .unverified:
                return LocalizedStringResource("Hay reportes sin confirmar de que partes de \(municipio) están sin \(noun) desde las \(since).", comment: "Siri: unconfirmed reports that parts of a municipio are without a service")
            }
        }
    }

    /// After a voice report: what the agency already says there, when it does.
    func officialLine(service: Layer, municipio: String, locale: Locale) -> LocalizedStringResource? {
        guard case .out(let status) = self, case .official(let agency) = status.label else { return nil }
        let noun = service.spokenNoun.string(in: locale)
        let since = status.area.openedAt.islandClock(locale: locale)
        return LocalizedStringResource("\(agency.displayName) ya reporta sin \(noun) en partes de \(municipio) desde las \(since).", comment: "After a voice report: the agency already reports the outage there, since a clock time")
    }

    /// "hace 9 horas", in full words for speech.
    private static func spokenAge(_ date: Date, now: Date, locale: Locale) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

extension VoiceReport {
    /// "Calle Degetau, Caguas".
    var whereWords: LocalizedStringResource {
        let place = target.place
        if place.displayName == place.municipio {
            return LocalizedStringResource("\(place.municipio)", comment: "Watched place: the municipio alone")
        }
        return LocalizedStringResource("\(place.displayName), \(place.municipio)", comment: "Watched place: barrio, then municipio")
    }

    /// Asked before sending: "¿Envío “Sin luz” en Calle Degetau, Caguas?"
    func question(locale: Locale) -> LocalizedStringResource {
        LocalizedStringResource("¿Envío “\(kind.word.string(in: locale))” en \(whereWords.string(in: locale))?", comment: "Siri asks before sending a voice report: what, then where")
    }

    /// "Listo. Avisamos “Sin luz” en Calle Degetau, Caguas."
    func done(locale: Locale) -> LocalizedStringResource {
        LocalizedStringResource("Listo. Avisamos “\(kind.word.string(in: locale))” en \(whereWords.string(in: locale)).", comment: "Siri: a voice report was sent; what, then where")
    }
}
