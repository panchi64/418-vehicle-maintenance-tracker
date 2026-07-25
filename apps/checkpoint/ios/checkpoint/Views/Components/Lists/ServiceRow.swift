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

    /// The row's reason for existing: how urgent is this, in the unit the user
    /// actually tracks. Mileage leads when the service has a mileage trigger,
    /// since that's what the odometer answers; otherwise the date does.
    private var urgencyText: String? {
        if let miles = milesRemaining {
            if miles < 0 {
                return L10n.rowDistanceOverdue(formattedDistance(abs(miles)))
            } else if miles == 0 {
                return L10n.rowDueNow
            }
            return L10n.rowDistanceLeft(formattedDistance(miles))
        }
        if let days = daysUntilDue {
            if days < 0 { return L10n.rowDaysOverdue(-days) }
            if days == 0 { return L10n.rowDueToday }
            if days == 1 { return L10n.rowDueTomorrow }
            return L10n.rowDaysLeft(days)
        }
        return nil
    }

    /// Two channels, not one: urgent rows differ from healthy rows in both
    /// weight (via `urgencyColor`) and the width of the status bar, so the
    /// distinction survives color blindness and sunlight.
    private var urgencyColor: Color {
        switch status {
        case .overdue, .dueSoon: return status.color
        default: return Theme.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            statusBar

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Urgency as a status eyebrow: small, uppercase, tracked, in
                // the status color. Mirrors NextUpCard, which is the pattern
                // in this app that already reads correctly.
                //
                // It is deliberately NOT the largest element. Scanning a list
                // of upcoming work, the user is looking for *which service*;
                // urgency qualifies it. Position plus color make the qualifier
                // unmissable without it competing for the same rank.
                if let urgencyText {
                    Text(urgencyText.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(urgencyColor)
                        .tracking(1.5)
                }

                // Primary: which service this is. Differs from the eyebrow on
                // four channels — size (20 vs 11), weight, case, and color —
                // so the ranking survives monospace's narrow weight contrast.
                // Sentence case: long names ("Transmission fluid change") lose
                // scannability in caps.
                Text(service.name)
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                // Supporting: progress + history, at the quietest level.
                HStack(spacing: Spacing.sm) {
                    if service.dueMileage != nil {
                        miniProgressBar
                    }

                    if let lastPerformed = service.lastPerformed {
                        Text(L10n.rowLastPerformed(TimeSinceFormatter.abbreviated(from: lastPerformed)))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.listItem)
        .tappableCard(action: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(service.name)
        // VoiceOver gets the urgency as the value, matching the visual
        // hierarchy — weight and color don't survive a screen reader.
        .accessibilityValue(urgencyText ?? service.dueDescription ?? L10n.rowNoDueDate)
        .accessibilityHint(L10n.rowViewDetailsHint)
    }

    /// Replaces the 8×8 dot inside a 32×32 tint. A vertical bar the height of
    /// the row's content gives status real presence and lets urgency read from
    /// the row's left edge before any text is parsed.
    private var statusBar: some View {
        Rectangle()
            .fill(status.color)
            .frame(width: isUrgent ? 4 : 2)
            .frame(maxHeight: .infinity)
            .statusGlow(color: status.color, isActive: isUrgent)
            .pulseAnimation(isActive: isUrgent)
            .accessibilityHidden(true)
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

    /// Distance with its unit, converted to the user's preference. Returned as
    /// one string so the surrounding sentence stays a single format key and
    /// translators control word order.
    private func formattedDistance(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(miles)
        let formatted = Formatters.decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
        return "\(formatted) \(unit.abbreviation)"
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
        .brutalistBorder()
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
