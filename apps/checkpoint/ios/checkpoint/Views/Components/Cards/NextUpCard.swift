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

    /// Abstracted month period for the projected due date (earlier of the
    /// calendar due date or the pace-predicted mileage date). Nil when there's
    /// no projection, or when it resolves to "Overdue" (the hero already says so).
    private var estimatedDuePeriod: String? {
        guard let due = service.effectiveDueDate(currentMileage: currentMileage, dailyPace: dailyMilesPace) else {
            return nil
        }
        let period = DuePeriodFormatter.describe(due)
        return period.isOverdue ? nil : period.label
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
            .padding(.bottom, Spacing.md)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Hero data display - miles first, days as fallback
            if let miles = milesUntilDue {
                VStack(alignment: .leading, spacing: Spacing.xs) {
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

                    // Estimated due as an abstracted month period (not raw days)
                    if status != .overdue, let period = estimatedDuePeriod {
                        Text("EST. DUE \(period.uppercased())")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(1)
                            .padding(.top, 4)
                    } else if dailyMilesPace == nil || dailyMilesPace == 0 {
                        Text(L10n.emptyPaceHint.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, Spacing.lg)
            } else if let dueDate = service.dueDate {
                // Date-only services (e.g., battery check, wiper blades):
                // abstracted month period instead of a raw day count.
                DuePeriodHero(date: dueDate, status: status, overdueWord: String(localized: "OVERDUE"), dueLabel: String(localized: "DUE"))
            }

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Data rows
            VStack(spacing: Spacing.sm) {
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
                        Text("DUE AT")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Spacer()

                        Text(Formatters.mileageDisplay(dueMileage))
                            .font(.brutalistBody)
                            .foregroundStyle(status.color)
                    }

                    // Last service date
                    if let lastPerformed = service.lastPerformed {
                        HStack {
                            Text("LAST_SERVICE")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)

                            Spacer()

                            Text(Formatters.mediumDate.string(from: lastPerformed).uppercased())
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    // Progress bar (simple, geometric)
                    progressBar
                        .padding(.top, 8)
                }
            }
            .padding(.top, Spacing.listItem)
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

// MARK: - Due Period Hero

/// Hero display for date-based Next Up items: an abstracted month period
/// (e.g. "MID MAY") with a label beneath, or the domain "overdue" word when
/// past due. Shared by date-only services and marbete renewal.
struct DuePeriodHero: View {
    let date: Date
    let status: ServiceStatus
    /// Word shown when overdue, e.g. "OVERDUE" (services) or "EXPIRED" (marbete).
    let overdueWord: String
    /// Label shown beneath the period when not overdue, e.g. "DUE" / "EXPIRES".
    let dueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(status == .overdue ? overdueWord : DuePeriodFormatter.describe(date).label.uppercased())
                .font(.brutalistTitle)
                .foregroundStyle(status.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if status != .overdue {
                Text(dueLabel)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
            }
        }
        .padding(.vertical, Spacing.lg)
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
            .padding(.bottom, Spacing.md)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Hero data display — abstracted month period instead of raw days
            if let expiration = marbeteItem.vehicle.marbeteExpirationDate {
                DuePeriodHero(date: expiration, status: status, overdueWord: String(localized: "EXPIRED"), dueLabel: String(localized: "EXPIRES"))
            }

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Expiration info
            VStack(spacing: Spacing.sm) {
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
            .padding(.top, Spacing.listItem)
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
