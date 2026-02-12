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
        WidgetDistanceUnit.current()
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

                Text("NO SERVICES")
                    .font(.widgetBody)
                    .foregroundStyle(WidgetColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

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

    // MARK: - Display Helpers

    /// Format large number with comma separators
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Format mileage in user's preferred unit
    private func formatMileage(_ miles: Int) -> String {
        let displayValue = distanceUnit.fromMiles(miles)
        return formatNumber(displayValue)
    }

    /// Get the label text based on display mode and service type
    private func displayLabel(for service: WidgetService) -> String {
        if service.dueMileage != nil {
            switch displayMode {
            case .absolute:
                return "DUE AT"
            case .relative:
                if let dueMileage = service.dueMileage, entry.currentMileage > dueMileage {
                    return "OVERDUE BY"
                }
                return "REMAINING"
            }
        }
        return "DUE IN"
    }

    /// Get the display value (mileage or days) based on display mode
    private func displayValue(for service: WidgetService) -> String {
        // Priority: dueMileage first, then daysRemaining
        if let dueMileage = service.dueMileage {
            switch displayMode {
            case .absolute:
                return formatMileage(dueMileage)
            case .relative:
                let remaining = dueMileage - entry.currentMileage
                return formatMileage(abs(remaining))
            }
        } else if let days = service.daysRemaining {
            return "\(abs(days))"
        }
        return "—"
    }

    /// Get the unit label based on what we're displaying
    private func displayUnit(for service: WidgetService) -> String {
        if service.dueMileage != nil {
            return distanceUnit.uppercaseAbbreviation
        } else if service.daysRemaining != nil {
            return "DAYS"
        }
        return ""
    }

    /// Get status label text
    private func statusLabel(for status: WidgetServiceStatus) -> String {
        switch status {
        case .overdue: return "OVERDUE"
        case .dueSoon: return "DUE SOON"
        case .good: return "GOOD"
        case .neutral: return ""
        }
    }
}

#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
