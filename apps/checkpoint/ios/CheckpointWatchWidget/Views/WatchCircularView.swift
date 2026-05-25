//
//  WatchCircularView.swift
//  CheckpointWatchWidget
//
//  Circular Watch complication: status icon + abbreviated service name
//  Brutalist: monospace, uppercase
//

import SwiftUI
import WidgetKit

struct WatchCircularView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: service.status.icon)
                        .font(.system(size: 18, weight: .semibold))
                    Text(abbreviate(service.name))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                }
            }
            .widgetAccentable()
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("—")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
            }
        }
    }

    /// Returns first word: "Oil Change" → "OIL"
    private func abbreviate(_ name: String) -> String {
        String(name.uppercased().split(separator: " ").first ?? "")
    }
}
