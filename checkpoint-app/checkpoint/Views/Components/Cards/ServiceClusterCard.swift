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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row: status square + label + dismiss button
                HStack(alignment: .top) {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .statusGlow(color: Theme.accent, isActive: isUrgent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("BUNDLE OPPORTUNITY")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .tracking(1.5)

                        Text("\(cluster.serviceCount) SERVICES DUE SOON")
                            .font(.brutalistHeading)
                            .foregroundStyle(Theme.textPrimary)
                            .textCase(.uppercase)
                    }

                    Spacer()

                    // Dismiss button (prevent triggering main tap)
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 16)

                // Divider
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                // Service list (max 4, with +N more)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(cluster.services.prefix(4)), id: \.id) { service in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(service.status(currentMileage: cluster.vehicle.effectiveMileage).color)
                                .frame(width: 4, height: 4)

                            Text(service.name.uppercased())
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    if cluster.serviceCount > 4 {
                        Text("+\(cluster.serviceCount - 4) MORE")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                }
                .padding(.vertical, 12)

                // Divider
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                // Technical data rows
                VStack(spacing: 8) {
                    HStack {
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
                        HStack {
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
                .padding(.top, 12)
            }
            .glassCardStyle(intensity: .subtle)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bundle opportunity, \(cluster.serviceCount) services due soon")
        .accessibilityHint("Tap to view details, or dismiss")
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
