//
//  CheckpointWidget.swift
//  CheckpointWidget
//
//  Widget configuration for Checkpoint vehicle maintenance tracker
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry View

struct CheckpointWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ServiceEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct CheckpointWidget: Widget {
    let kind: String = "CheckpointWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CheckpointWidgetConfigurationIntent.self,
            provider: WidgetProvider()
        ) { entry in
            CheckpointWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetColors.backgroundPrimary
                }
        }
        .configurationDisplayName("Checkpoint")
        .description("See your upcoming vehicle maintenance at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
}

#Preview("Inline", as: .accessoryInline) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
}

#Preview("Circular", as: .accessoryCircular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
}
