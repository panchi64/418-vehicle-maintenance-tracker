//
//  MediumWidgetView.swift
//  CheckpointWidget
//
//  Medium widget showing next 2-3 services
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: ServiceEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - vehicle info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.vehicleName)
                    .font(.headline)
                    .foregroundStyle(WidgetColors.textPrimary)

                Text("Maintenance")
                    .font(.caption)
                    .foregroundStyle(WidgetColors.textSecondary)

                Spacer()

                if let firstService = entry.services.first {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(firstService.status.color)
                            .frame(width: 8, height: 8)

                        Text(firstService.dueDescription)
                            .font(.caption2)
                            .foregroundStyle(firstService.status.color)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - service list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.services.prefix(3)) { service in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(service.status.color)
                            .frame(width: 6, height: 6)

                        Text(service.name)
                            .font(.caption)
                            .foregroundStyle(WidgetColors.textPrimary)
                            .lineLimit(1)
                    }
                }

                if entry.services.isEmpty {
                    Text("All caught up!")
                        .font(.caption)
                        .foregroundStyle(WidgetColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
