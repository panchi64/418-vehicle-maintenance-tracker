//
//  HomeTab.swift
//  checkpoint
//
//  Home tab showing glanceable "what's next" overview
//

import SwiftUI
import SwiftData

struct HomeTab: View {
    @Environment(AppState.self) var appState
    let onboardingState: OnboardingState
    @Environment(\.modelContext) var modelContext
    @Query var services: [Service]
    @Query private var serviceLogs: [ServiceLog]
    @Query private var recallAcknowledgments: [RecallAcknowledgment]

    // Cluster state
    @State var primaryCluster: ServiceCluster? = nil
    @State var dismissedClusterHashes: Set<String> = []
    @AppStorage("dismissedClusterHashes") var dismissedClusterHashesStorage: String = ""

    // Seasonal reminders
    @State var activeSeasonalReminders: [SeasonalReminder] = []

    /// Scopes the service + log fetches to `vehicle` at the database level so a
    /// write to another vehicle's data doesn't re-run this tab's queries.
    /// `appState` and the model context arrive through the environment.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        _recallAcknowledgments = Query()
        if let vehicleID = vehicle?.id {
            _services = Query(filter: #Predicate<Service> { $0.vehicle?.id == vehicleID })
            // Sorted in the store, so Recent Activity doesn't re-sort the whole
            // history to show three rows.
            _serviceLogs = Query(
                filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID },
                sort: \.performedDate,
                order: .reverse
            )
        } else {
            _services = Query(filter: #Predicate<Service> { _ in false })
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { _ in false })
        }
    }

    private var syncService: SyncStatusService {
        SyncStatusService.shared
    }

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    /// Used by cluster detection, which runs on an event rather than in `body`.
    /// Anything the body needs comes from `Content` instead.
    var vehicleServices: [Service] {
        guard let vehicle = vehicle else { return [] }
        return services.sortedByUrgency(vehicle.mileageEstimate)
    }

    /// Recalls that should appear on Home: drops resolved + actively snoozed,
    /// but never hides a parkIt recall (safety override).
    private var visibleRecalls: [RecallInfo] {
        guard let vehicle = vehicle else { return [] }
        return RecallVisibility.visibleRecalls(
            from: appState.currentRecalls,
            acknowledgments: recallAcknowledgments.dictionary(forVehicle: vehicle.id)
        )
    }

    /// What this screen shows, derived in a single pass.
    ///
    /// The pieces below were computed properties that SwiftUI read repeatedly per
    /// body evaluation — `remainingServices` alone was read four times, and each
    /// read re-ran an urgency sort plus `nextUpItem`, which walks every mileage
    /// snapshot to re-derive the driving pace. Now: one sort, one pace.
    private struct Content {
        let nextUp: (any UpcomingItem)?
        /// Due-tracking services minus whatever Next Up is already showing.
        let remaining: [Service]
        let hasAnyService: Bool
        let recentLogs: [ServiceLog]
        let logCount: Int
        let mileageTrackedCount: Int
        let mileage: MileageEstimate
    }

    private func makeContent() -> Content {
        guard let vehicle else {
            return Content(
                nextUp: nil,
                remaining: [],
                hasAnyService: false,
                recentLogs: [],
                logCount: 0,
                mileageTrackedCount: 0,
                mileage: MileageEstimate(pace: nil, effective: 0, isEstimated: false)
            )
        }

        let mileage = vehicle.mileageEstimate
        let sorted = services.sortedByUrgency(mileage)
        let tracked = sorted.filter { $0.hasDueTracking }

        // Next Up is the most urgent tracked service unless the marbete beats it.
        let nextUp = vehicle.mostUrgentUpcomingItem(mileage: mileage, tracked: tracked)

        // Drop the service Next Up is already showing — but if the marbete won,
        // no service was consumed.
        let remaining: [Service]
        if let nextUp, nextUp.itemType == .service {
            remaining = tracked.filter { $0.id != nextUp.id }
        } else {
            remaining = tracked
        }

        return Content(
            nextUp: nextUp,
            remaining: remaining,
            hasAnyService: !sorted.isEmpty,
            // Already newest-first from the query.
            recentLogs: Array(serviceLogs.prefix(3)),
            logCount: serviceLogs.count,
            mileageTrackedCount: sorted.filter { $0.dueMileage != nil }.count,
            mileage: mileage
        )
    }

    var body: some View {
        @Bindable var appState = appState
        let content = makeContent()
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Recall alert is safety-critical and outranks everything else,
                // so it stays first.
                //
                // It used to share a tighter-spaced wrapper VStack with
                // QuickSpecsCard. With specs moved to the persistent shell in
                // ContentView, that wrapper was left empty whenever there was no
                // recall — still consuming Spacing.xl above and below, so the
                // screen opened with ~64pt of dead space.
                if let vehicle = vehicle, !visibleRecalls.isEmpty {
                    RecallAlertCard(
                        vehicle: vehicle,
                        recalls: visibleRecalls,
                        allRecalls: appState.currentRecalls,
                        appState: appState
                    )
                    .revealAnimation(delay: 0.05)
                }

                // Next Up hero card (service or marbete, whichever is more urgent)
                if let nextUp = content.nextUp, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Next Up")

                        // Display appropriate card based on item type
                        switch nextUp.itemType {
                        case .service:
                            if let service = nextUp as? Service {
                                NextUpCard(
                                    service: service,
                                    currentMileage: content.mileage.effective,
                                    vehicleName: vehicle.displayName,
                                    dailyMilesPace: content.mileage.pace,
                                    isEstimatedMileage: content.mileage.isEstimated
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
                    .revealAnimation(delay: 0.15)
                }

                // Quick Mileage Update Card (shown if never updated or 14+ days ago)
                if let vehicle = vehicle, vehicle.shouldPromptMileageUpdate {
                    QuickMileageUpdateCard(
                        vehicle: vehicle,
                        mileageTrackedServiceCount: content.mileageTrackedCount
                    ) { newMileage in
                        AnalyticsService.shared.capture(.mileageUpdated(source: .quickUpdate))
                        updateMileage(newMileage, for: vehicle)
                    }
                    .onAppear {
                        AnalyticsService.shared.capture(.mileagePromptShown)
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

                // Upcoming services list (max 3 for home tab).
                //
                // No bordered container. Rows separated by dividers under a
                // titled header already read as one group — proximity carries
                // grouping before borders do — and the box put a second
                // enclosure inside a screen whose hero cards are already boxed,
                // so the list competed with the thing it sits beneath.
                if !content.remaining.isEmpty {
                    ReadoutSection(title: L10n.homeUpcoming) {
                        VStack(spacing: 0) {
                            ForEach(Array(content.remaining.prefix(3).enumerated()), id: \.element.id) { index, service in
                                ServiceRow(
                                    service: service,
                                    currentMileage: content.mileage.effective,
                                    isEstimatedMileage: content.mileage.isEstimated
                                ) {
                                    appState.selectedService = service
                                }
                                .staggeredReveal(index: index, baseDelay: 0.25)

                                if index < min(content.remaining.count, 3) - 1 {
                                    ListDivider()
                                }
                            }
                        }
                    } action: {
                        if content.remaining.count > 3 {
                            ReadoutSectionAction(label: L10n.commonViewAll) {
                                appState.selectedTab = .services
                            }
                        }
                    }
                }

                // Recent Activity Feed (max 3, with View All)
                if !content.recentLogs.isEmpty {
                    ReadoutSection(title: L10n.homeRecentActivity) {
                        VStack(spacing: 0) {
                            ForEach(Array(content.recentLogs.enumerated()), id: \.element.id) { index, log in
                                // ServiceEventRow owns its own tap target.
                                activityRow(log: log)

                                if index < content.recentLogs.count - 1 {
                                    ListDivider()
                                }
                            }
                        }
                    } action: {
                        if content.logCount > 3 {
                            // Services, not Costs. This sent a maintenance
                            // history list to a financial view — the rule is
                            // that "View All" lands on a list containing the
                            // items the section actually showed.
                            ReadoutSectionAction(label: L10n.commonViewAll) {
                                appState.selectedTab = .services
                            }
                        }
                    }
                    .revealAnimation(delay: 0.35)
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
                } else if !content.hasAnyService && vehicle != nil {
                    noServicesState
                        .revealAnimation(delay: 0.2)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl + Spacing.tabBarOffset)
        }
        .task(id: vehicle?.id) {
            detectClusters()
            refreshSeasonalReminders()
        }
        // `services` is already scoped to this vehicle by the query, so the count
        // is the same one `vehicleServices` would report — without paying for an
        // urgency sort on every body evaluation just to read it.
        .onChange(of: services.count) { _, _ in
            detectClusters()
        }
        .trackScreen(.home)
        // No `refreshSeasonalReminders()` here — the `.task` above already runs it
        // on every appearance, and doing it twice meant two extra `@State` writes,
        // each triggering another pass over this whole body.
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
            .environment(appState)
        }
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        HomeTab(vehicle: appState.selectedVehicle, onboardingState: OnboardingState())
    }
    .environment(appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .preferredColorScheme(.dark)
}
