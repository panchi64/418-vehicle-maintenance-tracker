//
//  NextUpCard.swift
//  checkpoint
//
//  Hero card showing vehicle status with elegant car visualization
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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top section: Service info + Car visualization
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Left: Service details
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        // Status pill
                        statusPill

                        // Service name
                        Text(service.name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .tracking(-0.5)

                        // Due countdown
                        if let days = daysUntilDue {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(days < 0 ? "\(abs(days))" : "\(days)")
                                    .font(.system(size: 40, weight: .light, design: .rounded))
                                    .foregroundStyle(status.color)
                                    .contentTransition(.numericText())

                                Text(days < 0 ? "days\noverdue" : "days\nremaining")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right: Car silhouette
                    carVisualization
                }

                // Divider
                Rectangle()
                    .fill(Theme.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                    .padding(.vertical, Spacing.md)

                // Bottom: Mileage info
                HStack {
                    // Current mileage
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Text(formatMileage(currentMileage))
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Spacer()

                    // Due mileage
                    if let dueMileage = service.dueMileage {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DUE AT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)

                            Text(formatMileage(dueMileage))
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(status.color)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.borderSubtle.opacity(0.6),
                                Theme.borderSubtle.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
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
                .frame(width: 6, height: 6)

            Text(status.label.isEmpty ? "SCHEDULED" : status.label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var carVisualization: some View {
        ZStack {
            // Glow effect behind car
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            status.color.opacity(0.15),
                            status.color.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            // Car icon
            Image(systemName: "car.side.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.textPrimary,
                            Theme.textSecondary
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: status.color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .frame(width: 120, height: 100)
    }

    private var cardBackground: some View {
        ZStack {
            Theme.backgroundElevated

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

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
