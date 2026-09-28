import AppIntents
import Foundation

/// "¿Dónde está la gasolina más barata?" (PRODUCT.md §11 `CheckFuelIntent`):
/// the gas widget's own pick, said in the user's unit. In crisis it is the
/// nearest station with gas, never a price.
struct CheckFuelIntent: AppIntent {
    static let title: LocalizedStringResource = "Gasolina cerca"
    static let description = IntentDescription("Dice dónde está la gasolina más barata cerca, o en una emergencia, la más cerca que tiene.")

    @Dependency var context: IntentContext

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let sentence = await Self.answer(context: context, unit: PriceUnit.current(), locale: .current)
        return .result(value: sentence, dialog: IntentDialog(stringLiteral: sentence))
    }

    @MainActor
    static func answer(context: IntentContext, unit: PriceUnit, locale: Locale) async -> String {
        guard let digest = await context.digest() else {
            return IntentContext.placesFailed(locale: locale)
        }
        return sentence(GasPick.make(from: digest), unit: unit, locale: locale).string(in: locale)
    }

    @MainActor
    static func sentence(_ pick: GasPick?, unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        guard let pick else {
            return LocalizedStringResource("No hay reportes recientes de gasolina cerca.", comment: "Siri: no current gas answer nearby")
        }
        let station = pick.answer.place.displayName
        let distance = GlanceNumbers.distance(meters: pick.distance, locale: locale)
        guard !pick.isAvailability, let price = pick.answer.price else {
            return LocalizedStringResource("Hay gasolina en \(station), a \(distance).", comment: "Siri in crisis: the nearest station with gas, and how far")
        }
        let spoken = unit.spoken(GlanceNumbers.price(price, unit: unit, locale: locale), grade: price.grade).string(in: locale)
        return LocalizedStringResource("La gasolina más barata cerca está en \(station): \(spoken), a \(distance).", comment: "Siri: the cheapest gas nearby; station, price per unit and grade, distance")
    }
}
