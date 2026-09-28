import SwiftUI
import WidgetKit

/// What a widget says instead of an old value (§3 "Truth before completeness").
struct NoRecentReports: View {
    var body: some View {
        Text("Sin reportes recientes", comment: "Widget: nothing current to show")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "Actualizado 4:10 p. m.": when the answer was last said.
struct UpdatedLine: View {
    let clock: String

    var body: some View {
        Text("Actualizado \(clock)", comment: "Widget: when the answer was last said, a clock time")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// One change at a watched place: symbol, sentence and source, never colour alone.
struct GlanceLineView: View {
    let line: GlanceLine

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: line.symbol)
                .font(.caption.weight(.semibold))
                .frame(width: 16)
                .widgetAccentable()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: line.text)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(verbatim: line.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
