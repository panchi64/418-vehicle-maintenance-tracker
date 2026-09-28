import SwiftUI

/// "Qué cambió" over the watch list: one on-device sentence across every
/// watched change, labelled "Resumen automático" (PRODUCT.md §11). Where
/// Apple Intelligence isn't available, in crisis, or with a single change,
/// it shows nothing: the rows below already say each change.
struct ChangeSummary: View {
    /// The changes as the list says them, one sentence each.
    let facts: [String]

    @State private var summary: String?
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let summary {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Label {
                        Text("Resumen automático", comment: "Label on an on-device model summary")
                    } icon: {
                        Image(systemName: "sparkles").accessibilityHidden(true)
                    }
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
                    Text(verbatim: summary)
                        .textRole(.body)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
        .task(id: Request(facts: facts, locale: locale, isCrisis: theme.isCrisis)) {
            // An old summary never stands in for the new facts while they load.
            summary = nil
            let isModelAvailable = OnDeviceSummarizer.isAvailable(for: locale)
            guard SummaryGate.shouldSummarize(factCount: facts.count, isModelAvailable: isModelAvailable, isCrisis: theme.isCrisis) else { return }
            summary = await OnDeviceSummarizer.summarize(facts, locale: locale)
        }
    }

    /// What a summary is made from: new facts, another language or a crisis starting ask again.
    private struct Request: Hashable {
        let facts: [String]
        let locale: Locale
        let isCrisis: Bool
    }
}
