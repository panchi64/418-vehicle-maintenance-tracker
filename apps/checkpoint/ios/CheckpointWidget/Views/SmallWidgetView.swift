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

    private var displayMode: MileageDisplayMode {
        entry.configuration.mileageDisplayMode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header

            if let service = entry.services.first {
                // Service name + hero figure open that service in the app.
                OpenServiceButton(service: service, vehicleID: entry.vehicleID) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.name.uppercased())
                            .font(.widgetHeadline)
                            .foregroundStyle(WidgetColors.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        WidgetHero(
                            label: WidgetDisplayHelpers.displayLabel(for: service, displayMode: displayMode, currentMileage: entry.currentMileage),
                            value: WidgetDisplayHelpers.displayValue(for: service, displayMode: displayMode, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit),
                            unit: WidgetDisplayHelpers.displayUnit(for: service, distanceUnit: entry.distanceUnit),
                            numeralSize: 34
                        )

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                HStack(spacing: 0) {
                    WidgetStatusTag(status: service.status)
                    Spacer(minLength: 4)
                    WidgetDoneButton(service: service, entry: entry)
                }
            } else {
                WidgetEmptyState(hasVehicle: entry.vehicleID != nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// Vehicle name; when the snapshot is from an earlier day, the as-of cue
    /// takes the line's trailing edge so a stale figure never reads as current.
    private var header: some View {
        HStack(spacing: 6) {
            Text(entry.vehicleName.uppercased())
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .tracking(1)
                .lineLimit(1)

            if let updatedAt = entry.updatedAt,
               WidgetDisplayHelpers.isStale(updatedAt: updatedAt, entryDate: entry.date) {
                Spacer(minLength: 0)
                WidgetAsOfLabel(entry: entry)
                    .layoutPriority(1)
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
