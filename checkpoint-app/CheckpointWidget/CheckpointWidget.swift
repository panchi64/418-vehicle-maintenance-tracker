//
//  CheckpointWidget.swift
//  CheckpointWidget
//
//  Widget configuration and entry view
//

import WidgetKit
import SwiftUI

struct CheckpointWidget: Widget {
    let kind: String = "CheckpointWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CheckpointWidgetEntryView(entry: entry)
                .containerBackground(WidgetColors.backgroundPrimary, for: .widget)
        }
        .configurationDisplayName("Checkpoint")
        .description("View upcoming vehicle maintenance")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Entry View

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

// MARK: - Previews

#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}

#Preview(as: .accessoryInline) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}

#Preview(as: .accessoryCircular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}

#Preview(as: .accessoryRectangular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
