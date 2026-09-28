import SwiftUI

/// A business's full tier (Contribute-BusinessPublic): the owner's events as
/// dated rows and what they say is in stock, then what neighbours say, as
/// counts with coarse ages only (PRODUCT.md §6.8).
struct BusinessSections: View {
    let detail: PlaceDetail

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            if !detail.events.isEmpty {
                SectionGroup(title: LocalizedStringResource("Eventos", comment: "Section: the owner's upcoming events")) {
                    RowList(elements: detail.events) { event in
                        twoLineRow(Text(verbatim: event.title), Text(when(event)), secondary: .ink2)
                    }
                }
            }
            if !detail.products.isEmpty {
                SectionGroup(title: LocalizedStringResource("Hay", comment: "Section: products the owner says are in stock")) {
                    RowList(elements: detail.products) { product in
                        Text(verbatim: product).textRole(.body).foregroundStyle(Color(.ink))
                            .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                    }
                }
            }
            if !detail.neighbours.isEmpty {
                SectionGroup(title: LocalizedStringResource("Lo que dicen los vecinos", comment: "Section: what community reports say")) {
                    RowList(elements: detail.neighbours) { count in
                        twoLineRow(Text(count.sentence), Text(count.age.text), secondary: .ink3)
                    }
                }
            }
        }
    }

    private func twoLineRow(_ title: Text, _ subtitle: Text, secondary: ColorResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            title.textRole(.body).foregroundStyle(Color(.ink))
            subtitle.textRole(.footnote).foregroundStyle(Color(secondary))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .padding(.vertical, Spacing.s1)
        .accessibilityElement(children: .combine)
    }

    /// "sáb, 3 oct · 8:00 p. m.–11:00 p. m.", in Puerto Rico time.
    private func when(_ event: OwnerEvent) -> LocalizedStringResource {
        let day = event.start.island(.dateTime.weekday(.abbreviated).day().month(.abbreviated), locale: locale)
        let start = event.start.islandClock(locale: locale)
        let end = event.end.islandClock(locale: locale)
        return LocalizedStringResource("\(day) · \(start) a \(end)", comment: "An event's day, then its start and end times")
    }
}

/// An outage area's full tier (V2-Outage): "¿Cuándo vuelve?" as the elapsed
/// time and, only when an agency gave one, its estimate on the restore bar;
/// "¿Dónde no hay luz?" with each barrio's source when the area spans more
/// than its name; then what neighbours say, lined up against the agency on
/// the agreement bar, never averaged into it.
struct AreaSections: View {
    let status: AreaStatus
    let mix: SourceMix
    let reports: [PlaceAnswer]
    let now: Date

    @Environment(\.locale) private var locale

    /// Barrios listed before the rest are left to depth (§6.2).
    static let barrioCap = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            restoreSection
            if mix.barrios.count > 1 {
                SectionGroup(title: status.whereTitle, aside: LocalizedStringResource("\(mix.barrios.count) barrios", comment: "Section aside: how many barrios the area covers")) {
                    RowList(elements: Array(mix.barrios.prefix(Self.barrioCap))) { barrio in
                        barrioRow(barrio)
                    }
                }
            }
            if mix.neighbours > 0 || !reports.isEmpty {
                SectionGroup(title: LocalizedStringResource("Lo que dicen los vecinos", comment: "Section: what community reports say")) {
                    if mix.neighbours > 0 {
                        VStack(alignment: .leading, spacing: Spacing.s3) {
                            Text(mix.headline).textRole(.headline).foregroundStyle(Color(.ink))
                                .fixedSize(horizontal: false, vertical: true)
                            AgreementBar(parts: mix.parts)
                        }
                        .padding(.vertical, Spacing.s3)
                    }
                    if !reports.isEmpty {
                        if mix.neighbours > 0 { RowDivider(isInset: false) }
                        RowList(elements: reports) { ReportRow(answer: $0, now: now) }
                    }
                }
            }
        }
    }

    private func barrioRow(_ barrio: SourceMix.Barrio) -> some View {
        SplitRow {
            Text(verbatim: barrio.name).textRole(.body).foregroundStyle(Color(.ink))
        } trailing: {
            voiceLabel(barrio.voice)
        }
    }

    private func voiceLabel(_ voice: SourceMix.Voice) -> some View {
        Label { Text(voice.title) } icon: { Image(systemName: voice.symbol).accessibilityHidden(true) }
            .textRole(.footnote)
            .foregroundStyle(Color(.ink2))
    }

    private var restoreSection: some View {
        SectionGroup(
            title: LocalizedStringResource("¿Cuándo vuelve?", comment: "Section: when service may come back"),
            aside: status.area.officialAgency.map { LocalizedStringResource("según \($0.displayName)", comment: "Section aside: the estimate comes from this agency") }
        ) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.elapsedSentence(now: now, locale: locale)).textRole(.headline).foregroundStyle(Color(.ink))
                    Text(estimateLine).textRole(.subheadline).foregroundStyle(Color(.ink2))
                }
                .fixedSize(horizontal: false, vertical: true)
                RestoreBar(since: status.area.openedAt, now: now, estimate: officialEstimate)
            }
            .padding(.vertical, Spacing.s3)
        }
    }

    /// A community estimate is never a restore time (§11): only an agency's counts.
    private var officialEstimate: DateInterval? {
        status.area.officialAgency != nil ? status.area.estimatedRestore : nil
    }

    private var estimateLine: LocalizedStringResource {
        guard let estimate = officialEstimate, let agency = status.area.officialAgency else {
            return LocalizedStringResource("Nadie ha dado un estimado de cuándo vuelve.", comment: "Restore headline: no official estimate exists")
        }
        let when = DayWindow(estimate.end, now: now).text(locale: locale)
        return LocalizedStringResource("\(agency.displayName) estima que vuelve \(when).", comment: "Restore headline: the agency's estimate as a window, e.g. 'LUMA estima que vuelve mañana en la tarde.'")
    }
}

extension AreaStatus {
    /// "¿Dónde no hay luz?", per layer.
    var whereTitle: LocalizedStringResource {
        switch layer {
        case .water: LocalizedStringResource("¿Dónde no hay agua?", comment: "Section: which barrios have no water")
        case .signal: LocalizedStringResource("¿Dónde no hay señal?", comment: "Section: which barrios have no signal")
        default: LocalizedStringResource("¿Dónde no hay luz?", comment: "Section: which barrios have no power")
        }
    }

    /// "Lleva 2 h sin luz": the time since the outage began, in whole units.
    func elapsedSentence(now: Date, locale: Locale) -> LocalizedStringResource {
        let seconds = max(now.timeIntervalSince(area.openedAt), 60)
        let allowed: Set<Duration.UnitsFormatStyle.Unit> = seconds < 3_600 ? [.minutes] : seconds < 172_800 ? [.hours] : [.days]
        let elapsed = Duration.seconds(seconds).formatted(
            .units(allowed: allowed, width: .abbreviated, maximumUnitCount: 1, fractionalPart: .hide(rounded: .down)).locale(locale)
        )
        switch layer {
        case .water: return LocalizedStringResource("Lleva \(elapsed) sin agua", comment: "Outage elapsed time: how long the area has had no water, e.g. 'Lleva 2 h sin agua'")
        case .signal: return LocalizedStringResource("Lleva \(elapsed) sin señal", comment: "Outage elapsed time: how long the area has had no signal")
        default: return LocalizedStringResource("Lleva \(elapsed) sin luz", comment: "Outage elapsed time: how long the area has had no power, e.g. 'Lleva 2 h sin luz'")
        }
    }
}
