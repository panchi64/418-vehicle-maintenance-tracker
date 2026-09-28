import Foundation

/// What VoiceOver reads for map marks: the answer and its label (PRODUCT.md §3
/// "Accessibility"), as full-sentence templates.
enum PinVoice {
    /// "Gasolina, Total Santurce: $1.02. Confirmado hace 1 h"
    static func label(_ answer: PlaceAnswer, now: Date, unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        let trust = TrustSuffix(answer, now: now).text(locale: locale)
        return LocalizedStringResource(
            "\(answer.layer.title), \(answer.place.displayName): \(answer.valueText(unit: unit, locale: locale)). \(trust)",
            comment: "VoiceOver for a map pin: layer, place name, its answer, then its trust suffix"
        )
    }

    /// "Bairoa sigue sin luz. Confirmado hace 35 min"
    static func label(_ status: AreaStatus, now: Date, locale: Locale) -> LocalizedStringResource {
        LocalizedStringResource(
            "\(status.sentence). \(TrustSuffix(status, now: now).text(locale: locale))",
            comment: "VoiceOver for an outage area: its sentence, then its trust suffix"
        )
    }
}
