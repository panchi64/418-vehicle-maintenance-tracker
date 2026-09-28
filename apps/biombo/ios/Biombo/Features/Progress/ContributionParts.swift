import SwiftUI

/// "Tu reporte ayudó a 38 personas" (§10): the cotorra sketch, the number
/// as the sentence's hero, what and when, and what the number means.
/// Feedback only; it earns nothing. No sketch in crisis or at accessibility
/// sizes (direction §1.1), where the text takes the whole width.
struct HelpedCard: View {
    let report: MyReport
    let now: Date
    let showsArt: Bool

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s4) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Tu reporte ayudó a \(report.helped) personas", comment: "Tu aporte: how many people one report helped; plural by count")
                    .textRole(.answer)
                    .foregroundStyle(Color(.ink))
                    .fixedSize(horizontal: false, vertical: true)
                Text("“\(report.report.kind.word)” en \(report.placeName), \(AgePhrase(since: report.report.capturedAt, now: now).text(locale: locale))", comment: "Tu aporte: the report that helped, where, and when")
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Son las personas que lo vieron mientras estaba reciente, no las veces que se abrió.", comment: "Tu aporte: what the helped count means")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if showsArt {
                InkVignette(image: .vignetteCotorra, points: 72)
            }
        }
        .padding(Spacing.s4)
        .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.plate))
        .contrastEdge()
        .accessibilityElement(children: .combine)
    }
}

/// "Tus reportes recientes": the newest three, then "Ver todos (N)".
struct RecentReportsSection: View {
    let summary: ContributionSummary
    let now: Date

    var body: some View {
        if !summary.reports.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                SectionGroup(title: LocalizedStringResource("Tus reportes recientes", comment: "Tu aporte section: your newest reports")) {
                    RowList(elements: summary.recent, isInset: true) { MyReportRow(report: $0, now: now) }
                }
                if summary.hasMore {
                    NavigationLink {
                        AllReportsView(reports: summary.reports, now: now)
                    } label: {
                        DisclosureLabel(title: LocalizedStringResource("Ver todos (\(summary.reports.count))", comment: "See all of your reports, with the count"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// One of your reports: what and where, then what became of it.
struct MyReportRow: View {
    let report: MyReport
    let now: Date

    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .body) private var pinSize = Size.listPin

    var body: some View {
        HStack(spacing: Spacing.s3) {
            LayerPin(layer: report.report.layer, glyph: report.report.kind.glyph, size: pinSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.title)
                    .textRole(.body)
                    .foregroundStyle(Color(.ink))
                Label { Text(report.outcomeLine(now: now, locale: locale)) } icon: { Image(systemName: report.outcomeSymbol).accessibilityHidden(true) }
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.s2)
        .frame(minHeight: Size.target)
        .accessibilityElement(children: .combine)
    }
}

/// Every report, newest first.
struct AllReportsView: View {
    let reports: [MyReport]
    let now: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RowList(elements: reports, isInset: true) { MyReportRow(report: $0, now: now) }
            }
            .insetGroup()
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .background(Color(.paperSheet))
        .navigationTitle(Text("Tus reportes", comment: "Title: all of your reports"))
    }
}

/// "Cómo se sube de nivel": points come from outcomes, never from sending,
/// and what each level is. Levels bring recognition only.
struct LevelsExplainer: View {
    let progress: Progress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                SectionGroup(title: LocalizedStringResource("Cómo ganas puntos", comment: "Levels explainer: how points are earned")) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        rule(LocalizedStringResource("+3 cuando otros confirman tu reporte.", comment: "Points rule: +3 for a confirmed report"))
                        rule(LocalizedStringResource("+1 por el primer reporte confirmado del día.", comment: "Points rule: +1 for the first confirmed report of the day"))
                        rule(LocalizedStringResource("+1 cuando tu voto coincide con lo que se resolvió.", comment: "Points rule: +1 for a vote that matched the resolution"))
                        rule(LocalizedStringResource("−2 si un reporte tuyo se retira. Tu nivel no baja.", comment: "Points rule: -2 for a removed report; the level never drops"))
                        rule(LocalizedStringResource("Hasta 15 puntos al día. Enviar no da puntos; los peligros solo cuentan cuando se confirman.", comment: "Points rule: daily cap; sending earns nothing; hazards count only when confirmed"))
                    }
                    .padding(.vertical, Spacing.s3)
                }
                SectionGroup(title: LocalizedStringResource("Los niveles", comment: "Levels explainer: the levels")) {
                    RowList(elements: Progress.Level.allCases, isInset: false) { level in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.title).textRole(.body).foregroundStyle(Color(.ink))
                                Text(level.reachedBy).textRole(.footnote).foregroundStyle(Color(.ink2))
                            }
                            Spacer(minLength: Spacing.s2)
                            if level == progress.level {
                                Label { Text("Tu nivel", comment: "Level state: your current level") } icon: { Image(systemName: "checkmark.circle.fill") }
                                    .textRole(.footnote)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.vertical, Spacing.s2)
                        .frame(minHeight: Size.target)
                        .accessibilityElement(children: .combine)
                    }
                }
                Text("Los niveles son un reconocimiento. No cambian cuánto pesa lo que reportas.", comment: "Levels explainer: levels never change a report's weight")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .background(Color(.paperSheet))
        .navigationTitle(Text("Cómo se sube de nivel", comment: "Tu aporte: how levels and points work"))
    }

    private func rule(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .textRole(.body)
            .foregroundStyle(Color(.ink))
            .fixedSize(horizontal: false, vertical: true)
    }
}
