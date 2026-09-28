import SwiftUI

/// "Tu aporte" (PRODUCT.md §10, Contribute-Progress, DirC-Progress). Glance
/// question: what's my level and what's next? The report that helped most
/// lately, then the level with its five sketches, three numbers and the
/// newest reports. Private: no leaderboard, no comparison. In crisis, and at
/// accessibility text sizes, the art goes (direction §1.1); in crisis a line
/// says progress waits.
struct ContributionView: View {
    let now: Date
    let isCrisis: Bool

    @Environment(ContributionStore.self) private var contributions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Sketches and vignettes show only on an ordinary day at ordinary text sizes.
    private var showsArt: Bool { !isCrisis && !typeSize.isAccessibilitySize }

    var body: some View {
        let summary = ContributionSummary(reports: contributions.history, votes: contributions.votes.all, now: now)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    if isCrisis {
                        Label {
                            Text("Modo emergencia: el progreso está en pausa. Reporta solo lo que veas.", comment: "Tu aporte in crisis: progress waits; report only what you see")
                        } icon: {
                            Image(systemName: "pause.circle").accessibilityHidden(true)
                        }
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink))
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    if let highlight = summary.highlight {
                        HelpedCard(report: highlight, now: now, showsArt: showsArt)
                    }
                    level(summary.progress)
                    numbers(summary.progress)
                    RecentReportsSection(summary: summary, now: now)
                    Text("Tu nivel es privado: nadie más lo ve y no hay tablas de posiciones. Solo cuentan los reportes que otros confirman.", comment: "Tu aporte: the level is private, there are no leaderboards, only confirmed reports count")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.vertical, Spacing.s4)
            }
            .background(Color(.paperSheet))
            .navigationTitle(Text("Tu aporte", comment: "Title: your contributions and level"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text("Listo", comment: "Done: close this screen") }
                }
            }
        }
    }

    /// "Tu nivel · 3 de 5", the level's name in New York, the sketches, and what's next.
    private func level(_ progress: Progress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text("Tu nivel · \(progress.level.rawValue) de \(Progress.Level.allCases.count)", comment: "Tu aporte: your level out of all levels")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
            Text(progress.level.name)
                .textRole(isCrisis ? .answer : .placeName)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if showsArt {
                LevelLadder(progress: progress)
            }
            Text(progress.nextLine)
                .textRole(.body)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                LevelsExplainer(progress: progress)
            } label: {
                DisclosureLabel(title: LocalizedStringResource("Cómo se sube de nivel", comment: "Tu aporte: how levels and points work"), symbol: "questionmark.circle")
            }
            .buttonStyle(.plain)
        }
    }

    /// Three numbers, with the unit said once each (§3 "Numbers for
    /// glancing"). They stack at accessibility sizes.
    private func numbers(_ progress: Progress) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s3))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.s4))
        return layout {
            // The unit is its own word under the number, so one and many are separate strings.
            metric(progress.sentReports, progress.sentReports == 1
                   ? LocalizedStringResource("reporte", comment: "Tu aporte metric unit under the number 1: one report sent")
                   : LocalizedStringResource("reportes", comment: "Tu aporte metric unit under a number other than 1: reports sent"))
            metric(progress.confirmedReports, progress.confirmedReports == 1
                   ? LocalizedStringResource("confirmado", comment: "Tu aporte metric unit under the number 1: one report others confirmed")
                   : LocalizedStringResource("confirmados", comment: "Tu aporte metric unit under a number other than 1: reports others confirmed"))
            if let since = progress.since {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: since.island(.dateTime.month(.wide), locale: locale))
                        .textRole(.metric)
                        .foregroundStyle(Color(.ink))
                    Text("desde", comment: "Tu aporte metric unit: reporting since a month")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Reportas desde \(since.island(.dateTime.month(.wide).year(), locale: locale))", comment: "VoiceOver: reporting since a month"))
            }
        }
    }

    private func metric(_ value: Int, _ unit: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number)
                .textRole(.metric)
                .foregroundStyle(Color(.ink))
            Text(unit)
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
