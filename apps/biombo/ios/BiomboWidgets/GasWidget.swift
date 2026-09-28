import SwiftUI
import WidgetKit

/// "Gasolina cerca" (Flows-SystemSurfaces): the cheapest current price near
/// you, or in crisis the nearest station with gas. Past its freshness it
/// says "Sin reportes recientes" rather than keeping an old price (§11).
struct GasWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.418-studio.biombo.widget.gas", provider: GasProvider()) { entry in
            GasWidgetView(entry: entry)
                .containerBackground(Color(.paperRaised), for: .widget)
        }
        .configurationDisplayName(Text("Gasolina cerca", comment: "Gas widget name"))
        .description(Text("La gasolina más barata cerca de ti, o dónde hay en una emergencia.", comment: "Gas widget description"))
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

struct GasWidgetView: View {
    let entry: GlanceEntry

    @Environment(\.widgetFamily) private var family

    private var glance: GasGlance? {
        entry.snapshot?.gas.flatMap { $0.isFresh(at: entry.date) ? $0 : nil }
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryRectangular:
            rectangular
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text("Gasolina cerca", comment: "Gas widget name")
            } icon: {
                Image(systemName: "fuelpump.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            if let glance {
                value(glance)
                    .widgetAccentable()
                Text(verbatim: glance.station)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(verbatim: glance.whereLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                UpdatedLine(clock: glance.asOfClock)
            } else {
                NoRecentReports()
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenLabel)
    }

    /// The whole glance as one sentence, for every family.
    private var spokenLabel: Text {
        glance.map { Text(verbatim: $0.spoken) } ?? Text("Gasolina cerca: sin reportes recientes.", comment: "Gas widget, VoiceOver: nothing current")
    }

    private func value(_ glance: GasGlance) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(verbatim: glance.value)
                .font(.system(glance.unit == nil ? .title3 : .largeTitle, design: .rounded, weight: .semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let unit = glance.unit {
                Text(verbatim: unit)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let glance {
                Text(verbatim: glance.compact)
                    .font(.headline)
                    .widgetAccentable()
                Text(verbatim: glance.station)
                    .font(.caption)
                    .lineLimit(1)
                Text(verbatim: glance.asOfClock)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Label {
                    Text("Gasolina cerca", comment: "Gas widget name")
                } icon: {
                    Image(systemName: "fuelpump")
                }
                .font(.headline)
                NoRecentReports()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenLabel)
    }

    @ViewBuilder
    private var inline: some View {
        if let glance {
            Label {
                Text("\(glance.compact) · \(glance.station)", comment: "Inline gas widget: the price per unit, then the station")
            } icon: {
                Image(systemName: "fuelpump.fill")
            }
            .accessibilityLabel(Text(verbatim: glance.spoken))
        } else {
            Label {
                Text("Sin reportes recientes", comment: "Widget: nothing current to show")
            } icon: {
                Image(systemName: "fuelpump")
            }
        }
    }
}
