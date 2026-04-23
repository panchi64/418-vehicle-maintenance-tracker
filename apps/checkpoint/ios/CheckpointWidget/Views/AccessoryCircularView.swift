//
//  AccessoryCircularView.swift
//  CheckpointWidget
//
//  Circular lock screen widget showing status icon and abbreviated service
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace
//

import SwiftUI
import WidgetKit

struct AccessoryCircularView: View {
    let entry: ServiceEntry

    var body: some View {
        if let service = entry.services.first {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: statusIcon(for: service.status))
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

    private func statusIcon(for status: WidgetServiceStatus) -> String {
        switch status {
        case .overdue: return "exclamationmark.triangle"
        case .dueSoon: return "clock"
        case .good: return "checkmark.circle"
        case .neutral: return "minus.circle"
        }
    }
}

#Preview(as: .accessoryCircular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
