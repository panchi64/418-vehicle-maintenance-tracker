import AppIntents
import Foundation

/// "¿Hay luz en Caguas?" (PRODUCT.md §11 `CheckConditionIntent`). The answer
/// is the app's own template over current areas: who says what, since
/// when, or that nothing recent is known. With no municipio said, it is
/// the one where you stand.
struct CheckConditionIntent: AppIntent {
    static let title: LocalizedStringResource = "Consultar un servicio"
    static let description = IntentDescription("Dice si hay luz, agua o señal en un municipio, según las fuentes oficiales y los vecinos.")

    /// Luz unless said: "Pregúntale a Biombo si hay luz" names no parameter,
    /// so without a default Siri would still ask which service.
    @Parameter(title: "Servicio", default: .power, requestValueDialog: "¿Luz, agua o señal?")
    var service: CheckedService

    @Parameter(title: "Municipio", description: "Déjalo vacío para preguntar por donde estás.")
    var municipio: MunicipioEntity?

    @Dependency var context: IntentContext

    static var parameterSummary: some ParameterSummary {
        Summary("¿Hay \(\.$service) en \(\.$municipio)?")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let sentence = await Self.answer(service.layer, in: municipio?.id, context: context, locale: .current)
        return .result(value: sentence, dialog: IntentDialog(stringLiteral: sentence))
    }

    /// The spoken answer; tests call it without Siri.
    @MainActor
    static func answer(_ layer: Layer, in municipio: String?, context: IntentContext, locale: Locale) async -> String {
        guard let snapshot = await context.snapshot(),
              let name = municipio ?? snapshot.municipio(nearest: snapshot.vantage) else {
            return IntentContext.placesFailed(locale: locale)
        }
        let digest = IntentContext.digest(of: snapshot)
        return ConditionAnswer.make(service: layer, municipio: name, areas: digest.areas)
            .sentence(service: layer, municipio: name, now: digest.now, locale: locale)
            .string(in: locale)
    }
}
