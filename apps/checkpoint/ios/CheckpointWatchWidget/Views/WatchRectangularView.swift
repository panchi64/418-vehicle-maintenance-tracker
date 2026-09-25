//
//  WatchRectangularView.swift
//  CheckpointWatchWidget
//
//  Rectangular Watch complication: status tag, service, due phrase
//  Brutalist: monospace, uppercase, sharp edges
//

import SwiftUI
import WidgetKit

struct WatchRectangularView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let service = entry.service {
                HStack(spacing: 4) {
                    WatchWidgetStatusTag(status: service.status)
                    Spacer(minLength: 0)
                    Text(trailingCue)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(service.name.uppercased())
                    .font(.system(.headline, design: .monospaced))
                    .lineLimit(1)
                    .widgetAccentable()

                Text(WatchWidgetDisplay.compactDue(for: service, entry: entry))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                WatchWidgetStatusTag(status: .good)
                Text("NO SERVICES DUE")
                    .font(.system(.headline, design: .monospaced))
                    .lineLimit(2)
                    .widgetAccentable()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Vehicle name, or how old the figures are once the sync is stale.
    private var trailingCue: String {
        if entry.isStale, let updatedAt = entry.updatedAt {
            return WatchWidgetDisplay.asOfLabel(updatedAt, now: entry.date)
        }
        return entry.vehicleName.uppercased()
    }
}
