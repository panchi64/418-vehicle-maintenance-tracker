//
//  HomeTab.swift
//  checkpoint
//
//  Home — a Readout. "What does this car need from me, and can I do it now?"
//
//  FIXED ORDER, ALWAYS THE SAME FIVE BLOCKS:
//    0. Vehicle band   odometer (tap → update; stale tag) | specs ⌄
//    1. Next Up        THE hero, ending in Mark Done (marbete: Mark Renewed)
//    2. Suggestions    at most ONE: the visit cluster or a seasonal item
//    3. Upcoming       the next 3 after Next Up
//    4. Recent         the last 3 logs
//
//  Sparse data never removes a section and never renders an apology card: an
//  empty section is its header plus one quiet `InsufficientDataNote`, so a new
//  user's Home already has the shape it will have later.
//
//  A safety recall outranks all of it and sits above Next Up when present.
//
//  Removed with this layout: the stale-mileage prompt card (the stale tag now
//  sits on the band's odometer cell, the control that resolves it), "Miles this
//  year", and the separate cluster and seasonal cards.
//
//  Spec: tools/sketchpad/src/screens/HomeTab.tsx.
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

    /// The expiration a pending "Mark Renewed" would set; drives its dialog.
    @State var pendingMarbeteRenewal: Vehicle.MarbeteExpiration?

    /// Scopes the service + log fetches to `vehicle` at the database level so a
    /// write to another vehicle's data doesn't re-run this tab's queries.
    /// `appState` and the model context arrive through the environment.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        _recallAcknowledgments = Query()
        if let vehicleID = vehicle?.id {
            _services = Query(filter: #Predicate<Service> { $0.vehicle?.id == vehicleID })
            // Sorted in the store, so Recent doesn't re-sort the whole history
            // to show three rows.
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

    var vehicle: Vehicle? {
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
    private func visibleRecalls(for vehicle: Vehicle) -> [RecallInfo] {
        RecallVisibility.visibleRecalls(
            from: appState.currentRecalls,
            acknowledgments: recallAcknowledgments.dictionary(forVehicle: vehicle.id)
        )
    }

    /// What this screen shows, derived in a single pass: one urgency sort, one
    /// walk of the mileage snapshots (Views/CLAUDE.md).
    struct Content {
        let nextUp: (any UpcomingItem)?
        /// The three due-tracking services after Next Up.
        let upcoming: [Service]
        let recentLogs: [ServiceLog]
        let suggestion: HomeSuggestion?
        let mileage: MileageEstimate
    }

    private func makeContent(for vehicle: Vehicle) -> Content {
        let mileage = vehicle.mileageEstimate
        let tracked = services.sortedByUrgency(mileage).filter { $0.hasDueTracking }

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
            upcoming: Array(remaining.prefix(3)),
            // Already newest-first from the query.
            recentLogs: Array(serviceLogs.prefix(3)),
            suggestion: HomeSuggestion.pick(
                cluster: primaryCluster,
                dismissedClusterHashes: dismissedClusterHashes,
                clusteringEnabled: ClusteringSettings.shared.isEnabled,
                seasonal: activeSeasonalReminders
            ),
            mileage: mileage
        )
    }

    var body: some View {
        Group {
            if let vehicle {
                ScrollView {
                    readout(for: vehicle, content: makeContent(for: vehicle))
                }
            } else {
                noVehicleState
            }
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
        .onAppear {
            loadDismissedClusters()
        }
        // The cluster sheets present from the root router (`ActiveSheet`);
        // marking one done bumps this token.
        .onChange(of: appState.clusterRefreshToken) { _, _ in
            detectClusters()
        }
        .marbeteRenewalDialog(pending: $pendingMarbeteRenewal) { expiration in
            if let vehicle { renewMarbete(of: vehicle, to: expiration) }
        }
    }

    @ViewBuilder
    private func readout(for vehicle: Vehicle, content: Content) -> some View {
        // Full-bleed, inside the scroll: it scrolls away with the content as
        // the large title collapses rather than pinning ~55pt of chrome.
        VehicleSummaryBand(
            vehicle: vehicle,
            onMileageTap: { appState.present(.mileageUpdate()) },
            onEdit: { appState.present(.editVehicle) },
            onDocumentsTap: { appState.push(.documents(vehicle)) }
        )
        .tourTarget(.vehicleSummary, active: onboardingState.currentPhase.isTour)

        VStack(alignment: .leading, spacing: Spacing.xl) {
            let recalls = visibleRecalls(for: vehicle)
            if !recalls.isEmpty {
                RecallAlertCard(
                    vehicle: vehicle,
                    recalls: recalls,
                    allRecalls: appState.currentRecalls,
                    appState: appState
                )
                .revealAnimation(delay: 0.05)
            }

            nextUpSection(content, vehicle: vehicle)
                .tourTarget(.homeNextUp, active: onboardingState.currentPhase.isTour)
                .revealAnimation(delay: 0.1)

            suggestionSection(content.suggestion)
                .revealAnimation(delay: 0.15)

            upcomingSection(content)
                .revealAnimation(delay: 0.2)

            recentSection(content)
                .revealAnimation(delay: 0.25)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.xxl)
    }

    // MARK: - Sections

    @ViewBuilder
    private func nextUpSection(_ content: Content, vehicle: Vehicle) -> some View {
        if let service = content.nextUp as? Service {
            NextUpCard(
                service: service,
                mileage: content.mileage,
                onOpen: { appState.push(.service(service)) },
                onMarkDone: {
                    appState.present(.markDone(MarkDoneRequest(services: [service], vehicle: vehicle)))
                }
            )
        } else if let marbete = content.nextUp as? MarbeteUpcomingItem {
            NextUpCard(
                marbete: marbete,
                // No marbete detail screen exists; its fields live on the vehicle.
                onOpen: { appState.present(.editVehicle) },
                onMarkRenewed: { pendingMarbeteRenewal = vehicle.renewedMarbeteExpiration() }
            )
        } else {
            ReadoutSection(title: L10n.homeNextUp) {
                InsufficientDataNote(message: L10n.homeNextUpEmpty)
            }
        }
    }

    private func suggestionSection(_ suggestion: HomeSuggestion?) -> some View {
        ReadoutSection(title: L10n.homeSuggestions) {
            if let suggestion {
                suggestionView(suggestion)
            } else {
                InsufficientDataNote(message: L10n.homeSuggestionsEmpty)
            }
        }
    }

    private func upcomingSection(_ content: Content) -> some View {
        ReadoutSection(title: L10n.homeUpcoming) {
            if content.upcoming.isEmpty {
                InsufficientDataNote(message: L10n.homeUpcomingEmpty)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(content.upcoming.enumerated()), id: \.element.id) { index, service in
                        ServiceRow(
                            service: service,
                            currentMileage: content.mileage.effective,
                            isEstimatedMileage: content.mileage.isEstimated
                        ) {
                            appState.push(.service(service))
                        }

                        if index < content.upcoming.count - 1 {
                            ListDivider()
                        }
                    }
                }
            }
        } action: {
            // Services' status groups contain every row shown here.
            if !content.upcoming.isEmpty {
                ReadoutSectionAction(label: L10n.commonViewAll) {
                    appState.selectedTab = .services
                }
            }
        }
    }

    private func recentSection(_ content: Content) -> some View {
        ReadoutSection(title: L10n.homeRecentActivity) {
            if content.recentLogs.isEmpty {
                InsufficientDataNote(message: L10n.homeRecentEmpty)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(content.recentLogs.enumerated()), id: \.element.id) { index, log in
                        activityRow(log: log)

                        if index < content.recentLogs.count - 1 {
                            ListDivider()
                        }
                    }
                }
            }
        } action: {
            // Services' history, never Costs: a maintenance-history list must
            // not point at a financial view.
            if !content.recentLogs.isEmpty {
                ReadoutSectionAction(label: L10n.commonViewAll) {
                    appState.selectedTab = .services
                }
            }
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
