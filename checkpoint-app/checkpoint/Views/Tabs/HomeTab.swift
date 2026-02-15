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
    @Environment(\.modelContext) var modelContext
    @Query var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    // Cluster state
    @State var primaryCluster: ServiceCluster?
    @State var dismissedClusterHashes: Set<String> = []
    @AppStorage("dismissedClusterHashes") var dismissedClusterHashesStorage: String = ""

    // Seasonal reminders
    @State var activeSeasonalReminders: [SeasonalReminder] = []

    private var syncService: SyncStatusService {
        SyncStatusService.shared
    }

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    var vehicleServices: [Service] {
        guard let vehicle = vehicle else { return [] }
        return services.forVehicle(vehicle)
    }

    /// The most urgent upcoming item (service or marbete)
    private var nextUpItem: (any UpcomingItem)? {
        vehicle?.nextUpItem
    }

    private var nextUpService: Service? {
        vehicleServices.first
    }

    private var remainingServices: [Service] {
        let tracked = vehicleServices.filter { $0.hasDueTracking }
        // If marbete is the most urgent, don't drop a service from remaining
        if let nextUp = nextUpItem, nextUp.itemType == .marbete {
            return tracked
        }
        return Array(tracked.dropFirst())
    }

    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs.filter { $0.vehicle?.id == vehicle.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Instrument cluster: compact status cards grouped tightly
                VStack(spacing: Spacing.md) {
                    // Recall Alert Card (safety-critical, shown above everything)
                    if !appState.currentRecalls.isEmpty {
                        RecallAlertCard(recalls: appState.currentRecalls)
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
                        QuickMileageUpdateCard(
                            vehicle: vehicle,
                            mileageTrackedServiceCount: vehicleServices.filter { $0.dueMileage != nil }.count
                        ) { newMileage in
                            AnalyticsService.shared.capture(.mileageUpdated(source: .quickUpdate))
                            updateMileage(newMileage, for: vehicle)
                        }
                        .onAppear {
                            AnalyticsService.shared.capture(.mileagePromptShown)
                        }
                        .revealAnimation(delay: 0.15)
                    }
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
                            AnalyticsService.shared.capture(.serviceClusterTapped)
                            appState.selectedCluster = cluster
                        },
                        onDismiss: {
                            dismissCluster(cluster)
                        }
                    )
                    .revealAnimation(delay: 0.25)
                }

                // Seasonal Advisory Cards (max 2)
                ForEach(Array(activeSeasonalReminders.prefix(2)), id: \.id) { reminder in
                    SeasonalReminderCard(
                        reminder: reminder,
                        onScheduleService: {
                            scheduleSeasonalService(reminder)
                        },
                        onDismiss: {
                            dismissSeasonalReminder(reminder)
                        }
                    )
                    .revealAnimation(delay: 0.3)
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
                    if case .syncing = syncService.syncState {
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
            detectClusters()
            refreshSeasonalReminders()
        }
        .onChange(of: vehicleServices.count) { _, _ in
            detectClusters()
        }
        .trackScreen(.home)
        .onAppear {
            loadDismissedClusters()
            refreshSeasonalReminders()
        }
        .sheet(item: $appState.selectedCluster) { cluster in
            ServiceClusterDetailSheet(
                cluster: cluster,
                onServiceTap: { service in
                    appState.selectedCluster = nil
                    appState.selectedService = service
                },
                onMarkAllDone: {
                    AnalyticsService.shared.capture(.serviceClusterMarkAllDone)
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
