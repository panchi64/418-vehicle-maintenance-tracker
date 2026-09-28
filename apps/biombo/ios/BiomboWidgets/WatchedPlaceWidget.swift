import AppIntents
import SwiftUI
import WidgetKit

/// A watched place (Flows-SystemSurfaces "Mi barrio"): its name, then each
/// confirmed change with its source, or "Todo normal". Past its freshness
/// it says "Sin reportes recientes" rather than keeping old news (§11).
/// Tapping opens the watch list.
struct WatchedPlaceWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "com.418-studio.biombo.widget.watched", intent: WatchedPlaceWidgetIntent.self, provider: WatchedPlaceProvider()) { entry in
            WatchedPlaceWidgetView(entry: entry)
                .containerBackground(Color(.paperRaised), for: .widget)
        }
        .configurationDisplayName(Text("Lugar vigilado", comment: "Watched place widget name"))
        .description(Text("Si hay luz, agua y carreteras en un lugar que vigilas.", comment: "Watched place widget description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WatchedPlaceWidgetView: View {
    let entry: WatchedPlaceEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Button(intent: OpenBiomboScreenIntent(target: .watchList)) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if let place = entry.place {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: place.name)
                        .font(.system(.headline, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(verbatim: place.whereLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !place.isFresh(at: entry.date) {
                    NoRecentReports()
                } else if place.lines.isEmpty {
                    Label {
                        Text(verbatim: place.normalLine)
                    } icon: {
                        Image(systemName: "checkmark.circle")
                    }
                    .font(.subheadline.weight(.medium))
                } else {
                    let shown = family == .systemSmall ? 1 : 3
                    ForEach(Array(place.lines.prefix(shown).enumerated()), id: \.offset) { _, line in
                        GlanceLineView(line: line)
                    }
                }
                Spacer(minLength: 0)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text("Lugar vigilado", comment: "Watched place widget name")
                } icon: {
                    Image(systemName: "eye")
                }
                .font(.headline)
                Text("Vigila un lugar en Biombo para verlo aquí.", comment: "Watched place widget: nothing watched yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
