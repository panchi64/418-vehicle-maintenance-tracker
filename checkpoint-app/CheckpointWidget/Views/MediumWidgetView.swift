//
//  MediumWidgetView.swift
//  CheckpointWidget
//
//  Medium widget showing next 2-3 services
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI
import WidgetKit
import AppIntents

struct MediumWidgetView: View {
    let entry: ServiceEntry

    private var displayMode: MileageDisplayMode {
        entry.configuration.mileageDisplayMode
    }

    private var distanceUnit: WidgetDistanceUnit {
        entry.distanceUnit
    }

    /// Services excluding the first one (for the right panel)
    private var otherServices: [WidgetService] {
        Array(entry.services.dropFirst().prefix(3))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Next up focus with large number
            leftPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Vertical divider (brutalist - 2px solid line)
            Rectangle()
                .fill(WidgetColors.gridLine)
                .frame(width: WidgetColors.borderWidth)

            // Right side - other services list
            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Left Panel (Next Up Focus)

    @ViewBuilder
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Vehicle name
            Text(entry.vehicleName.uppercased())
                .font(.widgetHeadline)
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)

            // "MAINTENANCE" subtitle
            Text("MAINTENANCE")
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .tracking(1)

            if let service = entry.services.first {
                Spacer()

                // Large centered number display with unit to the right
                VStack(spacing: 2) {
                    Text(displayLabel(for: service))
                        .font(.widgetLabel)
                        .foregroundStyle(WidgetColors.textTertiary)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayValue(for: service))
                            .font(.widgetDisplayHero)
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

                // Service name
                Text(service.name.uppercased())
                    .font(.widgetBody)
                    .foregroundStyle(WidgetColors.textPrimary)
                    .lineLimit(1)

                // Status indicator and mark done button
                HStack(spacing: 0) {
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

                    // Mark done button (in left panel, acting on the primary service)
                    markDoneButton
                }
            } else {
                Spacer()

                if entry.vehicleID == nil {
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
        .padding(.trailing, 12)
    }

    // MARK: - Right Panel (Other Services)

    @ViewBuilder
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if otherServices.isEmpty {
                Spacer()
                Text("ALL CAUGHT UP")
                    .font(.widgetBody)
                    .foregroundStyle(WidgetColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                // "UPCOMING" header
                Text("UPCOMING")
                    .font(.widgetLabel)
                    .foregroundStyle(WidgetColors.textTertiary)
                    .tracking(1)

                ForEach(otherServices) { service in
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
            }

            Spacer()
        }
        .padding(.leading, 12)
    }

    // MARK: - Mark Done Button

    @ViewBuilder
    private var markDoneButton: some View {
        if let service = entry.services.first,
           let serviceID = service.serviceID,
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

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
