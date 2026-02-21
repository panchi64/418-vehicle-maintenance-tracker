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
            .navigationTitle("Bundle Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - Summary Section

    private var clusterSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Summary")

            VStack(spacing: 0) {
                summaryRow(label: "SERVICES", value: "\(cluster.serviceCount)")

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)

                summaryRow(label: "WINDOW", value: cluster.windowDescription)

                if let mileage = cluster.suggestedMileage {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    summaryRow(label: "TARGET", value: Formatters.mileageDisplay(mileage), highlight: true)
                }

                if let date = cluster.suggestedDate {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    summaryRow(label: "DUE", value: Formatters.shortDate.string(from: date))
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    private func summaryRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Spacer()

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(highlight ? Theme.accent : Theme.textSecondary)
        }
        .padding(Spacing.md)
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Services")

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

            VStack(alignment: .leading, spacing: 2) {
                Text(service.name.uppercased())
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                if let desc = service.primaryDescription {
                    Text(desc)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            Text(status.label)
                .font(.brutalistLabel)
                .foregroundStyle(status.color)
                .tracking(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - Mark All Done Section

    private var markAllDoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: onMarkAllDone) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 16, weight: .semibold))

                    Text("MARK ALL DONE")
                        .font(.brutalistBody)
                        .tracking(1)
                }
                .foregroundStyle(Theme.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Theme.accent)
            }
            .buttonStyle(.plain)

            Text("LOG ALL \(cluster.serviceCount) SERVICES AT CURRENT MILEAGE")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("TIP")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1.5)

                Text("SCHEDULE TOGETHER")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Text("Handling multiple services in one visit reduces trips and may lower labor costs.")
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
