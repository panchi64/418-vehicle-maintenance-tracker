//
//  SmallWidgetView.swift
//  CheckpointWidget
//
//  Small widget showing next service due
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: ServiceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vehicle name - monospace label
            Text(entry.vehicleName.uppercased())
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .tracking(1)

            if let service = entry.services.first {
                // Service name - monospace headline
                Text(service.name.uppercased())
                    .font(.widgetHeadline)
                    .foregroundStyle(WidgetColors.textPrimary)
                    .lineLimit(2)

                Spacer()

                // Status indicator - square (brutalist)
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(service.status.color)
                        .frame(width: 8, height: 8)

                    Text(service.dueDescription.uppercased())
                        .font(.widgetLabel)
                        .foregroundStyle(service.status.color)
                        .tracking(0.5)
                }
            } else {
                Text("NO SERVICES")
                    .font(.widgetBody)
                    .foregroundStyle(WidgetColors.textSecondary)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            ZStack {
                WidgetColors.backgroundPrimary
                // Subtle glass overlay
                Color.white.opacity(0.05)
            }
        }
    }
}

#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
