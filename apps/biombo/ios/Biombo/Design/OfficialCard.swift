import SwiftUI

/// One flat card per agency (PRODUCT.md §3): set apart by sobriety, not volume.
/// Each notice is its own block: agency · time, one sentence, and its guidance
/// line only when there is something to do, directly under the notice it
/// belongs to. A hairline separates notices so guidance never reads as
/// covering its neighbour. Never art.
struct OfficialCard: View {
    let group: AgencyNotices
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            ForEach(Array(group.notices.enumerated()), id: \.element.id) { index, notice in
                if index > 0 {
                    RowDivider(isInset: false)
                }
                NoticeBlock(notice: notice, now: now)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
        .contrastEdge()
        .overlay(alignment: .leading) {
            // The slate hairline that marks official items, on the leading edge.
            UnevenRoundedRectangle(topLeadingRadius: Radius.medium, bottomLeadingRadius: Radius.medium)
                .fill(Color(.verifyOfficial))
                .frame(width: 3)
                .accessibilityHidden(true)
        }
    }
}

/// One notice: its source and time, its sentence, and its guidance if any.
private struct NoticeBlock: View {
    let notice: OfficialNotice
    let now: Date
    @Environment(\.locale) private var locale

    var body: some View {
        let trust = TrustSuffix(notice, now: now)
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Label {
                Text(trust.text(locale: locale))
            } icon: {
                Image(systemName: trust.symbol)
                    .accessibilityHidden(true)
            }
            .textRole(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.verifyOfficial))

            Text(verbatim: notice.headline)
                .textRole(.callout)
                .foregroundStyle(Color(.ink))
            if let guidance = notice.guidance {
                Label {
                    Text(verbatim: guidance)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                        .accessibilityHidden(true)
                }
                .textRole(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(.ink2))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}
