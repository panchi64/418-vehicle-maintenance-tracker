//
//  NextUpCard.swift
//  checkpoint
//
//  Data-focused hero card with instrument cluster aesthetic
//

import SwiftUI

struct NextUpCard: View {
    let service: Service
    let currentMileage: Int
    let vehicleName: String
    let onTap: () -> Void

    private var status: ServiceStatus {
        service.status(currentMileage: currentMileage)
    }

    private var daysUntilDue: Int? {
        guard let dueDate = service.dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: dueDate).day
    }

    private var milesUntilDue: Int? {
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
            VStack(spacing: Spacing.lg) {
                // Top section: Status pill
                HStack {
                    statusPill
                    Spacer()
                }

                // Service name
                Text(service.name.uppercased())
                    .font(.instrumentMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Hero countdown number
                if let days = daysUntilDue {
                    VStack(spacing: 4) {
                        Text("\(abs(days))")
                            .font(.instrumentLarge)
                            .foregroundStyle(status.color)
                            .contentTransition(.numericText())
                            .statusGlow(color: status.color, isActive: isUrgent)

                        Text(days < 0 ? "DAYS OVERDUE" : "DAYS REMAINING")
                            .font(.instrumentLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }

                // Progress bar section
                if let dueMileage = service.dueMileage {
                    VStack(spacing: Spacing.md) {
                        // Progress track
                        progressBar

                        // Mileage labels
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CURRENT")
                                    .font(.instrumentLabel)
                                    .foregroundStyle(Theme.textTertiary)

                                Text(formatMileage(currentMileage))
                                    .font(.instrumentMono)
                                    .foregroundStyle(Theme.textPrimary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("DUE AT")
                                    .font(.instrumentLabel)
                                    .foregroundStyle(Theme.textTertiary)

                                Text(formatMileage(dueMileage))
                                    .font(.instrumentMono)
                                    .foregroundStyle(status.color)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.instrumentCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.instrumentCornerRadius, style: .continuous)
                    .strokeBorder(Theme.gridLine, lineWidth: 1)
            )
            .shadow(color: status.color.opacity(isUrgent ? 0.2 : 0), radius: 8, x: 0, y: 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name), \(status.label)")
        .accessibilityHint(service.dueDescription ?? "")
    }

    // MARK: - Subviews

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .pulseAnimation(isActive: isUrgent)

            Text(status.label.isEmpty ? "SCHEDULED" : status.label)
                .font(.instrumentLabel)
                .foregroundStyle(status.color)
                .tracking(1.5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ZStack {
                status.color.opacity(0.15)

                // Inner glow effect
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(status.color.opacity(0.3), lineWidth: 1)
            }
        )
        .clipShape(Capsule())
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.gridLine)
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.accent,
                                status.color
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progressValue, height: 4)

                // End markers
                HStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)

                    Spacer()

                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(height: 8)
    }

    private var cardBackground: some View {
        ZStack {
            Theme.surfaceInstrument

            // Subtle vertical gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Helpers

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            ForEach(services.prefix(2), id: \.name) { service in
                NextUpCard(
                    service: service,
                    currentMileage: vehicle.currentMileage,
                    vehicleName: vehicle.displayName
                ) {
                    print("Tapped \(service.name)")
                }
            }
        }
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
