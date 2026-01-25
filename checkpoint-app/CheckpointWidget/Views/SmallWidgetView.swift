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
                    Text("DUE @")
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
                .frame(maxWidth: .infinity, alignment: .center)
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

    /// Get the display value (mileage or days)
    private func displayValue(for service: WidgetService) -> String {
        // Priority: dueMileage first, then daysRemaining
        if let dueMileage = service.dueMileage {
            return formatNumber(dueMileage)
        } else if let days = service.daysRemaining {
            return "\(days)"
        }
        return "—"
    }

    /// Get the unit label based on what we're displaying
    private func displayUnit(for service: WidgetService) -> String {
        if service.dueMileage != nil {
            return "MI"
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
