import Foundation

/// The connection banner's words (PRODUCT.md §4.6, Crisis-Offline): the
/// newest data's age first, then what waits for signal.
extension ConnectionStatus {
    var title: LocalizedStringResource {
        switch self {
        case .online: LocalizedStringResource("Conectado", comment: "Connection: online")
        case .weak: LocalizedStringResource("Señal débil", comment: "Connection: a weak or constrained network")
        case .offline: LocalizedStringResource("Sin conexión", comment: "Connection: offline")
        }
    }
}

extension ConnectionState {
    var symbol: String {
        switch status {
        case .online: "wifi"
        case .weak: "wifi.exclamationmark"
        case .offline: "wifi.slash"
        }
    }

    var title: LocalizedStringResource { status.title }

    /// "Datos de hace 40 min · 2 reportes esperan señal".
    func detail(pending: Int, locale: Locale) -> LocalizedStringResource {
        let age = AgePhrase(since: lastSyncedAt, now: now).text(locale: locale)
        switch (status, pending) {
        case (.weak, 0):
            return LocalizedStringResource("Cargamos primero luz, agua y carreteras.", comment: "Weak signal banner: utilities load first")
        case (.weak, _):
            return LocalizedStringResource("Enviando \(pending) reportes", comment: "Weak signal banner: queued reports are being sent")
        case (_, 0):
            return LocalizedStringResource("Datos de \(age)", comment: "Offline banner: how old the newest data is, e.g. 'Datos de hace 40 min'")
        default:
            return LocalizedStringResource("Datos de \(age) · \(pending) reportes esperan señal", comment: "Offline banner: data age, then how many reports wait for signal")
        }
    }

    /// "Esto es lo último que vimos, a las 5:30 p. m."
    func lastSeenSentence(locale: Locale) -> LocalizedStringResource {
        switch status {
        case .weak:
            LocalizedStringResource("Cargamos primero luz, agua y carreteras. Lo demás es de las \(lastSyncedAt.islandClock(locale: locale)).", comment: "Weak signal: utilities load first; the rest is from a clock time")
        case .online, .offline:
            LocalizedStringResource("Esto es lo último que vimos, a las \(lastSyncedAt.islandClock(locale: locale)). Lo que ya no está al día no se muestra.", comment: "Offline: the data shown is from the last sync; anything past its window is hidden")
        }
    }
}

extension QueuedReport {
    /// "Calle Betances, Guaynabo · 4:22 p. m.", with the day when it wasn't today.
    func whereAndWhen(now: Date, locale: Locale) -> LocalizedStringResource {
        let when = PuertoRico.calendar.isDate(capturedAt, inSameDayAs: now)
            ? capturedAt.islandClock(locale: locale)
            : capturedAt.island(.dateTime.weekday(.abbreviated).hour().minute(), locale: locale)
        return LocalizedStringResource("\(placeName) · \(when)", comment: "Queued report: where, then the capture time")
    }
}
