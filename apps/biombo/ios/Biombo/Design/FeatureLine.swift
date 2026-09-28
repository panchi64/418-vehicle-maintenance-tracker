import SwiftUI

/// One promise on a first-run page: a symbol, a short title and one line
/// (Flows-Onboarding1, Onboarding3). Reads as one VoiceOver element.
struct FeatureLine: View {
    let symbol: String
    let title: LocalizedStringResource
    let text: LocalizedStringResource

    @ScaledMetric(relativeTo: .body) private var mark = Size.listPin

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: mark, height: mark)
                .background(Color(.fill), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textRole(.headline)
                    .foregroundStyle(Color(.ink))
                Text(text)
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
