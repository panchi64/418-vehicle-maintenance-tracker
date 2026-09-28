import SwiftUI

/// A station row in "Gasolina y planta": a place row whose trailing value is
/// availability, never a price (§8: prices step back), and whose trust atom
/// says when neighbours dispute the owner.
struct FuelStopRow: View {
    let stop: FuelStop
    let fuel: FuelKind
    let now: Date
    let action: () -> Void

    var body: some View {
        AnswerRow(
            row: NearbyRow(item: .place(stop.answer), distance: stop.distance),
            grammar: .place,
            now: now,
            trustOverride: stop.trust(now: now),
            value: stop.value(for: fuel),
            action: action
        )
    }
}
