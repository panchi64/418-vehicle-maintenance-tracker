import SwiftUI

/// The full tier's sections, one comparison per layer (PRODUCT.md §3, §6):
/// the price ladder and trend words for gas, ports for chargers, events and
/// neighbours for businesses, the restore bar and "Dónde" for areas, and
/// neighbours' reports and distribution points for outages, water and roads.
struct PlaceFullSections: View {
    let detail: PlaceDetail

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            if let ladder = detail.ladder {
                gasComparison(ladder)
            }
            if !detail.otherGrades.isEmpty {
                SectionGroup(title: LocalizedStringResource("Otros grados", comment: "Section: the station's prices for other fuel grades"), aside: unit.sectionAside) {
                    RowList(elements: detail.otherGrades) { price in
                        valueRow(Text(price.grade.capitalizedTitle), value: Text(verbatim: GlanceNumbers.price(price, unit: unit, locale: locale)))
                    }
                }
            }
            if !detail.alsoReported.isEmpty {
                SectionGroup(title: LocalizedStringResource("También reportaron", comment: "Section: other statuses reported at this station")) {
                    RowList(elements: detail.alsoReported) { ReportRow(answer: $0, now: detail.now) }
                }
            }
            if !detail.ports.isEmpty {
                SectionGroup(title: LocalizedStringResource("Conectores", comment: "Section: the charger's connectors and their status")) {
                    RowList(elements: detail.ports) { status in
                        valueRow(Text(status.port.title), value: Text(status.status?.word ?? LocalizedStringResource("Sin reportes", comment: "A connector nobody reported on recently")))
                    }
                }
            }
            if !detail.events.isEmpty || !detail.products.isEmpty || !detail.neighbours.isEmpty {
                BusinessSections(detail: detail)
            }
            if let area = detail.area, let mix = detail.sourceMix {
                AreaSections(status: area, mix: mix, reports: detail.fullNeighbourReports, now: detail.now)
            } else if detail.listsNeighbourReports {
                SectionGroup(title: LocalizedStringResource("Lo que dicen los vecinos", comment: "Section: what community reports say")) {
                    RowList(elements: detail.fullNeighbourReports) { ReportRow(answer: $0, now: detail.now) }
                }
            }
            if !detail.waterPoints.isEmpty {
                SectionGroup(title: LocalizedStringResource("Dónde hay agua", comment: "Section: water distribution points in the municipio")) {
                    RowList(elements: detail.waterPoints) { point in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: point.place.displayName).textRole(.body).foregroundStyle(Color(.ink))
                            TrustSuffixLabel(suffix: TrustSuffix(point, now: detail.now))
                        }
                        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                        .padding(.vertical, Spacing.s1)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    /// "¿Buen precio?": the headline in words, then the ladder; the trend in words below.
    private func gasComparison(_ ladder: PriceLadder) -> some View {
        SectionGroup(title: LocalizedStringResource("¿Buen precio?", comment: "Section: how this station's price compares")) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    if let headline = ladder.headline(unit: unit) {
                        Text(headline).textRole(.headline).foregroundStyle(Color(.ink))
                    }
                    if let cheapest = ladder.cheapestLine {
                        Text(cheapest).textRole(.subheadline).foregroundStyle(Color(.ink2))
                    }
                    if let published = ladder.publishedOn, !PuertoRico.calendar.isDate(published, inSameDayAs: detail.now) {
                        Text("Referencia del \(published.island(.dateTime.day().month(.abbreviated), locale: locale))", comment: "DACO's reference is not today's: its date")
                            .textRole(.footnote).foregroundStyle(Color(.inkStale))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                PriceLadderView(ladder: ladder)
                if let trend = detail.trend {
                    Label {
                        Text(trend.headline(unit: unit))
                    } icon: {
                        Image(systemName: trend.symbol(unit: unit)).accessibilityHidden(true)
                    }
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, Spacing.s3)
        }
    }

    private func valueRow(_ title: Text, value: Text) -> some View {
        SplitRow {
            title.textRole(.body).foregroundStyle(Color(.ink))
        } trailing: {
            value.textRole(.value).foregroundStyle(Color(.ink))
        }
    }
}
