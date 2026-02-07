//
//  WatchCornerView.swift
//  CheckpointWatchWidget
//
//  Corner Watch complication (accessoryCorner): gauge-style display
//  watchOS-only corner complication with status-colored gauge
//

import SwiftUI
import WidgetKit

struct WatchCornerView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            ZStack {
                // Corner gauge showing urgency
                AccessoryWidgetBackground()
                Image(systemName: service.status.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .widgetAccentable()
            }
            .widgetLabel {
                Text(abbreviate(service.name))
                    .font(.system(.caption, design: .monospaced))
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("—")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
        }
    }

    /// Returns first word: "Oil Change" → "OIL"
    private func abbreviate(_ name: String) -> String {
        String(name.uppercased().split(separator: " ").first ?? "")
    }
}
