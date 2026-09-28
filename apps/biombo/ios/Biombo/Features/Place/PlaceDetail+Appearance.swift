import SwiftUI

/// The detail sheet's words: its postcard, its answer sentence, and what the
/// empty state asks for (PRODUCT.md §3 "Empty and stale states say what to do").
extension PlaceDetail {
    var motif: PlateMotif {
        switch subject {
        case .place(let place):
            switch place.kind {
            case .station: .station
            case .charger: .charger
            case .business: .business
            case .roadSegment: .road
            case .area: PlateMotif(region: place.region)
            }
        case .area(let status):
            PlateMotif(region: status.area.region)
        }
    }

    /// "Cayey · 1.2 km", or "Frailes, Guaynabo · 3.4 km" for a named barrio.
    func whereLine(locale: Locale) -> LocalizedStringResource {
        let away = GlanceNumbers.distance(meters: distance, locale: locale)
        if let barrio = place?.barrio, place?.kind != .area, barrio != municipio {
            return LocalizedStringResource("\(barrio), \(municipio) · \(away)", comment: "Detail postcard: barrio, municipio, then distance")
        }
        return LocalizedStringResource("\(municipio) · \(away)", comment: "Detail postcard: municipio, then distance")
    }

    /// The answer as a sentence, for everything except a price hero.
    func sentence(locale: Locale) -> LocalizedStringResource {
        if let area {
            return area.answerSentence(now: now, locale: locale)
        }
        guard let answer else { return emptyHeadline }
        if answer.layer.readsAsPlace {
            if let end = answer.lead.statedEnd, answer.label == .verifiedOwner {
                return LocalizedStringResource("\(answer.kind.word) hasta las \(end.islandClock(locale: locale))", comment: "Owner answer with its stated end, e.g. 'Con planta hasta las 8:00 p. m.'")
            }
            return answer.kind.word
        }
        return answer.eventSentence
    }

    /// Roads never read as safe: with no problem reports the answer is "Sin reportes de problemas" (§6.6).
    var emptyHeadline: LocalizedStringResource {
        layer == .roads
            ? RoadCopy.noProblems
            : LocalizedStringResource("No hay reportes recientes", comment: "Detail answer when nothing current is reported")
    }

    /// One sentence that says what to do.
    var emptyPrompt: LocalizedStringResource {
        switch layer {
        case .gas: LocalizedStringResource("Si pasas por aquí, dinos el precio.", comment: "Empty station: ask for the price")
        case .chargers: LocalizedStringResource("Si pasas por aquí, dinos si funciona.", comment: "Empty charger: ask whether it works")
        case .businesses: LocalizedStringResource("Si pasas por aquí, dinos si está abierto.", comment: "Empty business: ask whether it is open")
        case .roads: LocalizedStringResource("Si pasas por aquí y ves algo, repórtalo.", comment: "Empty road: ask for a report if something is wrong")
        case .power, .water, .signal: LocalizedStringResource("Si estás aquí, dinos cómo está.", comment: "Empty area: ask how it is")
        }
    }

    /// The empty state's one verb.
    var emptyVerb: LocalizedStringResource {
        layer == .gas
            ? LocalizedStringResource("Reportar el precio", comment: "Empty station verb: report the price")
            : LocalizedStringResource("Reportar", comment: "Verb: report something here")
    }

    /// "Detalles del precio" on a station; "Detalles" elsewhere.
    var depthTitle: LocalizedStringResource {
        ladder != nil || trend != nil
            ? LocalizedStringResource("Detalles del precio", comment: "Row into a station's depth: sources, history, older reports")
            : LocalizedStringResource("Detalles", comment: "Row into a place's depth: sources and older reports")
    }

    /// The trust line under the answer.
    var trust: TrustSuffix? {
        if let answer { return TrustSuffix(answer, now: now) }
        if let area { return TrustSuffix(area, now: now) }
        return nil
    }

    var accessibilityName: LocalizedStringResource {
        LocalizedStringResource("\(name), \(municipio)", comment: "VoiceOver: a place, then its municipio")
    }
}
