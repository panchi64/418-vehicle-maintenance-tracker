//
//  HomeTab.swift
//  checkpoint
//
//  Home tab showing glanceable "what's next" overview
//

import SwiftUI
import SwiftData

struct HomeTab: View {
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    // Recall alert state
    @State private var recalls: [RecallInfo] = []

    // Cluster state
    @State private var primaryCluster: ServiceCluster?
    @State private var dismissedClusterHashes: Set<String> = []
    @AppStorage("dismissedClusterHashes") private var dismissedClusterHashesStorage: String = ""

    private var syncService: CloudSyncStatusService {
        CloudSyncStatusService.shared
    }

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    private var vehicleServices: [Service] {
        guard let vehicle = vehicle else { return [] }
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace
        return services
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) < $1.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) }
    }

    /// The most urgent upcoming item (service or marbete)
    private var nextUpItem: (any UpcomingItem)? {
        vehicle?.nextUpItem
    }

    private var nextUpService: Service? {
        vehicleServices.first
    }

    private var remainingServices: [Service] {
        // If marbete is the most urgent, don't drop a service from remaining
        if let nextUp = nextUpItem, nextUp.itemType == .marbete {
            return vehicleServices
        }
        return Array(vehicleServices.dropFirst())
    }

    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs.filter { $0.vehicle?.id == vehicle.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Recall Alert Card (safety-critical, shown above everything)
                if !recalls.isEmpty {
                    RecallAlertCard(recalls: recalls)
                        .revealAnimation(delay: 0.05)
                }

                // Quick Specs Card
                if let vehicle = vehicle {
                    QuickSpecsCard(vehicle: vehicle) {
                        appState.showEditVehicle = true
                    }
                    .revealAnimation(delay: 0.1)
                }

                // Quick Mileage Update Card (shown if never updated or 14+ days ago)
                if let vehicle = vehicle, vehicle.shouldPromptMileageUpdate {
                    QuickMileageUpdateCard(vehicle: vehicle) { newMileage in
                        updateMileage(newMileage, for: vehicle)
                    }
                    .revealAnimation(delay: 0.15)
                }

                // Next Up hero card (service or marbete, whichever is more urgent)
                if let nextUp = nextUpItem, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Next Up")

                        // Display appropriate card based on item type
                        switch nextUp.itemType {
                        case .service:
                            if let service = nextUp as? Service {
                                NextUpCard(
                                    service: service,
                                    currentMileage: vehicle.effectiveMileage,
                                    vehicleName: vehicle.displayName,
                                    dailyMilesPace: vehicle.dailyMilesPace,
                                    isEstimatedMileage: vehicle.isUsingEstimatedMileage
                                ) {
                                    appState.selectedService = service
                                }
                            }
                        case .marbete:
                            if let marbeteItem = nextUp as? MarbeteUpcomingItem {
                                MarbeteNextUpCard(
                                    marbeteItem: marbeteItem,
                                    vehicleName: vehicle.displayName
                                ) {
                                    // Navigate to EditVehicleView to update marbete
                                    appState.showEditVehicle = true
                                }
                            }
                        }
                    }
                    .revealAnimation(delay: 0.2)
                }

                // Service Cluster Suggestion Card (after Next Up)
                if let cluster = primaryCluster,
                   !dismissedClusterHashes.contains(cluster.contentHash),
                   ClusteringSettings.shared.isEnabled {
                    ServiceClusterCard(
                        cluster: cluster,
                        onTap: {
                            appState.selectedCluster = cluster
                        },
                        onDismiss: {
                            dismissCluster(cluster)
                        }
                    )
                    .revealAnimation(delay: 0.25)
                }

                // Upcoming services list (max 3 for home tab)
                if !remainingServices.isEmpty, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            InstrumentSectionHeader(title: "Upcoming")
                            Spacer()
                            if remainingServices.count > 3 {
                                Button {
                                    appState.navigateToServices()
                                } label: {
                                    Text("View All")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.accent)
                                        .tracking(1)
                                }
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(remainingServices.prefix(3).enumerated()), id: \.element.id) { index, service in
                                ServiceRow(
                                    service: service,
                                    currentMileage: vehicle.effectiveMileage,
                                    isEstimatedMileage: vehicle.isUsingEstimatedMileage
                                ) {
                                    appState.selectedService = service
                                }
                                .staggeredReveal(index: index, baseDelay: 0.25)

                                if index < min(remainingServices.count, 3) - 1 {
                                    ListDivider()
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )
                    }
                }

                // Recent Activity Feed (max 3, with VIEW_ALL)
                if !vehicleServiceLogs.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            InstrumentSectionHeader(title: "Recent Activity")
                            Spacer()
                            if vehicleServiceLogs.count > 3 {
                                Button {
                                    appState.navigateToServices()
                                } label: {
                                    Text("View All")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.accent)
                                        .tracking(1)
                                }
                            }
                        }

                        VStack(spacing: 0) {
                            let recentLogs = vehicleServiceLogs
                                .sorted { $0.performedDate > $1.performedDate }
                                .prefix(3)

                            ForEach(Array(recentLogs.enumerated()), id: \.element.id) { index, log in
                                Button {
                                    appState.selectedServiceLog = log
                                } label: {
                                    activityRow(log: log)
                                }
                                .buttonStyle(.plain)

                                if index < recentLogs.count - 1 {
                                    ListDivider(leadingPadding: 28)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )
                    }
                    .revealAnimation(delay: 0.35)
                }

                // Quick Stats Bar
                if vehicle != nil {
                    QuickStatsBar(serviceLogs: vehicleServiceLogs)
                        .revealAnimation(delay: 0.4)
                }

                // Empty states
                if appState.selectedVehicle == nil {
                    if case .syncing = syncService.status {
                        syncingDataState
                            .revealAnimation(delay: 0.2)
                    } else {
                        emptyVehicleState
                            .revealAnimation(delay: 0.2)
                    }
                } else if vehicleServices.isEmpty && vehicle != nil {
                    noServicesState
                        .revealAnimation(delay: 0.2)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl + 56) // Extra padding for FAB and tab bar
        }
        .task(id: vehicle?.id) {
            await fetchRecalls()
            detectClusters()
        }
        .onChange(of: vehicleServices.count) { _, _ in
            detectClusters()
        }
        .onAppear {
            loadDismissedClusters()
        }
        .sheet(item: $appState.selectedCluster) { cluster in
            ServiceClusterDetailSheet(
                cluster: cluster,
                onServiceTap: { service in
                    appState.selectedCluster = nil
                    appState.selectedService = service
                },
                onMarkAllDone: {
                    appState.selectedCluster = nil
                    appState.clusterToMarkDone = cluster
                }
            )
        }
        .sheet(item: $appState.clusterToMarkDone) { cluster in
            MarkClusterDoneSheet(cluster: cluster) {
                detectClusters()
            }
        }
    }

    // MARK: - Activity Row

    private func activityRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(Formatters.shortDate.string(from: log.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - Empty States

    private var syncingDataState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: Spacing.xs) {
                Text("Syncing Your Data")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Restoring your vehicles and maintenance\nhistory from iCloud")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            ProgressView()
                .tint(Theme.accent)
                .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xxl)
    }

    private var emptyVehicleState: some View {
        EmptyStateView(
            icon: "car.side.fill",
            title: "No Vehicles",
            message: "Add your first vehicle to start\ntracking maintenance",
            action: { appState.showAddVehicle = true },
            actionLabel: "Add Vehicle"
        )
    }

    private var noServicesState: some View {
        EmptyStateView(
            icon: "checkmark",
            title: "All Clear",
            message: "No maintenance services scheduled\nfor this vehicle"
        )
    }

    // MARK: - Recall Fetch

    private func fetchRecalls() async {
        guard let vehicle = vehicle,
              !vehicle.make.isEmpty,
              !vehicle.model.isEmpty,
              vehicle.year > 0 else {
            recalls = []
            return
        }

        do {
            recalls = try await NHTSAService.shared.fetchRecalls(
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year
            )
        } catch {
            // Silently fail — recalls are supplementary info
            recalls = []
        }
    }

    // MARK: - Cluster Management

    private func detectClusters() {
        guard let vehicle = vehicle else {
            primaryCluster = nil
            return
        }
        primaryCluster = ServiceClusteringService.primaryCluster(
            for: vehicle,
            services: vehicleServices
        )
    }

    private func dismissCluster(_ cluster: ServiceCluster) {
        dismissedClusterHashes.insert(cluster.contentHash)
        saveDismissedClusters()
    }

    private func loadDismissedClusters() {
        dismissedClusterHashes = Set(
            dismissedClusterHashesStorage
                .split(separator: ",")
                .map(String.init)
        )
    }

    private func saveDismissedClusters() {
        dismissedClusterHashesStorage = dismissedClusterHashes.joined(separator: ",")
    }

    // MARK: - Helpers

    private func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = .now

        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots ?? []
        )

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: newMileage,
                recordedAt: .now,
                source: .manual
            )
            modelContext.insert(snapshot)
        }

        // Force immediate save to trigger SwiftUI observation for dependent views
        try? modelContext.save()

        // Update app icon based on new mileage affecting service status
        AppIconService.shared.updateIcon(for: vehicle, services: services)

        // Reschedule mileage reminder for 14 days from now
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)

        // Reschedule service notifications with updated pace data
        NotificationService.shared.rescheduleNotifications(for: vehicle)
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        HomeTab(appState: appState)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .preferredColorScheme(.dark)
}
