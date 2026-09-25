//
//  ContentView+Modifiers.swift
//  checkpoint
//
//  Grouped modifier chains extracted from ContentView's body: the root sheet
//  router, the onboarding full-screen surfaces and tour overlay, and the
//  notification-routing handlers. Each takes the content it decorates and
//  returns it with the group applied, keeping the root body scannable.
//

import SwiftUI
import SwiftData

extension ContentView {

    // MARK: - Sheet Router

    /// Every root task sheet, through one `.sheet(item:)`. `AppState.present`
    /// queues a sheet requested while another is on screen and this
    /// `onDismiss` presents it, so "dismiss one, present the next" can no
    /// longer drop the second.
    func sheetRouter(_ content: some View) -> some View {
        content
            .sheet(item: $appState.activeSheet, onDismiss: handleSheetDismiss) { sheet in
                sheetContent(for: sheet)
                    .environment(appState)
                    .onAppear { appState.sheetDidAppear(sheet) }
            }
            // AppState only queues the tip prompt (pure state); the delayed
            // presentation effect belongs to the view layer, so it lives here.
            .onChange(of: appState.tipPromptQueued) { _, queued in
                guard queued else { return }
                presentQueuedTipPrompt()
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .vehiclePicker:
            VehiclePickerSheet(
                selectedVehicle: Binding(
                    get: { appState.selectedVehicle },
                    set: { appState.selectVehicle($0) }
                ),
                // Queued by `present` until the picker has closed.
                onAddVehicle: { appState.requestAddVehicle(vehicleCount: vehicles.count) }
            )

        case .addVehicle:
            AddVehicleFlowView()

        case .editVehicle:
            if let vehicle = currentVehicle {
                EditVehicleView(vehicle: vehicle)
            } else {
                noVehicleFallback
            }

        case .addService(let seasonal, let postRecord):
            if let vehicle = currentVehicle {
                AddServiceView(
                    vehicle: vehicle,
                    seasonalPrefill: seasonal,
                    postRecordPrefill: postRecord
                )
            } else {
                noVehicleFallback
            }

        case .mileageUpdate(let prefilled):
            if let vehicle = currentVehicle {
                MileageUpdateSheet(
                    vehicle: vehicle,
                    prefilledMileage: prefilled,
                    onSave: { newMileage in
                        AnalyticsService.shared.capture(.mileageUpdated(source: .manual))
                        updateMileage(newMileage, for: vehicle)
                        ToastService.shared.show(L10n.toastMileageUpdated, icon: "gauge.medium", style: .success)
                    }
                )
                .trackScreen(.mileageUpdate)
                .presentationDetents([.medium, .large])
            } else {
                noVehicleFallback
            }

        case .settings:
            SettingsView(
                onboardingState: onboardingState,
                onReplayTour: {
                    // Skip the intro re-prompt — the user already set their
                    // preferences. Seed sample data (same hook the intro's
                    // onStartTour uses) and jump straight to step 0.
                    AnalyticsService.shared.capture(.onboardingTourStarted)
                    seedSampleDataForTour()
                    onboardingState.replayTour()
                }
            )
            .onAppear {
                AnalyticsService.shared.capture(.settingsOpened)
            }

        case .proPaywall:
            ProPaywallSheet()

        case .tipModal:
            TipModalView(isPrompt: true)

        case .themeReveal(let theme):
            ThemeRevealView(theme: theme)

        case .markDone(let request):
            MarkServiceVisitDoneSheet(origin: markDoneOrigin(for: request))

        case .clusterDetail(let cluster):
            ServiceClusterDetailSheet(
                cluster: cluster,
                onServiceTap: { service in
                    appState.showDetail(.service(service))
                },
                onMarkAllDone: {
                    AnalyticsService.shared.capture(.serviceClusterMarkAllDone)
                    appState.present(.clusterMarkDone(cluster))
                }
            )

        case .clusterMarkDone(let cluster):
            MarkClusterDoneSheet(cluster: cluster) {
                appState.clusterRefreshToken += 1
            }

        case .starterSchedule(let vehicle):
            StarterScheduleSheet(vehicle: vehicle)
        }
    }

    /// `currentVehicle` can resolve to nil if the selected vehicle is deleted
    /// (locally or by an arriving iCloud delete) while a sheet is in flight.
    /// A dismissible fallback rather than an empty sheet the user can only
    /// swipe away.
    private var noVehicleFallback: some View {
        NavigationStack {
            EmptyStateView(
                icon: "car.side.fill",
                title: L10n.emptyNoVehicleTitle,
                message: L10n.emptyNoVehicleMessage,
                action: { appState.dismissSheet() },
                actionLabel: L10n.commonClose
            )
        }
    }

    /// Once a sheet has finished closing (and any queued sheet is on its way
    /// up): the moment a service may have just come into existence, which is
    /// when asking about reminders makes sense.
    private func handleSheetDismiss() {
        switch appState.sheetDidDismiss() {
        case .addService, .markDone, .clusterMarkDone, .starterSchedule:
            considerNotificationPrePrompt()
        default:
            break
        }
    }

    // MARK: - Onboarding Surfaces

    func onboardingSurfaces(_ content: some View) -> some View {
        content
            .fullScreenCover(isPresented: Binding(
                get: { showOnboardingIntro },
                set: { if !$0 { /* dismiss handled by callbacks */ } }
            )) {
                OnboardingIntroView(
                    onStartTour: {
                        AnalyticsService.shared.capture(.onboardingTourStarted)
                        seedSampleDataForTour()
                        onboardingState.startTour()
                    },
                    onSkip: {
                        AnalyticsService.shared.capture(.onboardingIntroSkipped)
                        onboardingState.complete()
                    }
                )
            }
            .overlay {
                GeometryReader { geo in
                    tourOverlay(in: geo)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { onboardingState.currentPhase == .getStarted },
                set: { if !$0 { /* dismiss handled by callbacks */ } }
            )) {
                OnboardingGetStartedView(
                    onAddVehicle: {
                        AnalyticsService.shared.capture(.onboardingManualEntry)
                        completeOnboardingAndPresentAddVehicle()
                    },
                    onUseICloudVehicles: {
                        AnalyticsService.shared.capture(.onboardingICloudSync)
                        clearSampleData()
                        onboardingState.complete()
                    },
                    onSkip: {
                        AnalyticsService.shared.capture(.onboardingSkippedGetStarted)
                        clearSampleData()
                        onboardingState.complete()
                    }
                )
            }
    }

    /// The tour's spotlight card, over the whole shell — tab bar and
    /// navigation bar included.
    @ViewBuilder
    private func tourOverlay(in geo: GeometryProxy) -> some View {
        if onboardingState.currentPhase.isTour {
            OnboardingTourOverlay(
                onboardingState: onboardingState,
                spotlight: tourSpotlight(in: geo),
                geometry: geo,
                // Analytics fire from the Skip button itself.
                onSkipTour: skipTour
            )
            .transition(.opacity)
        }
    }

    /// The current step's target, converted from window space (where the
    /// targets report it) into the overlay's space.
    private func tourSpotlight(in geo: GeometryProxy) -> CGRect? {
        guard let step = onboardingState.currentPhase.tourStep,
              let target = TourStep.at(step)?.target,
              let frame = tourSpotlights.frames[target] else { return nil }
        let origin = geo.frame(in: .global).origin
        return frame.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    private func skipTour() {
        clearSampleData()
        onboardingState.complete()
        appState.selectedTab = .home
    }

    // MARK: - Notification Routing

    func notificationHandlers(_ content: some View) -> some View {
        content
            // `initial: true` picks up a route stored while the app was still
            // launching from the notification tap.
            .onChange(of: NotificationService.shared.pendingRoute, initial: true) { _, route in
                guard let route else { return }
                NotificationService.shared.pendingRoute = nil
                appState.apply(route, vehicles: vehicles)
            }
            // A widget row tap runs `OpenServiceIntent` in this process, which
            // can land after activation already ran `enterForeground()`.
            .onReceive(NotificationCenter.default.publisher(for: PendingWidgetRoute.queuedNotification)) { _ in
                consumePendingWidgetRoute()
            }
            // Clear AppState's retained SwiftData references before the App swaps
            // the ModelContainer on this notification (onboarding → CloudKit).
            // Without this, selectedVehicle et al. would point into the outgoing
            // container's dead context after the swap.
            .onReceive(NotificationCenter.default.publisher(for: .enableCloudSyncAfterOnboarding)) { _ in
                // Only tear down the retained references when a swap will actually
                // happen. checkpointApp guards the real container swap on this same
                // preference; finishing onboarding with sync OFF performs no swap,
                // so wiping the selection here would strand the user with no
                // vehicle. Must stay in lockstep with checkpointApp's guard.
                guard SyncSettings.shared.iCloudSyncEnabled else { return }
                appState.prepareForContainerSwap()
            }
    }

    // MARK: - Onboarding Helpers

    /// Shared exit path for the "get started" onboarding surface when the user
    /// chooses to add a vehicle (VIN lookup or manual entry): clear the sample
    /// tour data, mark onboarding complete, and present the Add Vehicle sheet a
    /// beat later so the onboarding cover has finished dismissing first. (The
    /// cover is not a router sheet, so the router's queue cannot wait on it.)
    private func completeOnboardingAndPresentAddVehicle() {
        clearSampleData()
        onboardingState.complete()
        delayedTask?.cancel()
        delayedTask = Task {
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled else { return }
            appState.present(.addVehicle)
        }
    }
}
