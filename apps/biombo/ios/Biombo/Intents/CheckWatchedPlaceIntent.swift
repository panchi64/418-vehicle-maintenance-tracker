import AppIntents
import Foundation

/// "¿Cómo está Casa de Mamá?" (PRODUCT.md §11 `CheckWatchedPlaceIntent`):
/// the same confirmed news the watch list shows, said as one sentence.
/// With no place said ("Cómo están mis lugares"), it answers for every
/// watched place. Sin verificar is never news here, and prices never are (§9).
struct CheckWatchedPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Cómo está un lugar vigilado"
    static let description = IntentDescription("Dice qué cambió en los lugares que vigilas: luz, agua, carreteras y avisos oficiales.")

    @Parameter(title: "Lugar vigilado", description: "Déjalo vacío para oír todos tus lugares.")
    var place: WatchedPlaceEntity?

    @Dependency var context: IntentContext

    static var parameterSummary: some ParameterSummary {
        Summary("Cómo está \(\.$place)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let sentence = await Self.answer(for: place?.id, context: context, locale: .current)
        return .result(value: sentence, dialog: IntentDialog(stringLiteral: sentence))
    }

    /// One watched place when `id` is set, else every one.
    @MainActor
    static func answer(for id: UUID?, context: IntentContext, locale: Locale) async -> String {
        let watched = context.watches.places.filter { id == nil || $0.id == id }
        guard !watched.isEmpty else {
            return id == nil
                ? LocalizedStringResource("Todavía no vigilas ningún lugar.", comment: "Siri: asked about watched places, but none are watched").string(in: locale)
                : LocalizedStringResource("Ya no vigilas ese lugar.", comment: "Siri: the watched place was removed").string(in: locale)
        }
        guard let digest = await context.digest() else {
            return IntentContext.placesFailed(locale: locale)
        }
        let builder = WatchStatusBuilder()
        return sentences(for: watched.map { ($0.name, builder.news(for: $0, digest: digest)) }, now: digest.now, locale: locale)
    }

    /// Each place with news gets its sentence, in the watch list's order;
    /// the quiet ones share one "Todo normal en …" at the end.
    @MainActor
    static func sentences(for places: [(name: String, news: [WatchNews])], now: Date, locale: Locale) -> String {
        let changed = places.filter { !$0.news.isEmpty }.map { sentence(name: $0.name, news: $0.news, now: now, locale: locale) }
        let quiet = places.filter(\.news.isEmpty).map(\.name)
        let normal = quiet.isEmpty ? [] : [sentence(name: quiet.formatted(.list(type: .and).locale(locale)), news: [], now: now, locale: locale)]
        return (changed + normal).map { $0.string(in: locale) }.joined(separator: " ")
    }

    /// "Todo normal en Casa de Mamá." or "En Casa de Mamá: …", every change
    /// joined as one list, most urgent first.
    @MainActor
    static func sentence(name: String, news: [WatchNews], now: Date, locale: Locale) -> LocalizedStringResource {
        guard !news.isEmpty else {
            return LocalizedStringResource("Todo normal en \(name).", comment: "Siri: nothing changed at the watched place (or places, as a list)")
        }
        let changes = news
            .map { $0.sentenceString(now: now, locale: locale).trimmingCharacters(in: CharacterSet(charactersIn: ". ")) }
            .formatted(.list(type: .and).locale(locale))
        return LocalizedStringResource("En \(name): \(changes).", comment: "Siri: the changes at a watched place, joined as a list")
    }
}
