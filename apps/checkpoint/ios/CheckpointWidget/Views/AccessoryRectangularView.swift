//
//  AccessoryRectangularView.swift
//  CheckpointWidget
//
//  Rectangular Lock Screen widget: status tag, service, due phrase
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace, sharp edges
//

import SwiftUI
import WidgetKit

struct AccessoryRectangularView: View {
    let entry: ServiceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let service = entry.services.first {
                // Status as shape + word — the Lock Screen strips hue.
                HStack(spacing: 6) {
                    WidgetStatusTag(status: service.status)
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

                Text(WidgetDisplayHelpers.compactDue(for: service, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                WidgetStatusTag(status: .good)
                Text(entry.vehicleID == nil ? "TAP TO SET UP" : "NO SERVICES DUE")
                    .font(.system(.headline, design: .monospaced))
                    .lineLimit(2)
                    .widgetAccentable()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Vehicle name, or how old the figures are once they predate today.
    private var trailingCue: String {
        if let updatedAt = entry.updatedAt,
           WidgetDisplayHelpers.isStale(updatedAt: updatedAt, entryDate: entry.date) {
            return WidgetDisplayHelpers.asOfLabel(updatedAt: updatedAt, entryDate: entry.date)
        }
        return entry.vehicleName.uppercased()
    }
}

#Preview(as: .accessoryRectangular) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
