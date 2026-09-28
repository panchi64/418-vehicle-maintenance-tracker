import SwiftUI

/// Words, symbols and ink for ages and trust suffixes (PRODUCT.md §3 "Row budget").
extension AgePhrase {
    func text(locale: Locale) -> LocalizedStringResource {
        switch self {
        case .now:
            LocalizedStringResource("ahora", comment: "Age: less than a minute ago")
        case .minutes(let minutes):
            LocalizedStringResource("hace \(minutes) min", comment: "Age: minutes ago, abbreviated")
        case .hours(let hours):
            LocalizedStringResource("hace \(hours) h", comment: "Age: hours ago, abbreviated")
        case .yesterday:
            LocalizedStringResource("ayer", comment: "Age: yesterday")
        case .date(let date):
            LocalizedStringResource("el \(date.island(.dateTime.day().month(.abbreviated), locale: locale))", comment: "Age: on a calendar date, e.g. 'el 24 sept.'")
        }
    }
}

extension Date {
    /// This date in Puerto Rico's time zone and the given language, whatever
    /// the device's zone and language: "3:10 p. m.", "domingo", "24 sept.".
    nonisolated func island(_ style: Date.FormatStyle, locale: Locale) -> String {
        var style = style
        style.locale = locale
        style.timeZone = PuertoRico.timeZone
        style.calendar = PuertoRico.calendar
        return formatted(style)
    }

    /// "3:10 p. m." in Puerto Rico time, as one unbreakable atom.
    nonisolated func islandClock(locale: Locale) -> String {
        island(Date.FormatStyle(date: .omitted, time: .shortened), locale: locale).unbroken
    }
}

extension TrustSuffix {
    func text(locale: Locale) -> LocalizedStringResource {
        switch phrase {
        case .confirmed(let age):
            LocalizedStringResource("Confirmado \(age.text(locale: locale))", comment: "Trust suffix: confirmed by neighbours, then an age such as 'hace 12 min'")
        case .unverified(let age):
            LocalizedStringResource("Sin verificar · \(age.text(locale: locale))", comment: "Trust suffix: nobody confirmed this yet, then an age")
        case .owner(let age):
            LocalizedStringResource("Dueño verificado · \(age.text(locale: locale))", comment: "Trust suffix: the verified owner posted this, then an age")
        case .official(let agency, .today(let date)):
            LocalizedStringResource("Oficial · \(agency.displayName), \(date.islandClock(locale: locale))", comment: "Trust suffix: official, the agency, then when it published: a clock time today, else a day such as ayer")
        case .official(let agency, .earlier(let age)):
            LocalizedStringResource("Oficial · \(agency.displayName), \(age.text(locale: locale))", comment: "Trust suffix: official, the agency, then when it published: a clock time today, else a day such as ayer")
        case .disputed(let age):
            LocalizedStringResource("Vecinos no coinciden · \(age.text(locale: locale))", comment: "Trust suffix: neighbours dispute this report, then an age")
        case .stale(let age):
            LocalizedStringResource("Reportado \(age.text(locale: locale))", comment: "Trust suffix on an older report shown on request, age first")
        }
    }

    /// "Confirmado por 6 vecinos · hace 12 min": the count shows in detail only.
    func detailText(locale: Locale) -> LocalizedStringResource {
        if case .confirmed(let age) = phrase, case .communityConfirmed(let neighbours) = label, neighbours > 0 {
            return LocalizedStringResource("Confirmado por \(neighbours) vecinos · \(age.text(locale: locale))", comment: "Detail trust line: confirmed by N neighbours, then an age")
        }
        return text(locale: locale)
    }

    var symbol: String {
        switch (tone, phrase) {
        case (_, .disputed): "exclamationmark.triangle"
        case (_, .stale): "clock.arrow.circlepath"
        case (.aging, _): "clock"
        default: label.symbol
        }
    }

    /// Quiet suffixes recede; promoted ones take their label's ink, except
    /// age and disputes, which take caution ink.
    var ink: ColorResource {
        switch (tone, phrase) {
        case (.stale, _): .inkStale
        case (.news, .disputed), (.aging, _): .statusCaution
        case (.news, _): label.ink
        case (.quiet, _): .ink3
        }
    }
}

/// One trust atom: symbol plus phrase, never colour alone.
struct TrustSuffixLabel: View {
    let suffix: TrustSuffix
    /// Detail screens add the neighbour count (§4.5 "N vecinos in detail").
    var isDetail = false
    @Environment(\.locale) private var locale

    var body: some View {
        Label {
            Text(isDetail ? suffix.detailText(locale: locale) : suffix.text(locale: locale))
        } icon: {
            Image(systemName: suffix.symbol)
                .accessibilityHidden(true)
        }
        .labelStyle(.titleAndIcon)
        .textRole(.footnote)
        .fontWeight(suffix.isPromoted ? .medium : .regular)
        .foregroundStyle(Color(suffix.ink))
        .fixedSize(horizontal: false, vertical: true)
    }
}
