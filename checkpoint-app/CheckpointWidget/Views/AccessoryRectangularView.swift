//
//  AccessoryRectangularView.swift
//  CheckpointWidget
//
//  Rectangular lock screen widget with full detail and status bar
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace, sharp edges
//

import SwiftUI
import WidgetKit

struct AccessoryRectangularView: View {
    let entry: ServiceEntry

    var body: some View {
        if let service = entry.services.first {
            HStack(spacing: 6) {
                // Status bar - 2px wide, sharp rectangle (brutalist)
                Rectangle()
                    .fill(service.status.accessoryColor)
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 1) {
                    // Vehicle name - 40% opacity
                    Text(entry.vehicleName.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .opacity(0.4)

                    // Service name - full opacity, bold
                    Text(service.name.uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)

                    // Due description - status colored
                    Text(service.dueDescription.uppercased())
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(service.status.accessoryColor)
                }

                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(.green)
                    .frame(width: 2)
                Text("— NO SERVICES DUE —")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .opacity(0.4)
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview(as: .accessoryRectangular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
