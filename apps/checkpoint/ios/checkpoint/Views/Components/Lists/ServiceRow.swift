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

    /// The row's reason for existing: how urgent is this.
    private var urgencyText: String? {
        service.urgencyText(currentMileage: currentMileage)
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
                // "Due soon" and "good" both read "N MI LEFT"; only the tint
                // told them apart. The word carries it for color-blind users
                // and in sunlight. (Overdue already says so in the text.)
                if status == .dueSoon || urgencyText != nil {
                    AdaptiveStack(spacing: Spacing.sm) {
                        if status == .dueSoon {
                            Text(status.label)
                                .font(.brutalistLabelBold)
                                .foregroundStyle(status.color)
                                .tracking(1.5)
                        }
                        if let urgencyText {
                            Text(urgencyText.uppercased())
                                .font(.brutalistLabel)
                                .foregroundStyle(urgencyColor)
                                .tracking(1.5)
                        }
                    }
                }

                // Primary: which service this is. Differs from the eyebrow on
                // four channels — size (20 vs 11), weight, case, and color —
                // so the ranking survives monospace's narrow weight contrast.
                // Sentence case: long names ("Transmission fluid change") lose
                // scannability in caps.
                Text(service.name)
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                // Supporting: progress + history, at the quietest level.
                HStack(spacing: Spacing.sm) {
                    if service.dueMileage != nil {
                        miniProgressBar
                    }

                    if let lastPerformed = service.lastPerformed {
                        Text(L10n.rowLastPerformed(TimeSinceFormatter.abbreviated(from: lastPerformed)))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Spacer(minLength: Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
                .accessibilityHidden(true)
        }
        // Vertical padding only. The 16pt horizontal inset existed because this
        // row lived inside a bordered card that needed interior padding — with
        // the card gone it just indented every row 16pt past the section header
        // above it, so the list read as hanging off the screen's left edge.
        .padding(.vertical, Spacing.listItem)
        .tappableCard(action: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(service.name)
        // VoiceOver gets the urgency as the value, matching the visual
        // hierarchy — weight and color don't survive a screen reader.
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(L10n.rowViewDetailsHint)
        .accessibilityAddTraits(.isButton)
    }

    /// Urgency, led by the status word wherever the text alone doesn't
    /// carry it ("300 mi left" is due soon or good depending on thresholds).
    private var accessibilityValue: String {
        guard let urgencyText else { return L10n.rowNoDueDate }
        switch status {
        case .dueSoon, .good:
            return L10n.readoutValueWithStatus(urgencyText, L10n.readoutStatus(status))
        case .overdue, .neutral:
            return urgencyText
        }
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
