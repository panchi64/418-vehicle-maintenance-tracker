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
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Status indicator (square - brutalist)
                ZStack {
                    Rectangle()
                        .fill(status.color.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Rectangle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                        .pulseAnimation(isActive: isUrgent)
                }

                // Service info with progress
                VStack(alignment: .leading, spacing: 6) {
                    // Service name - monospace
                    Text(service.name.uppercased())
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    // Mini progress bar + due info
                    HStack(spacing: Spacing.sm) {
                        // Mini progress indicator
                        if service.dueMileage != nil {
                            miniProgressBar
                        }

                        // Due date info
                        if let days = daysUntilDue {
                            Text(dueText(days: days))
                                .font(.instrumentLabel)
                                .foregroundStyle(status == .overdue ? status.color : Theme.textTertiary)
                                .tracking(0.5)
                        }
                    }
                }

                Spacer()

                // Miles remaining - monospaced
                if let miles = milesRemaining {
                    Text(formatMiles(miles))
                        .font(.instrumentMono)
                        .foregroundStyle(miles < 0 ? status.color : Theme.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.listItem)
            .contentShape(Rectangle())
        }
        .buttonStyle(ServiceRowButtonStyle())
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

    private func formatMiles(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if miles < 0 {
            return "OVER"
        }
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
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
