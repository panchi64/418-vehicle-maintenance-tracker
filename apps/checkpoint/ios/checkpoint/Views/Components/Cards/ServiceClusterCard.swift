//
//  ServiceClusterCard.swift
//  checkpoint
//
//  Brutalist card showing bundling opportunity for services due around the same time
//

import SwiftUI

struct ServiceClusterCard: View {
    let cluster: ServiceCluster
    let onTap: () -> Void
    let onDismiss: () -> Void

    private var status: ServiceStatus {
        cluster.mostUrgentStatus
    }

    private var isUrgent: Bool {
        status == .overdue || status == .dueSoon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row: accent square + label. The dismiss button is
            // overlaid (below) so it stays outside the combined element.
            HStack(alignment: .top) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: Theme.accent, isActive: isUrgent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SERVICE VISIT OPPORTUNITY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)

                    Text("\(cluster.serviceCount) SERVICES DUE SOON")
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        .textCase(.uppercase)
                }

                Spacer(minLength: TouchTarget.minimum)
            }
            .padding(.bottom, Spacing.md)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Service list (max 4, with +N more)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(cluster.services.prefix(4)), id: \.id) { service in
                    let serviceStatus = service.status(currentMileage: effectiveMileage)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Rectangle()
                            .fill(serviceStatus.color)
                            .frame(width: 4, height: 4)
                            .accessibilityHidden(true)

                        Text(service.name.uppercased())
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)

                        // The square's color is the status; the word says it
                        // too, for color-blind users and VoiceOver.
                        if !serviceStatus.label.isEmpty {
                            Text(serviceStatus.label)
                                .font(.brutalistLabel)
                                .foregroundStyle(serviceStatus.color)
                                .tracking(1)
                        }
                    }
                }

                if cluster.serviceCount > 4 {
                    Text("+\(cluster.serviceCount - 4) MORE")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                }
            }
            .padding(.vertical, Spacing.listItem)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Technical data rows
            VStack(spacing: Spacing.sm) {
                AdaptiveStack {
                    Text("WINDOW")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    Spacer()

                    Text("WITHIN \(cluster.windowDescription)")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textSecondary)
                }

                if let targetMileage = cluster.suggestedMileage {
                    AdaptiveStack {
                        Text("TARGET")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Spacer()

                        Text("@ \(Formatters.mileageDisplay(targetMileage))")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(.top, Spacing.listItem)
        }
        .glassCardStyle(intensity: .subtle)
        .tappableCard(action: onTap)
        // Reads the header, each service with its status, and the window —
        // the datum, in reading order. The dismiss button is overlaid after
        // this so it remains its own element instead of being swallowed.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .topTrailing) {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .minimumTouchTarget()
            }
            .buttonStyle(.plain)
            // Same position it had inside the header row, whose trailing
            // spacer still reserves room for it.
            .padding([.top, .trailing], Theme.cardPadding)
            .accessibilityLabel(L10n.readoutDismissVisitSuggestion)
        }
    }

    private var effectiveMileage: Int {
        cluster.vehicle.effectiveMileage
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: Array(services.prefix(3)),
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return ZStack {
        AtmosphericBackground()

        ServiceClusterCard(
            cluster: cluster,
            onTap: { print("Tapped cluster") },
            onDismiss: { print("Dismissed cluster") }
        )
        .padding(Theme.screenHorizontalPadding)
    }
    .preferredColorScheme(.dark)
}
