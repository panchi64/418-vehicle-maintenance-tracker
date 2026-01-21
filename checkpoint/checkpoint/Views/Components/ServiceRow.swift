//
//  ServiceRow.swift
//  checkpoint
//
//  Compact row for service list with clear visual hierarchy
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

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Status indicator - larger and more prominent
                Circle()
                    .fill(status.color)
                    .frame(width: 10, height: 10)
                    .padding(7)
                    .background(
                        Circle()
                            .fill(status.color.opacity(0.15))
                    )

                // Service info - clear hierarchy
                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)

                    // Due date info
                    if let days = daysUntilDue {
                        Text(dueText(days: days))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(status == .overdue ? status.color : Theme.textSecondary)
                    }
                }

                Spacer()

                // Miles remaining - more prominent
                if let miles = milesRemaining {
                    Text(formatMiles(miles))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(miles < 0 ? status.color : Theme.textPrimary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name)")
        .accessibilityValue(service.dueDescription ?? "No due date")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Helpers

    private func dueText(days: Int) -> String {
        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "In \(days) days"
        }
    }

    private func formatMiles(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if miles < 0 {
            return "Overdue"
        }
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 0) {
            ForEach(services, id: \.name) { service in
                ServiceRow(
                    service: service,
                    currentMileage: vehicle.currentMileage
                ) {
                    print("Tapped \(service.name)")
                }

                if service.name != services.last?.name {
                    Divider()
                        .background(Theme.borderSubtle.opacity(0.3))
                        .padding(.leading, 56)
                }
            }
        }
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
