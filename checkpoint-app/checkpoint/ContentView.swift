//
//  ContentView.swift
//  checkpoint
//
//  Root TabView container with persistent vehicle header and FAB
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query var vehicles: [Vehicle]
    @Query var services: [Service]
    @Query var serviceLogs: [ServiceLog]

    @State var appState = AppState()
    @State var onboardingState = OnboardingState()
    @State var showMileageUpdate = false
    @State var showSettings = false
    @State var siriPrefilledMileage: Int?

    // MARK: - Vehicle Selection Persistence

    static let selectedVehicleIDKey = "appSelectedVehicleID"

    var currentVehicle: Vehicle? {
        appState.selectedVehicle ?? vehicles.first
    }

    var showOnboardingIntro: Bool {
        onboardingState.currentPhase == .intro
    }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Persistent vehicle header
                VehicleHeader(
                    vehicle: currentVehicle,
                    onTap: {
                        appState.showVehiclePicker = true
                    },
                    onMileageTap: {
                        showMileageUpdate = true
                    },
                    onSettingsTap: {
                        showSettings = true
                    }
                )
                .padding(.top, Spacing.sm)
                .revealAnimation(delay: 0.1)

                // Tab content - simple view switch with swipe navigation
                Group {
                    switch appState.selectedTab {
                    case .home:
                        HomeTab(appState: appState)
                    case .services:
                        ServicesTab(appState: appState)
                    case .costs:
                        CostsTab(appState: appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontalSwipe = value.translation.width
                            let verticalSwipe = abs(value.translation.height)

                            // Only trigger if horizontal movement dominates
                            guard abs(horizontalSwipe) > verticalSwipe else { return }

                            // Soft haptic feedback for tab switch
                            HapticService.shared.tabChanged()

                            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                                if horizontalSwipe > 0 {
                                    // Swipe right -> go to previous tab
                                    appState.selectedTab = appState.selectedTab.previous
                                } else {
                                    // Swipe left -> go to next tab
                                    appState.selectedTab = appState.selectedTab.next
                                }
                            }
                        }
                )
                // Reserve space at bottom for floating tab bar
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 72)
                }
            }

            // Bottom gradient fade - subtle fade so content peeks through glass tab bar
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [
                        Theme.backgroundPrimary.opacity(0),
                        Theme.backgroundPrimary.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                Theme.backgroundPrimary.opacity(0.7)
                    .frame(height: 34)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        // Tab bar overlay - floats over content with glass effect
        .overlay(alignment: .bottom) {
            BrutalistTabBar(
                selectedTab: $appState.selectedTab,
                onLogTapped: currentVehicle != nil ? {
                    appState.addServiceMode = .record
                    appState.showAddService = true
                } : nil,
                onScheduleTapped: currentVehicle != nil ? {
                    appState.addServiceMode = .remind
                    appState.showAddService = true
                } : nil
            )
            .revealAnimation(delay: 0.3)
        }
        .overlay(alignment: .bottom) {
            if let toast = ToastService.shared.currentToast {
                ToastView(toast: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 72 + Spacing.lg)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .animation(.easeOut(duration: Theme.animationMedium), value: ToastService.shared.currentToast?.id)
            }
        }
        .onAppear {
            // Restore persisted vehicle selection
            restoreSelectedVehicle()
            // Only seed sample data for returning users (onboarding completed)
            // New users get sample data seeded when tour starts
            if OnboardingState.hasCompletedOnboarding {
                seedSampleDataIfNeeded()
            }
            // Update app icon based on service status
            updateAppIcon()
            // Update widget data
            updateWidgetData()
            // Schedule mileage reminders and yearly roundups for all vehicles
            schedulePeriodicNotifications()
            // Fetch recalls for all existing vehicles
            fetchRecallsForAllVehicles()
            // Analytics: session start
            AnalyticsService.shared.capture(.appSessionStart(
                vehicleCount: vehicles.count,
                serviceCount: services.count
            ))
            // Track onboarding start for new users
            if !OnboardingState.hasCompletedOnboarding {
                AnalyticsService.shared.capture(.onboardingStarted)
            }
        }
        .onChange(of: onboardingState.currentPhase) { _, newPhase in
            if case .tourTransition(let toStep) = newPhase {
                // Switch tab behind the transition card
                switch toStep {
                case 2: appState.selectedTab = .services
                case 3: appState.selectedTab = .costs
                default: break
                }
            } else if newPhase == .completed {
                AnalyticsService.shared.capture(.onboardingCompleted)
                // Enable CloudKit sync now that onboarding is done
                NotificationCenter.default.post(name: .enableCloudSyncAfterOnboarding, object: nil)
                // Request notification permission after onboarding completes
                Task {
                    let granted = await NotificationService.shared.requestAuthorization()
                    if granted {
                        AnalyticsService.shared.capture(.notificationPermissionGranted)
                    } else {
                        AnalyticsService.shared.capture(.notificationPermissionDenied)
                    }
                }
            }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            if let tab = AnalyticsEvent.TabName(rawValue: newTab.rawValue) {
                AnalyticsService.shared.capture(.tabSwitched(tab: tab))
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Update app icon when entering foreground
                updateAppIcon()
                // Update widget data
                updateWidgetData()
                // Check for pending Siri mileage update
                handlePendingSiriMileageUpdate()
                // Process pending widget service completions
                processPendingWidgetCompletions()
                // Analytics
                AnalyticsService.shared.capture(.appOpened)
            } else if newPhase == .background {
                // Update app icon when going to background
                updateAppIcon()
                // Update widget data
                updateWidgetData()
                // Analytics
                AnalyticsService.shared.capture(.appBackgrounded)
                AnalyticsService.shared.flush()
            }
        }
        .onChange(of: appState.selectedVehicle) { _, newVehicle in
            updateAppIcon()
            // Persist selected vehicle ID first so widget reads correct ID
            persistSelectedVehicle(newVehicle)
            updateWidgetData()
            // Analytics
            AnalyticsService.shared.capture(.vehicleSwitched)
        }
        .onChange(of: vehicles) { oldVehicles, newVehicles in
            // Auto-select first vehicle when none is selected (e.g. iCloud sync after reinstall)
            if appState.selectedVehicle == nil, let first = newVehicles.first {
                appState.selectedVehicle = first
            }
            // Update selection if current vehicle was deleted
            if let selected = appState.selectedVehicle,
               !newVehicles.contains(where: { $0.id == selected.id }) {
                // Clean up widget data for deleted vehicle
                WidgetDataService.shared.removeWidgetData(for: selected.id.uuidString)
                // Select the previous vehicle in the old list, or fall back to first remaining
                if let oldIndex = oldVehicles.firstIndex(where: { $0.id == selected.id }),
                   oldIndex > 0,
                   let fallback = newVehicles.first(where: { $0.id == oldVehicles[oldIndex - 1].id }) {
                    appState.selectedVehicle = fallback
                } else {
                    appState.selectedVehicle = newVehicles.first
                }
            }
            // Update vehicle list when vehicles are added or removed
            if oldVehicles.count != newVehicles.count {
                WidgetDataService.shared.updateVehicleList(newVehicles)
            }
            // Fetch recalls for newly added vehicles
            if newVehicles.count > oldVehicles.count {
                let oldIDs = Set(oldVehicles.map(\.id))
                for vehicle in newVehicles where !oldIDs.contains(vehicle.id) {
                    Task {
                        await appState.fetchRecalls(for: vehicle)
                    }
                }
            }
        }
        // Centralized sheets
        .sheet(isPresented: $appState.showVehiclePicker) {
            VehiclePickerSheet(
                selectedVehicle: $appState.selectedVehicle,
                onAddVehicle: { appState.requestAddVehicle(vehicleCount: vehicles.count) }
            )
        }
        .sheet(isPresented: $appState.showAddVehicle, onDismiss: {
            appState.onboardingMarbeteMonth = nil
            appState.onboardingMarbeteYear = nil
        }) {
            AddVehicleFlowView()
                .environment(appState)
        }
        .sheet(isPresented: $appState.showAddService, onDismiss: {
            appState.seasonalPrefill = nil
            appState.addServiceMode = nil
        }) {
            if let vehicle = currentVehicle {
                AddServiceView(
                    vehicle: vehicle,
                    seasonalPrefill: appState.seasonalPrefill,
                    initialMode: appState.addServiceMode ?? .record
                )
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
        .sheet(item: $appState.selectedServiceLog) { log in
            NavigationStack {
                ServiceLogDetailView(log: log)
            }
        }
        .sheet(isPresented: $appState.showEditVehicle) {
            if let vehicle = currentVehicle {
                EditVehicleView(vehicle: vehicle)
            }
        }
        .sheet(isPresented: $showMileageUpdate, onDismiss: {
            // Clear Siri prefilled mileage after sheet is dismissed
            siriPrefilledMileage = nil
        }) {
            if let vehicle = currentVehicle {
                MileageUpdateSheet(
                    vehicle: vehicle,
                    prefilledMileage: siriPrefilledMileage,
                    onSave: { newMileage in
                        AnalyticsService.shared.capture(.mileageUpdated(source: .manual))
                        updateMileage(newMileage, for: vehicle)
                        ToastService.shared.show(L10n.toastMileageUpdated, icon: "gauge.medium", style: .success)
                    }
                )
                .trackScreen(.mileageUpdate)
                .presentationDetents([.height(450)])
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onboardingState: onboardingState)
                .environment(appState)
                .onAppear {
                    AnalyticsService.shared.capture(.settingsOpened)
                }
        }
        .sheet(isPresented: $appState.showProPaywall) {
            ProPaywallSheet()
        }
        .sheet(isPresented: $appState.showTipModal) {
            TipModalView()
                .environment(appState)
        }
        .sheet(item: $appState.unlockedTheme) { theme in
            ThemeRevealView(theme: theme)
        }
        // MARK: - Onboarding
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
        .overlay {
            if onboardingState.currentPhase.isTour {
                if case .tourTransition(let toStep) = onboardingState.currentPhase {
                    OnboardingTourTransitionCard(
                        targetStep: toStep,
                        onSkipTour: {
                            let step = onboardingState.currentPhase.tourStep ?? 0
                            AnalyticsService.shared.capture(.onboardingTourSkipped(atStep: step))
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
                        onSkipTour: {
                            let step = onboardingState.currentPhase.tourStep ?? 0
                            AnalyticsService.shared.capture(.onboardingTourSkipped(atStep: step))
                            clearSampleData()
                            onboardingState.complete()
                            appState.selectedTab = .home
                        },
                        onTourComplete: {
                            AnalyticsService.shared.capture(.onboardingTourCompleted)
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
                onVINLookupComplete: { _, _ in
                    AnalyticsService.shared.capture(.onboardingVINLookupUsed)
                    clearSampleData()
                    onboardingState.complete()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        appState.showAddVehicle = true
                    }
                },
                onManualEntry: {
                    AnalyticsService.shared.capture(.onboardingManualEntry)
                    clearSampleData()
                    onboardingState.complete()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        appState.showAddVehicle = true
                    }
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
                marbeteMonth: $appState.onboardingMarbeteMonth,
                marbeteYear: $appState.onboardingMarbeteYear
            )
        }
        // Handle mileage update notification navigation
        .onReceive(NotificationCenter.default.publisher(for: .navigateToMileageUpdateFromNotification)) { notification in
            if let vehicleIDString = notification.userInfo?["vehicleID"] as? String,
               let vehicleID = UUID(uuidString: vehicleIDString) {
                // Select the vehicle if it matches, otherwise find it
                if currentVehicle?.id != vehicleID {
                    if let vehicle = vehicles.first(where: { $0.id == vehicleID }) {
                        appState.selectedVehicle = vehicle
                    }
                }
                // Navigate to home and show mileage update
                appState.selectedTab = .home
                showMileageUpdate = true
            }
        }
        // Handle snooze mileage reminder
        .onReceive(NotificationCenter.default.publisher(for: .mileageReminderSnoozedFromNotification)) { notification in
            if let vehicleIDString = notification.userInfo?["vehicleID"] as? String,
               let vehicleID = UUID(uuidString: vehicleIDString),
               let vehicle = vehicles.first(where: { $0.id == vehicleID }) {
                NotificationService.shared.snoozeMileageReminder(for: vehicle)
            }
        }
        // Handle yearly roundup navigation to costs
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCostsFromNotification)) { notification in
            if let vehicleIDString = notification.userInfo?["vehicleID"] as? String,
               let vehicleID = UUID(uuidString: vehicleIDString) {
                // Select the vehicle if it matches, otherwise find it
                if currentVehicle?.id != vehicleID {
                    if let vehicle = vehicles.first(where: { $0.id == vehicleID }) {
                        appState.selectedVehicle = vehicle
                    }
                }
                // Navigate to costs tab
                appState.selectedTab = .costs
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
