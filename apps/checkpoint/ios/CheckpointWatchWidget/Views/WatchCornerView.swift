//
//  WatchCornerView.swift
//  CheckpointWatchWidget
//
//  Corner Watch complication (accessoryCorner): status shape with the
//  service's first word curved along the bezel
//

import SwiftUI
import WidgetKit

struct WatchCornerView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            ZStack {
                AccessoryWidgetBackground()
                WatchWidgetStatusMark(status: service.status, size: 14)
                    .widgetAccentable()
            }
            .widgetLabel {
                Text(verbatim: cornerLabel(for: service))
                    .font(.system(.caption, design: .monospaced))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(service.name), \(service.status.label)"))
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .widgetAccentable()
            }
            .accessibilityLabel(Text("No services due"))
        }
    }

    /// "OIL · OVERDUE" — the word travels with the shape.
    private func cornerLabel(for service: WatchWidgetService) -> String {
        let name = WatchWidgetDisplay.abbreviate(service.name)
        let word = service.status.label
        return word.isEmpty ? name : "\(name) \u{00B7} \(word)"
    }
}
