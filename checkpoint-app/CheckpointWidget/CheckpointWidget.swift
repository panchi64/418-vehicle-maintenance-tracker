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
        .supportedFamilies([.systemSmall, .systemMedium])
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
