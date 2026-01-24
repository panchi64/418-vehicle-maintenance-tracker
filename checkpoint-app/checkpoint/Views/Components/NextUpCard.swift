//
//  NextUpCard.swift
//  checkpoint
//
//  Brutalist-Tech-Modernist hero card - terminal data display
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

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row: status + service name
                HStack(alignment: .top) {
                    // Status indicator (square, not circle - brutalist)
                    Rectangle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                        .pulseAnimation(isActive: isUrgent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.label.isEmpty ? "SCHEDULED" : status.label)
                            .font(.brutalistLabel)
                            .foregroundStyle(status.color)
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(service.name)
                            .font(.brutalistHeading)
                            .foregroundStyle(Theme.textPrimary)
                            .textCase(.uppercase)
                    }

                    Spacer()
                }
                .padding(.bottom, 16)

                // Divider
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                // Hero data display
                if let days = daysUntilDue {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(abs(days))")
                            .font(.brutalistHero)
                            .foregroundStyle(status.color)
                            .contentTransition(.numericText())

                        Text(days < 0 ? "DAYS_OVERDUE" : "DAYS_REMAINING")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                    }
                    .padding(.vertical, 20)
                }

                // Divider
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                // Data rows
                VStack(spacing: 8) {
                    if let dueMileage = service.dueMileage {
                        HStack {
                            Text("CURRENT")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)

                            Spacer()

                            Text(formatMileage(currentMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)
                        }

                        HStack {
                            Text("DUE_AT")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)

                            Spacer()

                            Text(formatMileage(dueMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(status.color)
                        }

                        // Progress bar (simple, geometric)
                        progressBar
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 12)
            }
            .padding(Theme.cardPadding)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name), \(status.label)")
        .accessibilityHint(service.dueDescription ?? "")
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let progressValue: Double = {
            guard let dueMileage = service.dueMileage,
                  let lastMileage = service.lastMileage,
                  dueMileage > lastMileage else { return 0 }
            let total = Double(dueMileage - lastMileage)
            let elapsed = Double(currentMileage - lastMileage)
            return min(max(elapsed / total, 0), 1)
        }()

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 2)

                // Fill
                Rectangle()
                    .fill(status.color)
                    .frame(width: geo.size.width * progressValue, height: 2)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Helpers

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + "_MI"
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: 16) {
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
        .padding(Theme.screenHorizontalPadding)
    }
    .preferredColorScheme(.dark)
}
