import SwiftUI

/// "New to Puerto Rico?" (Flows-VisitorEN): under a station's detail when
/// Biombo reads in English. What DACO is and its range today, the unit
/// switch, and one line on what Biombo is. "Got it" puts it away for good.
struct VisitorGuideCard: View {
    let detail: PlaceDetail
    let tier: DisclosureTier

    @AppStorage(Preferences.visitorGuideDismissed) private var isDismissed = false
    @Environment(\.priceUnit) private var unit
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        if VisitorGuide.shows(on: detail.place?.kind, tier: tier, locale: locale, isCrisis: theme.isCrisis, isDismissed: isDismissed) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(alignment: .firstTextBaseline) {
                    Text("¿Nuevo en Puerto Rico?", comment: "Visitor card title")
                        .textRole(.headline)
                        .foregroundStyle(Color(.ink))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Spacing.s2)
                    Button { isDismissed = true } label: {
                        Text("Entendido", comment: "Visitor card: put it away for good")
                            .frame(minHeight: Size.target)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
                daco
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text("Mostrar precios por", comment: "Visitor card: label over the per litre / per gallon switch")
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink2))
                        .accessibilityHidden(true)
                    PriceUnitPicker(isSegmented: true)
                }
                Text("Biombo muestra lo que reportan los vecinos, junto a las fuentes oficiales.", comment: "Visitor card: what Biombo is")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.s2)
            .insetGroup()
        }
    }

    private var daco: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text("¿Qué es DACO?", comment: "Visitor card: what DACO is")
            } icon: {
                Image(systemName: "building.columns").accessibilityHidden(true)
            }
            .textRole(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.ink))
            Text(explanation)
                .textRole(.subheadline)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var explanation: LocalizedStringResource {
        guard let range = detail.dacoRange else {
            return LocalizedStringResource("La oficina de asuntos del consumidor de Puerto Rico. Publica un precio de referencia cada día.", comment: "Visitor card: DACO explained, with no current range")
        }
        let low = GlanceNumbers.price(range.low, unit: unit, locale: locale)
        let high = GlanceNumbers.price(range.high, unit: unit, locale: locale)
        let today = unit.perUnit(LocalizedStringResource("\(low)–\(high)", comment: "A price range, low to high").string(in: locale)).string(in: locale)
        return LocalizedStringResource("La oficina de asuntos del consumidor de Puerto Rico. Publica un precio de referencia cada día. Hoy, en toda la isla: \(today).", comment: "Visitor card: DACO explained, then today's island-wide range of its regional references, per unit")
    }
}
