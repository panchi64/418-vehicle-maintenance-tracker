//
//  WatchCircularView.swift
//  CheckpointWatchWidget
//
//  Circular Watch complication: status shape over the service's first word
//  Brutalist: monospace, uppercase
//

import SwiftUI
import WidgetKit

struct WatchCircularView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let service = entry.service {
                VStack(spacing: 3) {
                    WatchWidgetStatusMark(status: service.status, size: 11)
                    Text(WatchWidgetDisplay.abbreviate(service.name))
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.horizontal, 3)
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
}
