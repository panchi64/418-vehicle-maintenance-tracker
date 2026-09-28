import SwiftUI

/// "Modo emergencia": why it is on, since when, what changes and how it ends
/// (PRODUCT.md §8). Plain copy, SF only, no art.
struct CrisisInfoView: View {
    let crisis: CrisisState
    let now: Date

    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 28

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(headline)
                        .textRole(.answer)
                        .foregroundStyle(Color(.ink))
                    if !crisis.municipios.isEmpty {
                        Text("En \(crisis.municipios.formatted(.list(type: .and).locale(locale))).", comment: "Crisis: the municipios a declaration names, as a list")
                            .textRole(.subheadline)
                            .foregroundStyle(Color(.ink2))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                SectionGroup(title: LocalizedStringResource("Por qué", comment: "Crisis section: why the mode is on")) {
                    RowList(elements: crisis.triggers) { trigger in
                        line(symbol: trigger.symbol, text: trigger.reason)
                    }
                }
                SectionGroup(title: LocalizedStringResource("Qué cambia", comment: "Crisis section: what the mode changes")) {
                    RowList(elements: CrisisCopy.changes) { change in
                        line(symbol: change.symbol, text: change.text)
                    }
                }
                Text(CrisisCopy.howItEnds(isDeclared: crisis.triggers.contains(.declaration)))
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .navigationTitle(Text(CrisisCopy.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    /// "Modo emergencia desde hace 6 h."
    private var headline: LocalizedStringResource {
        guard let since = crisis.since else {
            return LocalizedStringResource("Modo emergencia está activo.", comment: "Crisis headline without a start time")
        }
        return LocalizedStringResource("Modo emergencia desde \(AgePhrase(since: since, now: now).text(locale: locale)).", comment: "Crisis headline: since when, e.g. 'desde hace 6 h'")
    }

    private func line(symbol: String, text: LocalizedStringResource) -> some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            // One column for every symbol, so each line's words start at the same x.
            Image(systemName: symbol).frame(width: iconWidth).accessibilityHidden(true)
        }
        .textRole(.body)
        .foregroundStyle(Color(.ink))
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .padding(.vertical, Spacing.s1)
    }
}
