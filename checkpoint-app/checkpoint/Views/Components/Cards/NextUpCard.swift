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
    var dailyMilesPace: Double? = nil
    var isEstimatedMileage: Bool = false
    let onTap: () -> Void

    private var status: ServiceStatus {
        service.status(currentMileage: currentMileage)
    }

    /// Calculate days until due based on mileage pace
    private var pacePredictedDays: Int? {
        guard let pace = dailyMilesPace,
              pace > 0,
              let dueMileage = service.dueMileage else { return nil }

        let milesRemaining = dueMileage - currentMileage
        guard milesRemaining > 0 else { return nil }

        return Int(ceil(Double(milesRemaining) / pace))
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
        VStack(alignment: .leading, spacing: 0) {
            // Header row: status + service name
            HStack(alignment: .top) {
                // Status indicator (square, not circle - brutalist) with glow
                Rectangle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: status.color, isActive: isUrgent)
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

            // Hero data display - miles first, days as fallback
            if let miles = milesUntilDue {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(Formatters.mileageNumber(abs(miles)))
                            .font(.brutalistHero)
                            .foregroundStyle(status.color)
                            .contentTransition(.numericText())

                        Text(DistanceSettings.shared.unit.uppercaseAbbreviation)
                            .font(.brutalistHeading)
                            .foregroundStyle(status.color)
                    }

                    Text(miles < 0 ? "OVERDUE" : "REMAINING")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    // Pace prediction (only shown when sufficient data)
                    if let paceDays = pacePredictedDays {
                        Text("~\(paceDays) DAYS AT YOUR PACE")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 4)
                    } else if dailyMilesPace == nil || dailyMilesPace == 0 {
                        Text(L10n.emptyPaceHint.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 20)
            } else if let days = daysUntilDue {
                // Fallback to days for date-only services (e.g., battery check, wiper blades)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(abs(days))")
                            .font(.brutalistHero)
                            .foregroundStyle(status.color)
                            .contentTransition(.numericText())

                        Text("DAYS")
                            .font(.brutalistHeading)
                            .foregroundStyle(status.color)
                    }

                    Text(days < 0 ? "OVERDUE" : "REMAINING")
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

                        HStack(spacing: 4) {
                            Text(Formatters.mileageDisplay(currentMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)

                            if isEstimatedMileage {
                                Text("(EST)")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textSecondary)
                                    .tracking(0.5)
                            }
                        }
                    }

                    HStack {
                        Text("DUE_AT")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Spacer()

                        Text(Formatters.mileageDisplay(dueMileage))
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
        .glassCardStyle(intensity: .subtle)
        .tappableCard(action: onTap)
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

}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

// MARK: - Marbete Next Up Card

/// Specialized NextUpCard for marbete renewal display
struct MarbeteNextUpCard: View {
    let marbeteItem: MarbeteUpcomingItem
    let vehicleName: String
    let onTap: () -> Void

    private var status: ServiceStatus { marbeteItem.itemStatus }
    private var daysUntilDue: Int? { marbeteItem.daysRemaining }

    private var isUrgent: Bool {
        status == .overdue || status == .dueSoon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row: status + item name
            HStack(alignment: .top) {
                // Status indicator (square, brutalist) with glow
                Rectangle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: status.color, isActive: isUrgent)
                    .pulseAnimation(isActive: isUrgent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.label.isEmpty ? "SCHEDULED" : status.label)
                        .font(.brutalistLabel)
                        .foregroundStyle(status.color)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(marbeteItem.itemName)
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

            // Hero data display - days only for marbete
            if let days = daysUntilDue {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(abs(days))")
                            .font(.brutalistHero)
                            .foregroundStyle(status.color)
                            .contentTransition(.numericText())

                        Text("DAYS")
                            .font(.brutalistHeading)
                            .foregroundStyle(status.color)
                    }

                    Text(days < 0 ? "EXPIRED" : "REMAINING")
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

            // Expiration info
            VStack(spacing: 8) {
                HStack {
                    Text("EXPIRES")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    Spacer()

                    if let formatted = marbeteItem.expirationFormatted {
                        Text(formatted)
                            .font(.brutalistBody)
                            .foregroundStyle(status.color)
                    }
                }
            }
            .padding(.top, 12)
        }
        .glassCardStyle(intensity: .subtle)
        .tappableCard(action: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Marbete renewal, \(status.label)")
        .accessibilityHint(marbeteItem.expirationFormatted ?? "")
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
                    vehicleName: vehicle.displayName,
                    dailyMilesPace: 40.0  // ~40 miles per day
                ) {
                    print("Tapped \(service.name)")
                }
            }
        }
        .padding(Theme.screenHorizontalPadding)
    }
    .preferredColorScheme(.dark)
}
