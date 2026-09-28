import SwiftUI

/// The verbs under a fuel answer (V2-Crisis, V2-FuelGenerator): "Cómo llegar
/// a Puma", then Reportar; only Reportar when nobody has fuel nearby. The
/// crisis home answer and "Gasolina y planta" share it, so both say the same.
struct FuelVerbBar: View {
    /// The station the answer names.
    let station: Place?
    let onReport: () -> Void

    @State private var isOpeningMaps = false

    var body: some View {
        VerbBar(verbs: verbs)
            .openInMaps(isPresented: $isOpeningMaps, destination: station?.anchor ?? GeoPoint(0, 0), name: station?.name ?? "")
    }

    private var verbs: [Verb] {
        let report = Verb(id: "report", title: LocalizedStringResource("Reportar", comment: "Verb: report something here"), symbol: "exclamationmark.bubble", action: onReport)
        guard let station else { return [report] }
        let go = Verb(
            id: "go",
            title: LocalizedStringResource("Cómo llegar a \(station.name)", comment: "Verb: directions to the named station"),
            symbol: "arrow.triangle.turn.up.right.diamond"
        ) { isOpeningMaps = true }
        return [go, report]
    }
}

/// "Abiertos con planta": places open on a generator, or with ice or cooking
/// gas, nearest first and capped (§6.5).
struct GeneratorsSection: View {
    let generators: [NearbyRow]
    let cap: Int
    let now: Date
    let onPick: (NearbyItem) -> Void

    var body: some View {
        if !generators.isEmpty {
            SectionGroup(
                title: LocalizedStringResource("Abiertos con planta", comment: "Section: places open on a generator nearby"),
                aside: LocalizedStringResource("\(generators.count) cerca", comment: "Section aside: how many nearby")
            ) {
                RowList(elements: Array(generators.prefix(cap)), isInset: true) { row in
                    AnswerRow(row: row, grammar: .place, now: now) { onPick(row.item) }
                }
            }
        }
    }
}
