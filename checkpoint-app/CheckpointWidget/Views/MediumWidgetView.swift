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

    private var displayMode: MileageDisplayMode {
        entry.configuration.mileageDisplayMode
    }

    private var distanceUnit: WidgetDistanceUnit {
        WidgetDistanceUnit.current()
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

                // Status indicator
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(service.status.color)
                        .frame(width: 8, height: 8)

                    Text(statusLabel(for: service.status))
                        .font(.widgetCaption)
                        .foregroundStyle(service.status.color)
                        .tracking(0.5)
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

                Spacer()
            }
        }
        .padding(.leading, 12)
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

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
