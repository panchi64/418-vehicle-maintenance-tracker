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
                staleIndicator(updatedAt: vehicle.updatedAt)
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

                if services.count > 3 {
                    Text("\(services.count - 3) MORE")
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(Text(verbatim: "CHECKPOINT"))
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
                    let unit = vehicle.resolvedDistanceUnit
                    Text(verbatim: "\(unit.fromMiles(displayMileage).formatted()) \(unit.abbreviation)")
                        .font(.watchBody)
                        .foregroundStyle(WatchColors.textPrimary)

                    if vehicle.isEstimated {
                        Text("EST")
                            .font(.watchCaption)
                            .foregroundStyle(WatchColors.textTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)
                        .accessibilityHidden(true)
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

    /// How old the figures are, once the last sync is over an hour back.
    private func staleIndicator(updatedAt: Date) -> some View {
        let stamp = Calendar.current.isDateInToday(updatedAt)
            ? updatedAt.formatted(date: .omitted, time: .shortened)
            : updatedAt.formatted(.dateTime.month(.abbreviated).day())
        return Label {
            Text("AS OF \(stamp)")
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
        } icon: {
            Image(systemName: "clock")
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
        }
    }

    private func syncErrorIndicator(_ error: String) -> some View {
        Text(error.uppercased())
            .font(.watchCaption)
            .foregroundStyle(WatchColors.textSecondary)
    }

    private var noServicesRow: some View {
        Text("NO SERVICES DUE")
            .font(.watchLabel)
            .foregroundStyle(WatchColors.textSecondary)
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
