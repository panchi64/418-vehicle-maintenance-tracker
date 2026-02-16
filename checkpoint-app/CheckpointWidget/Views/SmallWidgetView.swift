//
//  SmallWidgetView.swift
//  CheckpointWidget
//
//  Small widget showing next service due
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI
import WidgetKit
import AppIntents

struct SmallWidgetView: View {
    let entry: ServiceEntry

    private var displayMode: MileageDisplayMode {
        entry.configuration.mileageDisplayMode
    }

    private var distanceUnit: WidgetDistanceUnit {
        entry.distanceUnit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                    .lineLimit(1)

                Spacer()

                // Large centered number display with unit to the right
                VStack(spacing: 2) {
                    Text(displayLabel(for: service))
                        .font(.widgetLabel)
                        .foregroundStyle(WidgetColors.textTertiary)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayValue(for: service))
                            .font(.widgetDisplayLarge)
                            .foregroundStyle(WidgetColors.textPrimary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text(displayUnit(for: service))
                            .font(.widgetUnit)
                            .foregroundStyle(WidgetColors.textTertiary)
                            .tracking(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // Status indicator and mark done button
                HStack(spacing: 0) {
                    // Status indicator - square (brutalist)
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(service.status.color)
                            .frame(width: 8, height: 8)

                        Text(statusLabel(for: service.status))
                            .font(.widgetCaption)
                            .foregroundStyle(service.status.color)
                            .tracking(0.5)
                    }

                    Spacer()

                    // Mark done button (only for due soon or overdue services)
                    if let serviceID = service.serviceID,
                       let vehicleID = entry.vehicleID,
                       service.status == .dueSoon || service.status == .overdue {
                        Button(intent: MarkServiceDoneIntent(
                            serviceID: serviceID,
                            vehicleID: vehicleID,
                            mileage: entry.currentMileage
                        )) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                Text("DONE")
                                    .font(.widgetCaption)
                                    .tracking(0.5)
                            }
                            .foregroundStyle(WidgetColors.statusGood)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(WidgetColors.statusGood.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Spacer()

                if entry.vehicleID == nil {
                    // No vehicle configured
                    VStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(WidgetColors.textTertiary)
                        Text("TAP TO SET UP")
                            .font(.widgetBody)
                            .foregroundStyle(WidgetColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Vehicle exists but no services due
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(WidgetColors.statusGood)
                        Text("ALL CAUGHT UP")
                            .font(.widgetBody)
                            .foregroundStyle(WidgetColors.statusGood)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

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

    // MARK: - Display Helpers (delegated to shared WidgetDisplayHelpers)

    private func displayLabel(for service: WidgetService) -> String {
        WidgetDisplayHelpers.displayLabel(for: service, displayMode: displayMode, currentMileage: entry.currentMileage)
    }

    private func displayValue(for service: WidgetService) -> String {
        WidgetDisplayHelpers.displayValue(for: service, displayMode: displayMode, currentMileage: entry.currentMileage, distanceUnit: distanceUnit)
    }

    private func displayUnit(for service: WidgetService) -> String {
        WidgetDisplayHelpers.displayUnit(for: service, distanceUnit: distanceUnit)
    }

    private func statusLabel(for status: WidgetServiceStatus) -> String {
        WidgetDisplayHelpers.statusLabel(for: status)
    }
}

#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
