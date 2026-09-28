import Foundation
import WidgetKit

/// The widgets' timeline over the app's snapshot: an entry now and one at
/// each moment something shown goes stale, so a widget turns to "Sin
/// reportes recientes" on time without waiting for the app. The app
/// reloads every timeline whenever it writes a new snapshot.
nonisolated enum GlanceTimeline {
    static func dates(for snapshot: WidgetSnapshot?, from now: Date) -> [Date] {
        [now] + (snapshot?.expiries(after: now) ?? [])
    }
}

/// One moment of a widget: the snapshot as of `date`.
struct GlanceEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    /// The gallery's preview: an invented example.
    static var placeholder: GlanceEntry {
        GlanceEntry(
            date: .now,
            snapshot: WidgetSnapshot(
                writtenAt: .now,
                isCrisis: false,
                gas: GasGlance(
                    value: "$0.99", unit: "/L", compact: "$0.99/L", station: "Puma", whereLine: "Bo. Pueblo · 0.8 km",
                    asOfClock: Date.now.formatted(date: .omitted, time: .shortened), spoken: "", freshUntil: .distantFuture
                ),
                watched: [
                    WatchGlance(
                        id: UUID(),
                        name: String(localized: "Casa de Mamá", comment: "Widget gallery example: a watched place's name"),
                        whereLine: "Miradero, Mayagüez",
                        lines: [GlanceLine(
                            symbol: "bolt.slash.fill",
                            text: String(localized: "Sin luz desde las 3:10 p. m.", comment: "Widget gallery example: a power outage line"),
                            source: String(localized: "Oficial · LUMA", comment: "Widget gallery example: the source of a line")
                        )],
                        normalLine: String(localized: "Todo normal", comment: "Watch list row: nothing changed at this place"),
                        freshUntil: .distantFuture
                    )
                ]
            )
        )
    }
}

/// "Gasolina cerca" needs no configuration.
struct GasProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        completion(context.isPreview ? .placeholder : GlanceEntry(date: .now, snapshot: WidgetSnapshot.load(from: SharedContainer.defaults)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load(from: SharedContainer.defaults)
        let entries = GlanceTimeline.dates(for: snapshot, from: .now).map { GlanceEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .never))
    }
}
