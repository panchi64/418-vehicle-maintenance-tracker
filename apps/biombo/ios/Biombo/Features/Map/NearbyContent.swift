import SwiftUI

/// "Cerca de ti" below the answer: the watched places' news when there is
/// any, official cards (after the answer on ordinary days, first of all
/// sections in crisis), then the sections the tier allows, each capped with
/// "Ver todas (N)". In crisis the order is Oficial → Vecinos → Lugares (§8):
/// services and roads, then fuel and generators, then the rest.
struct NearbyContent: View {
    let digest: HomeDigest
    let tier: DisclosureTier
    let revealedStale: Set<NearbySection.Kind>
    /// "Hay novedades en Casa de Mamá.", when places are watched.
    let watchLine: LocalizedStringResource?
    let onReveal: (NearbySection.Kind) -> Void
    let onPick: (NearbyItem) -> Void
    let onOpenWatchList: () -> Void
    let onReport: () -> Void

    var body: some View {
        let nearby = digest.nearby
        let sections = Array(nearby.sections(for: tier))
        let services = nearby.isCrisis ? sections.filter { [.services, .roads].contains($0.kind) } : []
        VStack(alignment: .leading, spacing: nearby.isCrisis ? Spacing.s7 : Spacing.s8) {
            // Crisis: the answer's verbs come right under it (V2-Crisis, §3 verbs).
            if nearby.isCrisis {
                FuelVerbBar(station: nearby.nearestFuelStation, onReport: onReport)
            }
            // Ordinary days put the people you watch first; crisis puts officials first (§8).
            if !nearby.isCrisis { watchBanner }
            if !nearby.officials.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    SectionHeader(title: LocalizedStringResource("Avisos oficiales", comment: "Section title: official notices"))
                    ForEach(nearby.officials) { OfficialCard(group: $0, now: digest.now) }
                }
            }
            if nearby.isCrisis { watchBanner }
            ForEach(services) { sectionView($0) }
            if nearby.isCrisis {
                if digest.visibleLayers.contains(.roads), nearby.section(.roads) == nil {
                    // Never "pasable": with nothing reported the answer is only that (§6.6).
                    SectionGroup(title: NearbySection.Kind.roads.title) {
                        Label { Text(RoadCopy.noProblems) } icon: { Image(systemName: Layer.roads.symbol).accessibilityHidden(true) }
                            .textRole(.body)
                            .foregroundStyle(Color(.ink))
                            .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                    }
                }
                if digest.visibleLayers.contains(.gas) {
                    FuelSummarySection(availability: digest.availability, now: digest.now, onPick: onPick)
                }
            }
            ForEach(sections.filter { !services.contains($0) }) { sectionView($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var watchBanner: some View {
        if let watchLine {
            Button(action: onOpenWatchList) {
                StatusBanner(symbol: "eye", title: LocalizedStringResource("Lugares que vigilas", comment: "Title: the watch list"), detail: watchLine)
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionView(_ section: NearbySection) -> some View {
        NearbySectionView(
            section: section,
            cap: tier.rowCap(isCrisis: digest.nearby.isCrisis),
            dacoRange: digest.nearby.dacoRange,
            now: digest.now,
            isStaleRevealed: revealedStale.contains(section.kind),
            onReveal: { onReveal(section.kind) },
            onPick: onPick
        )
    }
}

/// One section: header, capped rows, "Ver todas (N)", then older reports on request.
struct NearbySectionView: View {
    let section: NearbySection
    let cap: Int
    /// Today's DACO range; only the gas section shows it.
    let dacoRange: DacoRange?
    let now: Date
    let isStaleRevealed: Bool
    /// The full list shows the title in its navigation bar instead.
    var showsHeader = true
    let onReveal: () -> Void
    let onPick: (NearbyItem) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        let shown = Array(section.shownRows(cap: cap))
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if showsHeader {
                SectionHeader(title: section.kind.title, aside: aside)
            }
            if let dacoLine {
                Text(dacoLine)
                    .textRole(.subheadline)
                    .foregroundStyle(Color(.ink2))
            }
            VStack(spacing: 0) {
                rows(shown)
                let overflow = section.overflowCount(cap: cap)
                if overflow > 0 {
                    RowDivider()
                    NavigationLink(value: SheetRoute.section(section.kind)) {
                        DisclosureLabel(title: LocalizedStringResource("Ver todas (\(overflow))", comment: "Row that opens the whole section; N is the total"))
                    }
                    .buttonStyle(.plain)
                }
                if section.kind == .cheapestGas, showsHeader {
                    // Disponibilidad is one tap away inside Gasolina (§6.5).
                    RowDivider()
                    NavigationLink(value: SheetRoute.availability) {
                        DisclosureLabel(title: LocalizedStringResource("¿Dónde hay gasolina y planta?", comment: "Row into the fuel and generator availability screen from the gas prices section"))
                    }
                    .buttonStyle(.plain)
                }
                if !section.staleRows.isEmpty {
                    if !shown.isEmpty { RowDivider() }
                    if isStaleRevealed {
                        rows(section.staleRows)
                    } else {
                        DisclosureRow(
                            title: LocalizedStringResource("Ver reportes anteriores (\(section.staleRows.count))", comment: "Row that reveals older reports; they never feed the answer"),
                            symbol: "clock.arrow.circlepath",
                            accessory: .expand,
                            action: onReveal
                        )
                    }
                }
            }
            .insetGroup()
            if (shown + (isStaleRevealed ? section.staleRows : [])).contains(where: \.item.isFlood) {
                SafetyLine(kind: .flood)
            }
        }
    }

    private func rows(_ rows: [NearbyRow]) -> some View {
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
            if index > 0 { RowDivider() }
            AnswerRow(row: row, grammar: section.grammar, now: now) { onPick(row.item) }
        }
    }

    private var aside: LocalizedStringResource? {
        switch section.kind {
        case .cheapestGas: unit.sectionAside
        case .roads: LocalizedStringResource("\(section.rows.count) avisos", comment: "Section aside: how many road events")
        default: nil
        }
    }

    /// "Referencia de DACO hoy: $1–$1.02", never called an official or legal price (§6.1).
    private var dacoLine: LocalizedStringResource? {
        guard section.kind == .cheapestGas, let dacoRange else { return nil }
        let low = GlanceNumbers.price(dacoRange.low, unit: unit, locale: locale)
        let high = GlanceNumbers.price(dacoRange.high, unit: unit, locale: locale)
        return low == high
            ? LocalizedStringResource("Referencia de DACO hoy: \(low)", comment: "DACO's reference price today, one value")
            : LocalizedStringResource("Referencia de DACO hoy: \(low)–\(high)", comment: "DACO's reference price range today across brands")
    }
}
