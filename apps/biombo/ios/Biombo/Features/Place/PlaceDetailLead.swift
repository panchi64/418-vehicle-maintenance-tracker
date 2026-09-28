import SwiftUI

/// The top of a detail sheet, which peek is measured to (V2-Station): the
/// name, then the answer and its trust line. At peek the name is a quiet
/// serif line and the trust line leads with the distance; from summary the
/// name sits on its postcard with where it is, and the trust line gains the
/// neighbour count. The ••• menu and Cerrar sit at the trailing edge.
struct PlaceDetailLead: View {
    let detail: PlaceDetail
    let tier: DisclosureTier
    var owner: PlaceMoreMenu.OwnerItem = .none
    let onReport: () -> Void
    let onClose: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(alignment: .top, spacing: Spacing.s2) {
                header
                PlaceMoreMenu(detail: detail, owner: owner, onReport: onReport)
                CloseButton(action: onClose)
            }
            VStack(alignment: .leading, spacing: Spacing.s1) {
                hero
                trustLine
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var header: some View {
        if tier == .peek {
            Text(verbatim: detail.name)
                .placeTitle()
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        } else {
            PostcardStrip(
                title: Text(verbatim: detail.name),
                subtitle: Text(detail.whereLine(locale: locale)),
                motif: detail.motif
            )
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let price = detail.answer?.price {
            let amount = GlanceNumbers.price(price, unit: unit, locale: locale)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
                Text(verbatim: amount)
                    .textRole(.hero)
                    .foregroundStyle(Color(.ink))
                Text(unit.heroSuffix(price.grade))
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(unit.spoken(amount, grade: price.grade)))
            if VisitorGuide.showsPumpPrice(in: unit) {
                let litre = GlanceNumbers.price(price, unit: .litre, locale: locale)
                Text("\(litre) el litro, como lo marca la bomba", comment: "Under a price in gallons: the per-litre price pumps in Puerto Rico show")
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
            }
        } else {
            Text(detail.sentence(locale: locale))
                .textRole(.answer)
                .foregroundStyle(Color(detail.isEmpty ? .ink2 : .ink))
                .fixedSize(horizontal: false, vertical: true)
            if let reliability = detail.reliability, detail.answer != nil {
                Label { Text(reliability.text) } icon: { Image(systemName: reliability.symbol).accessibilityHidden(true) }
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
            }
        }
    }

    @ViewBuilder
    private var trustLine: some View {
        if let trust = detail.trust {
            if tier == .peek {
                let away = GlanceNumbers.distance(meters: detail.distance, locale: locale)
                HStack(spacing: Spacing.s2) {
                    Text(verbatim: away)
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                    TrustSuffixLabel(suffix: trust)
                }
            } else {
                TrustSuffixLabel(suffix: trust, isDetail: true)
            }
        }
    }
}
