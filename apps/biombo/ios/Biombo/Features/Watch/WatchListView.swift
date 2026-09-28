import SwiftUI

/// "Lugares que vigilas" (V2-Watch): one sentence naming which places have
/// news, those places with each change and its source, then the quiet ones
/// as "Todo normal" rows. Tapping a place edits its watch.
struct WatchListView: View {
    let overview: WatchOverview
    let now: Date
    let isFull: Bool
    let onEdit: (WatchedPlace) -> Void
    let onWatchAnother: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    /// Changes shown per place before the rest are left to its detail (§3 caps).
    static let newsCap = 3

    /// Every change as the rows say it: the on-device summary's only input.
    private var facts: [String] {
        let shared = overview.sharedWarnings.map { WatchNews.warning($0).sentenceString(now: now, locale: locale) }
        return shared + overview.statuses.flatMap { status in
            status.news.map { "\(status.place.name): \($0.sentenceString(now: now, locale: locale))" }
        }
    }

    /// Tapping a place opens its watch setup.
    private static let editHint = Text("Cambia qué vigilas aquí", comment: "VoiceOver hint on a watched place: activating edits the watch")

    var body: some View {
        let summary = overview.summary
        let withNews = overview.statuses.filter { !$0.isNormal }
        let normal = overview.statuses.filter(\.isNormal)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    if summary.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.s1) {
                            Text(summary.headline(locale: locale)).textRole(.answer).foregroundStyle(Color(.ink))
                            if let others = summary.others {
                                Text(others).textRole(.answerSmall).foregroundStyle(Color(.ink2))
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityElement(children: .combine)
                        ChangeSummary(facts: facts)
                    }
                    ForEach(overview.sharedWarnings) { warning in
                        OfficialCard(group: AgencyNotices(agency: warning.agency, notices: [warning]), now: now)
                    }
                    if !withNews.isEmpty {
                        SectionGroup(title: LocalizedStringResource("Con novedades", comment: "Watch list section: places with news")) {
                            RowList(elements: withNews) { status in
                                Button { onEdit(status.place) } label: { WatchNewsCard(status: status, now: now, cap: Self.newsCap) }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Self.editHint)
                            }
                        }
                    }
                    if !normal.isEmpty {
                        SectionGroup(title: LocalizedStringResource("Sin novedades", comment: "Watch list section: places with nothing new")) {
                            RowList(elements: normal) { status in
                                Button { onEdit(status.place) } label: { normalRow(status.place, label: summary.normalLabel) }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Self.editHint)
                            }
                        }
                    }
                    if !summary.isEmpty && !isFull {
                        Button(action: onWatchAnother) {
                            DisclosureLabel(title: LocalizedStringResource("Vigilar otro lugar", comment: "Watch list: find another place to watch"), symbol: "plus")
                                .insetGroup()
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Solo te avisamos de luz, agua y carreteras. Nunca precios.", comment: "Watch list footer: what notifies and what never does")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink3))
                        .fixedSize(horizontal: false, vertical: true)
                    if !summary.isEmpty {
                        SiriTip(intent: CheckWatchedPlaceIntent(), storageKey: Preferences.watchListSiriTip)
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.vertical, Spacing.s4)
            }
            .navigationTitle(Text("Lugares que vigilas", comment: "Title: the watch list"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text("Listo", comment: "Done: close this screen") }
                }
            }
        }
    }

    /// One sentence and one verb (§3 "Empty states say what to do").
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Todavía no vigilas ningún lugar. Busca la casa de alguien o una estación y toca Vigilar.", comment: "Watch list empty state")
                .textRole(.answerSmall)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            VerbBar(verbs: [Verb(id: "find", title: LocalizedStringResource("Buscar un lugar", comment: "Watch list empty verb: search for a place"), symbol: "magnifyingglass", action: onWatchAnother)])
        }
    }

    private func normalRow(_ place: WatchedPlace, label: LocalizedStringResource) -> some View {
        SplitRow(stackedSpacing: Spacing.s1) {
            names(place)
        } trailing: {
            normalLabel(label)
        }
        .padding(.vertical, Spacing.s2)
        .contentShape(.rect)
    }

    private func names(_ place: WatchedPlace) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: place.name).textRole(.body).foregroundStyle(Color(.ink))
            place.whereLine.textRole(.footnote).foregroundStyle(Color(.ink2))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func normalLabel(_ label: LocalizedStringResource) -> some View {
        Label { Text(label) } icon: {
            Image(systemName: "checkmark.circle").accessibilityHidden(true)
        }
        .textRole(.subheadline)
        .foregroundStyle(Color(.ink2))
    }
}

/// A watched place with news: its name, then each change with its source.
private struct WatchNewsCard: View {
    let status: WatchStatus
    let now: Date
    let cap: Int

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: status.place.name).placeTitle()
                status.place.whereLine.textRole(.footnote).foregroundStyle(Color(.ink2))
            }
            ForEach(Array(status.news.prefix(cap).enumerated()), id: \.offset) { _, news in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    Image(systemName: news.symbol).foregroundStyle(Color(.ink2)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        news.sentence(now: now, locale: locale).textRole(.body).foregroundStyle(Color(.ink))
                        if let guidance = news.guidance {
                            Text(verbatim: guidance).textRole(.subheadline).foregroundStyle(Color(.ink2))
                        }
                        TrustSuffixLabel(suffix: news.trust(now: now))
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
