import SwiftUI

/// One current report in a detail's list: what it said, then its trust line.
struct ReportRow: View {
    let answer: PlaceAnswer
    let now: Date
    /// Depth spells the trust line out in full.
    var isDetail = false

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(answer.said(unit: unit, locale: locale)).textRole(.body).foregroundStyle(Color(.ink))
            TrustSuffixLabel(suffix: TrustSuffix(answer, now: now), isDetail: isDetail)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .padding(.vertical, Spacing.s1)
        .accessibilityElement(children: .combine)
    }
}
