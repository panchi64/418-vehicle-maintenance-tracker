import SwiftUI

/// Watching's words (PRODUCT.md §9, V2-Watch, Crisis-WatchPlaceSetup).
extension WatchNews {
    /// One sentence per change: the answer the map would give for it, or the
    /// agency's own sentence.
    func sentence(now: Date, locale: Locale) -> Text {
        Text(verbatim: sentenceString(now: now, locale: locale))
    }

    /// The same sentence as plain text, for widgets and Siri.
    func sentenceString(now: Date, locale: Locale) -> String {
        switch self {
        case .warning(let notice), .boilWater(let notice):
            notice.headline
        case .outage(let status):
            status.answerSentence(now: now, locale: locale).string(in: locale)
        case .road(let answer, _):
            answer.eventSentence.string(in: locale)
        }
    }

    /// "Hierve el agua 3 minutos…": an official item's guidance, when actionable.
    var guidance: String? {
        switch self {
        case .warning(let notice), .boilWater(let notice): notice.guidance
        case .outage, .road: nil
        }
    }

    func trust(now: Date) -> TrustSuffix {
        switch self {
        case .warning(let notice), .boilWater(let notice): TrustSuffix(notice, now: now)
        case .outage(let status): TrustSuffix(status, now: now)
        case .road(let answer, _): TrustSuffix(answer, now: now)
        }
    }

    var symbol: String {
        switch self {
        case .warning: "hurricane"
        case .outage(let status): status.glyph
        case .boilWater: "drop.triangle"
        case .road(let answer, _): answer.glyph
        }
    }
}

extension WatchSummary {
    /// "Hay novedades en Casa de Mamá." / "Todo normal en tus 3 lugares."
    func headline(locale: Locale) -> LocalizedStringResource {
        guard !withNews.isEmpty else {
            return hasSharedWarning
                ? LocalizedStringResource("Aparte del aviso, nada ha cambiado en tus \(normalCount) lugares.", comment: "Watch list answer: besides the shared warning, nothing changed at any watched place")
                : LocalizedStringResource("Todo normal en tus \(normalCount) lugares.", comment: "Watch list answer: nothing changed at any watched place; N places")
        }
        let names = withNews.formatted(.list(type: .and).locale(locale))
        return LocalizedStringResource("Hay novedades en \(names).", comment: "Watch list answer: the watched places with news, as a list")
    }

    /// "Tus otros 2 lugares están bien."
    var others: LocalizedStringResource? {
        guard !withNews.isEmpty, normalCount > 0 else { return nil }
        return hasSharedWarning
            ? LocalizedStringResource("En tus otros \(normalCount) lugares no hay otros cambios.", comment: "Watch list answer: the other watched places have nothing besides the shared warning")
            : LocalizedStringResource("Tus otros \(normalCount) lugares están bien.", comment: "Watch list answer: how many other watched places have no news")
    }

    /// A quiet place's row: "Todo normal", or "Sin otros cambios" under a shared warning.
    var normalLabel: LocalizedStringResource {
        hasSharedWarning
            ? LocalizedStringResource("Sin otros cambios", comment: "Watch list row: nothing changed here besides the shared warning")
            : LocalizedStringResource("Todo normal", comment: "Watch list row: nothing changed at this place")
    }
}

extension WatchedPlace {
    /// "Miradero, Mayagüez", or the municipio alone.
    var whereLine: Text {
        Text(whereWords)
    }

    var whereWords: LocalizedStringResource {
        if let barrio, barrio != municipio {
            return LocalizedStringResource("\(barrio), \(municipio)", comment: "Watched place: barrio, then municipio")
        }
        return LocalizedStringResource("\(municipio)", comment: "Watched place: the municipio alone")
    }

    /// What one tap on "Empezar a vigilar" promises, from the layers chosen.
    func promise(locale: Locale) -> LocalizedStringResource {
        guard let topics = topics(locale: locale) else {
            return LocalizedStringResource("Escoge al menos una cosa para vigilar.", comment: "Watch setup answer: nothing chosen yet")
        }
        return LocalizedStringResource("Te avisamos cuando cambien \(topics).", comment: "Watch setup answer: what will be notified, as a list, e.g. 'la luz, el agua y las carreteras cerca'")
    }

    /// "la luz, el agua y las carreteras cerca"; nil when nothing is chosen.
    func topics(locale: Locale) -> String? {
        let chosen = Layer.watchable.filter(layers.contains)
        guard !chosen.isEmpty else { return nil }
        return chosen.map { $0.watchTopic.string(in: locale) }.formatted(.list(type: .and).locale(locale))
    }

    /// The preview notification: how a change here will arrive, scoped to this place.
    var previewTitle: LocalizedStringResource {
        let place = barrio ?? municipio
        switch Layer.watchable.first(where: layers.contains) {
        case .water: return LocalizedStringResource("Aviso de hervir el agua en \(place)", comment: "Preview notification title: a boil-water notice at the watched place")
        case .roads: return LocalizedStringResource("Cerraron una carretera cerca de \(place)", comment: "Preview notification title: a road closed near the watched place")
        default: return LocalizedStringResource("Se fue la luz en \(place)", comment: "Preview notification title: power went out at the watched place")
        }
    }

    var previewBody: LocalizedStringResource {
        LocalizedStringResource("Así te llegará el aviso para \(name). Solo cambios en este lugar, nunca precios.", comment: "Preview notification body: this is how an alert for the named place will arrive")
    }
}

extension Layer {
    /// The layers a watch can follow, in the order the setup lists them (§9).
    static let watchable: [Layer] = [.power, .water, .roads]

    /// "la luz", "el agua", "las carreteras cerca": the watch promise's list items.
    var watchTopic: LocalizedStringResource {
        switch self {
        case .water: LocalizedStringResource("el agua", comment: "Watch promise list item: water")
        case .roads: LocalizedStringResource("las carreteras cerca", comment: "Watch promise list item: roads nearby")
        default: LocalizedStringResource("la luz", comment: "Watch promise list item: power")
        }
    }

    /// The setup toggle's title and its one line of scope.
    var watchTitle: LocalizedStringResource {
        self == .roads ? LocalizedStringResource("Carreteras cerca", comment: "Watch toggle: roads near the place") : title
    }

    var watchScope: LocalizedStringResource {
        switch self {
        case .water: LocalizedStringResource("Incluye avisos de hervir de la AAA", comment: "Watch toggle detail: water includes AAA boil-water notices")
        case .roads: LocalizedStringResource("Cierres, derrumbes e inundaciones a 2 km", comment: "Watch toggle detail: road closures, landslides and floods within 2 km")
        default: LocalizedStringResource("Cuando se va y cuando vuelve", comment: "Watch toggle detail: power going out and coming back")
        }
    }
}
