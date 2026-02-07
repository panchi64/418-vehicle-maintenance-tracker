//
//  CheckpointWatchWidget.swift
//  CheckpointWatchWidget
//
//  Widget configuration for Apple Watch complications
//  Supports circular, rectangular, inline, and corner families
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry View

struct CheckpointWatchWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WatchWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            WatchCircularView(entry: entry)
        case .accessoryRectangular:
            WatchRectangularView(entry: entry)
        case .accessoryInline:
            WatchInlineView(entry: entry)
        case .accessoryCorner:
            WatchCornerView(entry: entry)
        default:
            WatchCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct CheckpointWatchWidget: Widget {
    let kind: String = "CheckpointWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WatchWidgetProvider()
        ) { entry in
            CheckpointWatchWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Checkpoint")
        .description("Next vehicle maintenance at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    CheckpointWatchWidget()
} timeline: {
    WatchWidgetEntry.placeholder
    WatchWidgetEntry.empty
}

#Preview("Rectangular", as: .accessoryRectangular) {
    CheckpointWatchWidget()
} timeline: {
    WatchWidgetEntry.placeholder
    WatchWidgetEntry.empty
}

#Preview("Inline", as: .accessoryInline) {
    CheckpointWatchWidget()
} timeline: {
    WatchWidgetEntry.placeholder
    WatchWidgetEntry.empty
}

#Preview("Corner", as: .accessoryCorner) {
    CheckpointWatchWidget()
} timeline: {
    WatchWidgetEntry.placeholder
    WatchWidgetEntry.empty
}
