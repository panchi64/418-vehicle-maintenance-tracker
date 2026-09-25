//
//  AccessoryCircularView.swift
//  CheckpointWidget
//
//  Circular Lock Screen widget: status shape over the service's first word
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace
//

import SwiftUI
import WidgetKit

struct AccessoryCircularView: View {
    let entry: ServiceEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let service = entry.services.first {
                VStack(spacing: 3) {
                    // Lock Screen rendering is monochrome: the shape is the
                    // status (filled / outlined square, rule), not a hue.
                    WidgetStatusMark(status: service.status, size: 12)
                    Text(Self.abbreviate(service.name))
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(service.name), \(service.status.label)"))
            } else {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.semibold))
                    .accessibilityLabel(Text("No services due"))
            }
        }
        .widgetAccentable()
    }

    /// First word: "Oil Change" → "OIL"
    static func abbreviate(_ name: String) -> String {
        String(name.uppercased().split(separator: " ").first ?? "")
    }
}

#Preview(as: .accessoryCircular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
