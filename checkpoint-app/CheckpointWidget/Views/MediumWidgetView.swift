//
//  MediumWidgetView.swift
//  CheckpointWidget
//
//  Medium widget showing next 2-3 services
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: ServiceEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - vehicle info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.vehicleName.uppercased())
                    .font(.widgetHeadline)
                    .foregroundStyle(WidgetColors.textPrimary)

                Text("MAINTENANCE")
                    .font(.widgetLabel)
                    .foregroundStyle(WidgetColors.textTertiary)
                    .tracking(1)

                Spacer()

                if let firstService = entry.services.first {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(firstService.status.color)
                            .frame(width: 8, height: 8)

                        Text(firstService.dueDescription.uppercased())
                            .font(.widgetCaption)
                            .foregroundStyle(firstService.status.color)
                            .tracking(0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Vertical divider (brutalist)
            Rectangle()
                .fill(WidgetColors.gridLine)
                .frame(width: WidgetColors.borderWidth)

            // Right side - service list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.services.prefix(3)) { service in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(service.status.color)
                            .frame(width: 6, height: 6)

                        Text(service.name.uppercased())
                            .font(.widgetBody)
                            .foregroundStyle(WidgetColors.textPrimary)
                            .lineLimit(1)
                    }
                }

                if entry.services.isEmpty {
                    Text("ALL CAUGHT UP")
                        .font(.widgetBody)
                        .foregroundStyle(WidgetColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(for: .widget) {
            ZStack {
                WidgetColors.backgroundPrimary
                // Subtle glass overlay
                Color.white.opacity(0.05)
            }
        }
    }
}

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
