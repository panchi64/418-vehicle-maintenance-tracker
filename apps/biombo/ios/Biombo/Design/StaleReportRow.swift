import SwiftUI

/// One older report behind "Ver reportes anteriores" (PRODUCT.md §4.4): its
/// age first, in stale ink with the clock symbol, then what it said and that
/// it may have changed. It never reads as current and never feeds the answer.
struct StaleReportRow: View {
    let answer: PlaceAnswer
    let now: Date

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TrustSuffixLabel(suffix: TrustSuffix(answer, now: now))
            Text(answer.said(unit: unit, locale: locale))
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
            Text("Puede haber cambiado.", comment: "Under an older report: it may no longer be true")
                .textRole(.footnote)
                .foregroundStyle(Color(.inkStale))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .padding(.vertical, Spacing.s1)
        .accessibilityElement(children: .combine)
    }
}

/// "Ver reportes anteriores (N)" that reveals the older rows in place, and
/// "Ocultar reportes anteriores" to fold them again (Flows-StaleState). The
/// trailing chevron says which way the row moves.
struct StaleReportsGroup: View {
    let stale: [PlaceAnswer]
    let now: Date
    @Binding var isRevealed: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isRevealed {
                ForEach(stale, id: \.lead.id) { answer in
                    StaleReportRow(answer: answer, now: now)
                    RowDivider(isInset: false)
                }
                DisclosureRow(
                    title: LocalizedStringResource("Ocultar reportes anteriores", comment: "Row that folds older reports away again"),
                    symbol: "clock.arrow.circlepath",
                    accessory: .collapse
                ) { isRevealed = false }
            } else {
                DisclosureRow(
                    title: LocalizedStringResource("Ver reportes anteriores (\(stale.count))", comment: "Row that reveals older reports; they never feed the answer"),
                    symbol: "clock.arrow.circlepath",
                    accessory: .expand
                ) { isRevealed = true }
            }
        }
        .insetGroup()
    }
}

/// DACO's reference with its source line (§6.1): in a station's depth, and
/// in its empty state so a price can still be judged.
struct DacoReferenceGroup: View {
    let reference: PriceLadder.Reference

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        SectionGroup(title: LocalizedStringResource("Referencia de DACO", comment: "Depth section: DACO's reference behind the comparison")) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(reference.line(unit: unit, locale: locale)).textRole(.body).foregroundStyle(Color(.ink))
                Text("Fuente: DACO. Biombo no está afiliado con DACO.", comment: "DACO source line; never implies DACO endorses or sets prices")
                    .textRole(.footnote).foregroundStyle(Color(.ink3))
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, Spacing.s3)
        }
    }
}
