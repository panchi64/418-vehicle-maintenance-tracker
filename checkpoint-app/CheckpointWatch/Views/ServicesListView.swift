//
//  ServicesListView.swift
//  CheckpointWatch
//
//  Main Watch screen: vehicle info + next 2-3 services
//  Brutalist aesthetic: monospace, ALL CAPS, zero radius
//

import SwiftUI

struct ServicesListView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity

    var body: some View {
        Group {
            if let vehicle = dataStore.vehicleData {
                servicesList(vehicle: vehicle)
            } else {
                emptyState
            }
        }
    }

    // MARK: - Services List

    private func servicesList(vehicle: WatchVehicleData) -> some View {
        List {
            // Vehicle header
            vehicleHeader(vehicle: vehicle)
                .listRowBackground(Color.clear)

            // Stale data indicator
            if dataStore.isStale {
                staleIndicator
                    .listRowBackground(Color.clear)
            }

            // Sync error indicator
            if let error = connectivity.lastSyncError {
                syncErrorIndicator(error)
                    .listRowBackground(Color.clear)
            }

            // Services
            let services = dataStore.sortedServices
            if services.isEmpty {
                noServicesRow
                    .listRowBackground(Color.clear)
            } else {
                ForEach(services.prefix(3)) { service in
                    NavigationLink(value: service) {
                        ServiceRowView(service: service)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("CHECKPOINT")
        .navigationDestination(for: WatchService.self) { service in
            MarkServiceDoneView(service: service)
        }
    }

    // MARK: - Vehicle Header

    private func vehicleHeader(vehicle: WatchVehicleData) -> some View {
        VStack(alignment: .leading, spacing: WatchSpacing.sm) {
            Text(vehicle.vehicleName.uppercased())
                .font(.watchHeadline)
                .foregroundStyle(WatchColors.accent)

            NavigationLink {
                MileageUpdateView()
            } label: {
                HStack(spacing: WatchSpacing.sm) {
                    let displayMileage = vehicle.estimatedMileage ?? vehicle.currentMileage
                    Text("\(displayMileage.formatted()) MI")
                        .font(.watchBody)
                        .foregroundStyle(WatchColors.textPrimary)

                    if vehicle.isEstimated {
                        Text("EST")
                            .font(.watchCaption)
                            .foregroundStyle(WatchColors.textTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(WatchColors.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: WatchSpacing.md) {
            Image(systemName: "car.fill")
                .font(.system(size: 28))
                .foregroundStyle(WatchColors.textTertiary)

            Text("OPEN CHECKPOINT\nON IPHONE")
                .font(.watchLabel)
                .foregroundStyle(WatchColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Indicators

    private var staleIndicator: some View {
        HStack(spacing: WatchSpacing.sm) {
            Rectangle()
                .fill(WatchColors.statusDueSoon)
                .frame(width: 4, height: 4)
            Text("DATA MAY BE OUTDATED")
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textTertiary)
        }
    }

    private func syncErrorIndicator(_ error: String) -> some View {
        Text(error.uppercased())
            .font(.watchCaption)
            .foregroundStyle(WatchColors.textTertiary)
    }

    private var noServicesRow: some View {
        Text("— NO SERVICES DUE —")
            .font(.watchLabel)
            .foregroundStyle(WatchColors.textTertiary)
    }
}

// MARK: - Hashable Conformance for Navigation

extension WatchService: Hashable {
    static func == (lhs: WatchService, rhs: WatchService) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
