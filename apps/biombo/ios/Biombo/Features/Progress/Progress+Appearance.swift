import SwiftUI

/// Tu aporte's words (PRODUCT.md §10): level names in Puerto Rican Spanish,
/// what each one is, and the ink sketch each one fills with wash.
extension Progress.Level {
    var name: LocalizedStringResource {
        switch self {
        case .one: LocalizedStringResource("Vecino", comment: "Level 1 name: neighbour")
        case .two: LocalizedStringResource("Vecino atento", comment: "Level 2 name: attentive neighbour")
        case .three: LocalizedStringResource("Guardián de la cuadra", comment: "Level 3 name: guardian of the block")
        case .four: LocalizedStringResource("Voz del barrio", comment: "Level 4 name: voice of the barrio")
        case .five: LocalizedStringResource("Guardián del barrio", comment: "Level 5 name: guardian of the barrio")
        }
    }

    /// "Nivel 3 · Guardián de la cuadra".
    var title: LocalizedStringResource {
        LocalizedStringResource("Nivel \(rawValue) · \(name)", comment: "A level: its number, then its name")
    }

    /// How a level is reached, in points (Qué cambia con cada nivel).
    var reachedBy: LocalizedStringResource {
        self == .one
            ? LocalizedStringResource("Con tu primer reporte.", comment: "Level 1: reached with the first report")
            : LocalizedStringResource("Con \(threshold) puntos.", comment: "A level: reached at this many points")
    }

    /// The sketch that gains its wash when the level is reached.
    var vignette: ImageResource {
        switch self {
        case .one: .vignetteCoqui
        case .two: .vignettePalma
        case .three: .vignetteFlamboyan
        case .four: .vignetteGarita
        case .five: .vignetteFarol
        }
    }
}

extension Progress {
    /// "Te faltan 12 puntos para Voz del barrio", or the top reached.
    var nextLine: LocalizedStringResource {
        guard let next = level.next, let points = pointsToNextLevel else {
            return LocalizedStringResource("Llegaste al último nivel. Gracias por cuidar tu barrio.", comment: "Tu aporte: the top level is reached")
        }
        return LocalizedStringResource("Te faltan \(points) puntos para \(next.name).", comment: "Tu aporte: points left to the next level, plural by count")
    }
}

extension MyReport {
    /// "Inundada: PR-52, km 14".
    var title: LocalizedStringResource {
        LocalizedStringResource("\(report.kind.word): \(placeName)", comment: "Tu aporte row: what was reported, then where")
    }

    /// "Ayudó a 112 personas · ayer", or what became of it.
    func outcomeLine(now: Date, locale: Locale) -> LocalizedStringResource {
        let age = AgePhrase(since: report.capturedAt, now: now).text(locale: locale)
        switch outcome {
        case .confirmed where helped > 0:
            return LocalizedStringResource("Ayudó a \(helped) personas · \(age)", comment: "Tu aporte row: how many people it helped, then when; plural by count")
        case .confirmed:
            return LocalizedStringResource("Confirmado · \(age)", comment: "Tu aporte row: confirmed by others, then when")
        case .waiting:
            return LocalizedStringResource("Esperando confirmación · \(age)", comment: "Tu aporte row: nobody has confirmed it yet, then when")
        case .resolvedAgainst:
            return LocalizedStringResource("Los vecinos dijeron que no · \(age)", comment: "Tu aporte row: neighbours voted against it, then when")
        case .removed(let reason):
            return LocalizedStringResource("Reporte retirado · \(reason.text)", comment: "Tu aporte row: the report was removed, then why")
        case .late:
            return LocalizedStringResource("Llegó tarde; quedó en el historial · \(age)", comment: "Tu aporte row: it arrived after its window, then when")
        }
    }

    var outcomeSymbol: String {
        switch outcome {
        case .confirmed: "person.2.fill"
        case .waiting: "questionmark.circle"
        case .resolvedAgainst, .removed: "xmark.circle"
        case .late: "clock"
        }
    }
}

extension RemovalReason {
    /// The fixed reasons a reviewer picks from (§5), as the reporter reads them.
    var text: LocalizedStringResource {
        switch self {
        case .mismatch: LocalizedStringResource("no coincidía con otros reportes", comment: "Removal reason: didn't match other reports")
        case .wrongPlace: LocalizedStringResource("lugar equivocado", comment: "Removal reason: wrong place")
        case .duplicate: LocalizedStringResource("duplicado", comment: "Removal reason: duplicate")
        case .inappropriate: LocalizedStringResource("contenido inapropiado", comment: "Removal reason: inappropriate content")
        case .resolved: LocalizedStringResource("ya se resolvió", comment: "Removal reason: resolved")
        }
    }
}
