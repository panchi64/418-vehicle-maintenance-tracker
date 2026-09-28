import Foundation

/// The outage's source words (V2-Outage): who says it's out, barrio by
/// barrio, and how neighbours and the agency line up. Never averaged (§3).
extension SourceMix {
    /// "31 vecinos lo confirman; nadie ha dicho que volvió." It asks the bar's
    /// one question, still out or back, with the bar's own counts. Where
    /// neighbours sit against the agency's outline is "¿Dónde no hay luz?"'s job.
    var headline: LocalizedStringResource {
        saidBack == 0
            ? LocalizedStringResource("\(stillOut) vecinos lo confirman; nadie ha dicho que volvió.", comment: "Outage agreement headline: N neighbours confirm, nobody reported it back")
            : LocalizedStringResource("\(stillOut) vecinos lo confirman; \(saidBack) dicen que volvió.", comment: "Outage agreement headline: N neighbours confirm, M say it came back")
    }

    /// The agreement bar's parts: still out, then "volvió".
    var parts: [AgreementBar.Part] {
        [
            .init(
                id: "still", count: stillOut, pattern: .solid, symbol: "person.2.fill",
                label: LocalizedStringResource("\(stillOut) dicen que sigue igual", comment: "Agreement bar: neighbours saying the outage continues")
            ),
            .init(
                id: "back", count: saidBack, pattern: .dotted, symbol: "arrow.uturn.backward",
                label: LocalizedStringResource("\(saidBack) dicen que volvió", comment: "Agreement bar: neighbours saying service came back")
            ),
        ]
    }
}

extension SourceMix.Voice {
    var title: LocalizedStringResource {
        switch self {
        case .official(let agency): LocalizedStringResource("\(agency.displayName) lo confirma", comment: "Barrio source: the agency confirms the outage there")
        case .neighbours: LocalizedStringResource("Solo vecinos", comment: "Barrio source: only neighbours report the outage there")
        }
    }

    var symbol: String {
        switch self {
        case .official: "building.columns"
        case .neighbours: "person.2.fill"
        }
    }
}

extension AreaTimeline {
    /// "LUMA avisó 12 min después del primer vecino."
    func headline(locale: Locale) -> LocalizedStringResource? {
        guard let officialLag, let agency = entries.lazy.compactMap(\.agency).first else { return nil }
        let lag = Duration.seconds(max(officialLag, 60)).formatted(
            .units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 1).locale(locale)
        )
        return LocalizedStringResource("\(agency.displayName) avisó \(lag) después del primer vecino.", comment: "Outage timeline headline: how long after the first neighbour the agency spoke")
    }
}

extension AreaTimeline.Entry {
    var agency: Agency? {
        if case .official(let agency) = event { agency } else { nil }
    }

    var title: LocalizedStringResource {
        switch event {
        case .firstNeighbour: LocalizedStringResource("Primer vecino reporta", comment: "Outage timeline: the first neighbour's report")
        case .official(let agency): LocalizedStringResource("Aviso de \(agency.displayName)", comment: "Outage timeline: the agency's notice")
        case .latestConfirmation: LocalizedStringResource("Última confirmación", comment: "Outage timeline: the latest confirmation")
        }
    }
}
