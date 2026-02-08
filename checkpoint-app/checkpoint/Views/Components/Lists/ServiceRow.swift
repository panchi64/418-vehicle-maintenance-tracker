//
//  ServiceRow.swift
//  checkpoint
//
//  Compact row for service list with instrument cluster aesthetic
//

import SwiftUI

struct ServiceRow: View {
    let service: Service
    let currentMileage: Int
    var isEstimatedMileage: Bool = false
    let onTap: () -> Void

    private var status: ServiceStatus {
        service.status(currentMileage: currentMileage)
    }

    private var daysUntilDue: Int? {
        guard let dueDate = service.dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: dueDate).day
    }

    private var milesRemaining: Int? {
        guard let dueMileage = service.dueMileage else { return nil }
        return dueMileage - currentMileage
    }

    private var isUrgent: Bool {
        status == .overdue || status == .dueSoon
    }

    private var progressValue: Double {
        guard let dueMileage = service.dueMileage,
              let lastMileage = service.lastMileage,
              dueMileage > lastMileage else { return 0 }
        let total = Double(dueMileage - lastMileage)
        let elapsed = Double(currentMileage - lastMileage)
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator (square - brutalist) with glow for urgent
            ZStack {
                Rectangle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Rectangle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: status.color, isActive: isUrgent)
                    .pulseAnimation(isActive: isUrgent)
            }

            // Service info with progress
            VStack(alignment: .leading, spacing: 6) {
                // Service name - monospace
                Text(service.name.uppercased())
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                // Last performed context
                if let lastPerformed = service.lastPerformed {
                    Text("LAST: \(TimeSinceFormatter.abbreviated(from: lastPerformed))")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.5)
                }

                // Mini progress bar + due info - miles first
                HStack(spacing: Spacing.sm) {
                    // Mini progress indicator
                    if service.dueMileage != nil {
                        miniProgressBar
                    }

                    // Miles info (primary) or days info (fallback for date-only services)
                    if let miles = milesRemaining {
                        Text(formatMilesText(miles))
                            .font(.instrumentLabel)
                            .foregroundStyle(status == .overdue ? status.color : Theme.textTertiary)
                            .tracking(0.5)
                    } else if let days = daysUntilDue {
                        Text(dueText(days: days))
                            .font(.instrumentLabel)
                            .foregroundStyle(status == .overdue ? status.color : Theme.textTertiary)
                            .tracking(0.5)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.listItem)
        .tappableCard(action: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name)")
        .accessibilityValue(service.dueDescription ?? "No due date")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Subviews

    private var miniProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 2)

                Rectangle()
                    .fill(status.color)
                    .frame(width: geo.size.width * progressValue, height: 2)
            }
        }
        .frame(width: 40, height: 2)
    }

    // MARK: - Helpers

    private func dueText(days: Int) -> String {
        if days < 0 {
            return "\(abs(days))D OVERDUE"
        } else if days == 0 {
            return "TODAY"
        } else if days == 1 {
            return "TOMORROW"
        } else {
            return "IN \(days) DAYS"
        }
    }

    private func formatMilesText(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(abs(miles))
        let formatted = Formatters.decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
        if miles < 0 {
            return "\(formatted) \(unit.uppercaseAbbreviation) OVERDUE"
        } else if miles == 0 {
            return "DUE NOW"
        } else {
            return "\(formatted) \(unit.uppercaseAbbreviation)"
        }
    }
}

// MARK: - Service Row Button Style

struct ServiceRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? Theme.backgroundSubtle : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            ForEach(services, id: \.name) { service in
                ServiceRow(
                    service: service,
                    currentMileage: vehicle.currentMileage
                ) {
                    print("Tapped \(service.name)")
                }

                if service.name != services.last?.name {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)
                        .padding(.leading, 56)
                }
            }
        }
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
