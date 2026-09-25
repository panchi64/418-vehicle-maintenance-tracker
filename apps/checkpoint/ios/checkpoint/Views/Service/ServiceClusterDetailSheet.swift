//
//  ServiceClusterDetailSheet.swift
//  checkpoint
//
//  Detail sheet showing all services in a cluster with mark all done option
//

import SwiftUI

struct ServiceClusterDetailSheet: View {
    let cluster: ServiceCluster
    let onServiceTap: (Service) -> Void
    let onMarkAllDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Summary section
                        clusterSummarySection

                        // Services list
                        servicesSection

                        // Mark All Done action
                        markAllDoneSection

                        // Tip section
                        tipSection

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(L10n.clusterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - Summary Section

    private var clusterSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.clusterSummary)

            VStack(spacing: 0) {
                summaryRow(label: L10n.clusterRowServices, value: "\(cluster.serviceCount)")

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                summaryRow(label: L10n.clusterRowWindow, value: cluster.windowDescription)

                if let mileage = cluster.suggestedMileage {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    summaryRow(label: L10n.clusterRowTarget, value: Formatters.mileageDisplay(mileage), highlight: true)
                }

                if let date = cluster.suggestedDate {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    summaryRow(label: L10n.clusterRowDue, value: Formatters.shortDate.string(from: date))
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    private func summaryRow(label: String, value: String, highlight: Bool = false) -> some View {
        AdaptiveStack(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.xs) {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            AdaptiveSpacer()

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(highlight ? Theme.accent : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.clusterServices)

            VStack(spacing: 0) {
                ForEach(Array(cluster.services.enumerated()), id: \.element.id) { index, service in
                    Button {
                        onServiceTap(service)
                    } label: {
                        serviceRow(service: service)
                    }
                    .buttonStyle(.plain)

                    if index < cluster.services.count - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    private func serviceRow(service: Service) -> some View {
        let status = service.status(currentMileage: cluster.vehicle.effectiveMileage)

        return HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            // The status word stacks under the name at accessibility sizes
            // rather than squeezing it to a sliver.
            AdaptiveStack(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name.uppercased())
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    if let desc = service.primaryDescription {
                        Text(desc)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                AdaptiveSpacer()

                Text(status.label)
                    .font(.brutalistLabel)
                    .foregroundStyle(status.color)
                    .tracking(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mark All Done Section

    private var markAllDoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: onMarkAllDone) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.body.weight(.semibold))
                        .accessibilityHidden(true)

                    Text(L10n.clusterMarkAllDone)
                        .font(.brutalistBody)
                        .tracking(1)
                }
                .foregroundStyle(Theme.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Theme.accent)
            }
            .buttonStyle(.plain)

            Text(L10n.clusterLogAll(cluster.serviceCount))
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text(L10n.clusterTipLabel)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1.5)

                Text(L10n.clusterTipTitle)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Text(L10n.clusterTipBody)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(4)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument.opacity(0.5))
        .brutalistBorder()
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: services,
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return ServiceClusterDetailSheet(
        cluster: cluster,
        onServiceTap: { service in print("Tapped \(service.name)") },
        onMarkAllDone: { print("Mark all done") }
    )
    .preferredColorScheme(.dark)
}
