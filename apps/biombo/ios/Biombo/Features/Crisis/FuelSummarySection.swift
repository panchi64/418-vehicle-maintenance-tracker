import SwiftUI

/// Crisis home's places (V2-Crisis): prices step back, so Gasolina says where
/// there is fuel. The answer already names the nearest station, so this
/// lists the others, then who is open on a generator, capped at 3 each, and
/// hands off to "Gasolina y planta" for the rest.
struct FuelSummarySection: View {
    let availability: AvailabilityDigest
    let now: Date
    let onPick: (NearbyItem) -> Void

    private let cap = DisclosureTier.summary.rowCap(isCrisis: true)

    var body: some View {
        let gasoline = availability.gasoline
        let others = Array(gasoline.others(cap: cap))
        VStack(alignment: .leading, spacing: Spacing.s7) {
            if !others.isEmpty {
                SectionGroup(title: FuelKind.gasoline.hasTitle) {
                    RowList(elements: others, isInset: true) { stop in
                        FuelStopRow(stop: stop, fuel: .gasoline, now: now) { onPick(.place(stop.answer)) }
                    }
                }
            }
            GeneratorsSection(generators: availability.generators, cap: cap, now: now, onPick: onPick)
            NavigationLink(value: SheetRoute.availability) {
                DisclosureLabel(title: LocalizedStringResource("Ver gasolina y planta", comment: "Row into the fuel and generator availability screen"), symbol: "fuelpump")
                    .insetGroup()
            }
            .buttonStyle(.plain)
        }
    }
}
