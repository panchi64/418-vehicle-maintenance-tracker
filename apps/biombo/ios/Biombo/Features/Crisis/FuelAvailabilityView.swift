import SwiftUI

/// "Gasolina y planta" (PRODUCT.md §6.5, V2-FuelGenerator): the Disponibilidad
/// mode of Gasolina. The Gasolina / Diésel switch, the answer ("Hay gasolina
/// en 2 estaciones cerca…"), Cómo llegar and Reportar, the other stations,
/// bad news collapsed into one row, older reports with why they are hidden,
/// then the places open on a generator.
struct FuelAvailabilityView: View {
    let availability: AvailabilityDigest
    let isCrisis: Bool
    let now: Date
    let onPick: (NearbyItem) -> Void
    let onReport: () -> Void

    @State private var fuel: FuelKind = .gasoline
    @State private var isWithoutShown = false
    @State private var isOlderShown = false
    @Environment(\.locale) private var locale

    var body: some View {
        let current = availability.fuel(fuel)
        let cap = DisclosureTier.full.rowCap(isCrisis: isCrisis)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Picker(selection: $fuel) {
                    ForEach(FuelKind.allCases, id: \.self) { Text($0.title).tag($0) }
                } label: {
                    Text("Combustible", comment: "VoiceOver: the gasoline or diesel switch")
                }
                .pickerStyle(.segmented)

                answer(current)
                FuelVerbBar(station: current.lead?.place, onReport: onReport)

                let others = Array(current.others(cap: cap))
                if !others.isEmpty || !current.without.isEmpty {
                    SectionGroup(title: fuel.hasTitle) {
                        RowList(elements: others, isInset: true) { stop in
                            FuelStopRow(stop: stop, fuel: fuel, now: now) { onPick(.place(stop.answer)) }
                        }
                        if !current.without.isEmpty {
                            if !others.isEmpty { RowDivider() }
                            DisclosureRow(title: current.withoutLine, accessory: isWithoutShown ? .collapse : .expand) { isWithoutShown.toggle() }
                            if isWithoutShown {
                                RowList(elements: current.without, isInset: true) { stop in
                                    FuelStopRow(stop: stop, fuel: fuel, now: now) { onPick(.place(stop.answer)) }
                                }
                            }
                        }
                    }
                }
                if !current.older.isEmpty {
                    olderGroup(current)
                }
                GeneratorsSection(generators: availability.generators, cap: cap, now: now, onPick: onPick)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .navigationTitle(Text("Gasolina y planta", comment: "Screen title: fuel and generator availability"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    /// The answer, then the lead's line and trust under it.
    private func answer(_ current: FuelAvailability) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(current.answer(locale: locale))
                .textRole(.answer)
                .foregroundStyle(Color(.ink))
            if let lead = current.lead {
                HStack(spacing: Spacing.s2) {
                    if let queue = lead.queueLine {
                        Text(queue).textRole(.footnote).foregroundStyle(Color(.ink2))
                    }
                    TrustSuffixLabel(suffix: lead.trust(now: now))
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func olderGroup(_ current: FuelAvailability) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            VStack(spacing: 0) {
                DisclosureRow(
                    title: LocalizedStringResource("Ver reportes anteriores (\(current.older.count))", comment: "Row that reveals older reports; they never feed the answer"),
                    symbol: "clock.arrow.circlepath",
                    accessory: isOlderShown ? .collapse : .expand
                ) { isOlderShown.toggle() }
                if isOlderShown {
                    RowDivider()
                    RowList(elements: current.older, isInset: true) { row in
                        AnswerRow(row: row, grammar: .place, now: now) { onPick(row.item) }
                    }
                }
            }
            .insetGroup()
            Text(current.whyHidden(locale: locale))
                .textRole(.footnote)
                .foregroundStyle(Color(.ink3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
