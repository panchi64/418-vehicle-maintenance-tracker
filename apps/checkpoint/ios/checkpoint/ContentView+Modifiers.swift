//
//  ContentView+Modifiers.swift
//  checkpoint
//
//  Grouped modifier chains extracted from ContentView's body: the centralized
//  sheet presentations, the onboarding full-screen surfaces, and the
//  notification-routing handlers. Each takes the content it decorates and
//  returns it with the group applied, keeping the root body scannable.
//

import SwiftUI
import SwiftData

extension ContentView {

    // MARK: - Centralized Sheets

    func centralizedSheets(_ content: some View) -> some View {
        content
            .sheet(isPresented: $appState.showVehiclePicker, onDismiss: {
                guard addVehicleAfterPickerDismiss else { return }
                addVehicleAfterPickerDismiss = false
                appState.requestAddVehicle(vehicleCount: vehicles.count)
            }) {
                VehiclePickerSheet(
                    selectedVehicle: $appState.selectedVehicle,
                    onAddVehicle: { addVehicleAfterPickerDismiss = true }
                )
            }
            .sheet(isPresented: $appState.showAddVehicle, onDismiss: {
                appState.onboarding.marbeteMonth = nil
                appState.onboarding.marbeteYear = nil
                appState.onboarding.vinLookupResult = nil
            }) {
                AddVehicleFlowView()
                    .environment(appState)
            }
            .sheet(isPresented: $appState.showAddService, onDismiss: {
                appState.seasonalPrefill = nil
                appState.postRecordPrefill = nil
            }) {
                if let vehicle = currentVehicle {
                    AddServiceView(
                        vehicle: vehicle,
                        seasonalPrefill: appState.seasonalPrefill,
                        postRecordPrefill: appState.postRecordPrefill
                    )
                    .environment(appState)
                }
            }
            .sheet(item: $appState.selectedService) { service in
                if let vehicle = currentVehicle {
                    NavigationStack {
                        ServiceDetailView(service: service, vehicle: vehicle)
                    }
                    .environment(appState)
                }
            }
            // The root sheet dismisses onto the root, where the toast renders,
            // so deleting from here is immediate with Undo — no confirmation.
            .sheet(item: $appState.selectedServiceLog, onDismiss: {
                guard let log = logPendingDeletion else { return }
                logPendingDeletion = nil
                ServiceLogDeleteAction.perform(log, offerUndo: true)
            }) { log in
                NavigationStack {
                    ServiceLogDetailView(log: log, onDelete: { logPendingDeletion = $0 })
                }
                .environment(appState)
            }
            .sheet(item: $appState.selectedServiceVisit) { visit in
                NavigationStack {
                    ServiceVisitDetailView(visit: visit)
                }
                .environment(appState)
            }
            .sheet(isPresented: $appState.showEditVehicle) {
                if let vehicle = currentVehicle {
                    EditVehicleView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $appState.showDocuments) {
                if let vehicle = currentVehicle {
                    DocumentsView(vehicle: vehicle)
                        .environment(appState)
                } else {
                    // currentVehicle can resolve to nil if the selected vehicle is
                    // deleted (locally or by an arriving iCloud delete) while the
                    // sheet is in flight. Render a dismissible fallback rather
                    // than an empty sheet the user can only swipe away.
                    NavigationStack {
                        EmptyStateView(
                            icon: "car.side.fill",
                            title: "No Vehicle",
                            message: "Select a vehicle to view its documents.",
                            action: { appState.showDocuments = false },
                            actionLabel: "Close"
                        )
                    }
                }
            }
            .sheet(item: $appState.selectedDocument) { document in
                DocumentDetailView(document: document)
                    .environment(appState)
            }
            .sheet(isPresented: $appState.showMileageUpdate, onDismiss: {
                // Clear Siri prefilled mileage after sheet is dismissed
                appState.siriPrefilledMileage = nil
            }) {
                if let vehicle = currentVehicle {
                    MileageUpdateSheet(
                        vehicle: vehicle,
                        prefilledMileage: appState.siriPrefilledMileage,
                        onSave: { newMileage in
                            AnalyticsService.shared.capture(.mileageUpdated(source: .manual))
                            updateMileage(newMileage, for: vehicle)
                            ToastService.shared.show(L10n.toastMileageUpdated, icon: "gauge.medium", style: .success)
                        }
                    )
                    .trackScreen(.mileageUpdate)
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $appState.showSettings) {
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
                .environment(appState)
                .onAppear {
                    AnalyticsService.shared.capture(.settingsOpened)
                }
            }
            .sheet(isPresented: $appState.showProPaywall) {
                ProPaywallSheet()
            }
            .sheet(isPresented: $appState.showTipModal) {
                TipModalView(isPrompt: true)
                    .environment(appState)
            }
            // AppState only queues the tip prompt (pure state); the delayed
            // presentation effect belongs to the view layer, so it lives here.
            .onChange(of: appState.tipPromptQueued) { _, queued in
                guard queued else { return }
                presentQueuedTipPrompt()
            }
            .sheet(item: $appState.unlockedTheme) { theme in
                ThemeRevealView(theme: theme)
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
                    onboardingState: onboardingState,
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
            .overlayPreferenceValue(SpotlightAnchorPreferenceKey.self) { anchors in
                GeometryReader { geo in
                    if onboardingState.currentPhase.isTour {
                        if case .tourTransition(let toStep) = onboardingState.currentPhase {
                            OnboardingTourTransitionCard(
                                targetStep: toStep,
                                // Analytics for the skip-intent fire from the
                                // button itself; this closure handles state only.
                                onSkipTour: {
                                    clearSampleData()
                                    onboardingState.complete()
                                    appState.selectedTab = .home
                                },
                                onContinue: {
                                    onboardingState.resolveTransition()
                                }
                            )
                            .transition(.opacity)
                        } else {
                            OnboardingTourOverlay(
                                appState: appState,
                                onboardingState: onboardingState,
                                anchors: anchors,
                                geometry: geo,
                                // Analytics fire from the Skip button itself.
                                onSkipTour: {
                                    clearSampleData()
                                    onboardingState.complete()
                                    appState.selectedTab = .home
                                }
                            )
                            .transition(.opacity)
                        }
                    } else if onboardingState.currentPhase.isTourRecap {
                        OnboardingTourRecapCard(
                            onBack: {
                                onboardingState.goBackTour()
                            },
                            // onboardingTourCompleted analytics already fired
                            // on entering .tourRecap via the onChange handler.
                            onDone: {
                                appState.selectedTab = .home
                                onboardingState.finishTour()
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { onboardingState.currentPhase == .getStarted },
                set: { if !$0 { /* dismiss handled by callbacks */ } }
            )) {
                OnboardingGetStartedView(
                    onVINLookupComplete: { result, vin in
                        AnalyticsService.shared.capture(.onboardingVINLookupUsed)
                        // Store VIN lookup result for AddVehicleFlowView to consume
                        appState.onboarding.vinLookupResult = OnboardingPrefillState.VINLookupPassthrough(
                            make: result.make,
                            model: result.model,
                            year: result.modelYear,
                            vin: vin
                        )
                        completeOnboardingAndPresentAddVehicle()
                    },
                    onManualEntry: {
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
                    },
                    marbeteMonth: $appState.onboarding.marbeteMonth,
                    marbeteYear: $appState.onboarding.marbeteYear
                )
            }
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
            .sheet(item: $appState.markDoneRequest) { request in
                MarkServiceVisitDoneSheet(origin: markDoneOrigin(for: request))
                    .environment(appState)
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
    /// beat later so the onboarding cover has finished dismissing first.
    private func completeOnboardingAndPresentAddVehicle() {
        clearSampleData()
        onboardingState.complete()
        delayedTask?.cancel()
        delayedTask = Task {
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled else { return }
            appState.showAddVehicle = true
        }
    }
}
