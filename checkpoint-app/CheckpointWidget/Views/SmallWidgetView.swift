//
//  SmallWidgetView.swift
//  CheckpointWidget
//
//  Small widget showing next service due
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: ServiceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vehicle name
            Text(entry.vehicleName)
                .font(.caption)
                .foregroundStyle(WidgetColors.textSecondary)

            if let service = entry.services.first {
                // Service name
                Text(service.name)
                    .font(.headline)
                    .foregroundStyle(WidgetColors.textPrimary)
                    .lineLimit(2)

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(service.status.color)
                        .frame(width: 8, height: 8)

                    Text(service.dueDescription)
                        .font(.caption)
                        .foregroundStyle(service.status.color)
                }
            } else {
                Text("No services scheduled")
                    .font(.subheadline)
                    .foregroundStyle(WidgetColors.textSecondary)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
