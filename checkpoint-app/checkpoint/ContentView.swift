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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var vehicles: [Vehicle]
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    @State private var appState = AppState()
    @State private var showMileageUpdate = false
    @State private var showSettings = false
    @State private var siriPrefilledMileage: Int?

    // MARK: - Vehicle Selection Persistence

    private static let selectedVehicleIDKey = "appSelectedVehicleID"
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"

    private var currentVehicle: Vehicle? {
        appState.selectedVehicle ?? vehicles.first
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
                onAddTapped: currentVehicle != nil ? { appState.showAddService = true } : nil
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
            // Seed sample data if needed
            seedSampleDataIfNeeded()
            // Update app icon based on service status
            updateAppIcon()
            // Update widget data
            updateWidgetData()
            // Schedule mileage reminders and yearly roundups for all vehicles
            schedulePeriodicNotifications()
            // Analytics: session start
            AnalyticsService.shared.capture(.appSessionStart(
                vehicleCount: vehicles.count,
                serviceCount: services.count
            ))
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
        }
        // Centralized sheets
        .sheet(isPresented: $appState.showVehiclePicker) {
            VehiclePickerSheet(
                selectedVehicle: $appState.selectedVehicle,
                onAddVehicle: { appState.showAddVehicle = true }
            )
        }
        .sheet(isPresented: $appState.showAddVehicle) {
            AddVehicleFlowView()
                .environment(appState)
        }
        .sheet(isPresented: $appState.showAddService, onDismiss: {
            appState.seasonalPrefill = nil
        }) {
            if let vehicle = currentVehicle {
                AddServiceView(vehicle: vehicle, seasonalPrefill: appState.seasonalPrefill)
            }
        }
        .sheet(item: $appState.selectedService) { service in
            if let vehicle = currentVehicle {
                NavigationStack {
                    ServiceDetailView(service: service, vehicle: vehicle)
                }
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
                    }
                )
                .trackScreen(.mileageUpdate)
                .presentationDetents([.height(450)])
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .onAppear {
                    AnalyticsService.shared.capture(.settingsOpened)
                }
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

    // MARK: - Vehicle Selection Persistence

    /// Restore the previously selected vehicle from UserDefaults
    private func restoreSelectedVehicle() {
        // Try to load saved vehicle ID from standard UserDefaults
        guard let savedIDString = UserDefaults.standard.string(forKey: Self.selectedVehicleIDKey),
              let savedID = UUID(uuidString: savedIDString) else {
            // No saved selection, fall back to first vehicle
            if appState.selectedVehicle == nil {
                appState.selectedVehicle = vehicles.first
            }
            return
        }

        // Find the matching vehicle
        if let matchingVehicle = vehicles.first(where: { $0.id == savedID }) {
            appState.selectedVehicle = matchingVehicle
        } else {
            // Saved vehicle no longer exists, fall back to first vehicle
            appState.selectedVehicle = vehicles.first
        }
    }

    /// Persist the selected vehicle ID to both standard and App Group UserDefaults
    private func persistSelectedVehicle(_ vehicle: Vehicle?) {
        let vehicleIDString = vehicle?.id.uuidString

        // Save to standard UserDefaults (for app persistence)
        if let idString = vehicleIDString {
            UserDefaults.standard.set(idString, forKey: Self.selectedVehicleIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedVehicleIDKey)
        }

        // Save to shared App Group UserDefaults (for widget access)
        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupID) {
            if let idString = vehicleIDString {
                sharedDefaults.set(idString, forKey: Self.selectedVehicleIDKey)
            } else {
                sharedDefaults.removeObject(forKey: Self.selectedVehicleIDKey)
            }
        }
        // Note: Widget reload happens in updateWidgetData() via WidgetDataService
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: currentVehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        // Update vehicle list for widget configuration picker
        WidgetDataService.shared.updateVehicleList(vehicles)

        if let vehicle = currentVehicle {
            WidgetDataService.shared.updateWidget(for: vehicle)
        } else {
            WidgetDataService.shared.clearWidgetData()
        }
    }

    // MARK: - Siri Integration

    /// Handle pending mileage update from Siri intent
    private func handlePendingSiriMileageUpdate() {
        let pending = PendingMileageUpdate.shared
        guard pending.hasPendingUpdate,
              let vehicleIDString = pending.vehicleID,
              let mileage = pending.mileage else {
            return
        }

        // Clear the pending update immediately to avoid re-processing
        pending.clear()

        // Find the vehicle by ID
        guard let vehicleID = UUID(uuidString: vehicleIDString),
              let vehicle = vehicles.first(where: { $0.id == vehicleID }) else {
            return
        }

        // Select the vehicle if it's not already selected
        if currentVehicle?.id != vehicleID {
            appState.selectedVehicle = vehicle
        }

        // Navigate to home and show mileage update with prefilled value
        appState.selectedTab = .home
        siriPrefilledMileage = mileage
        showMileageUpdate = true
    }

    // MARK: - Mileage Update

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

        // Update app icon based on new mileage affecting service status
        updateAppIcon()
        // Update widget data
        updateWidgetData()
        // Reschedule mileage reminder for 14 days from now
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)
    }

    // MARK: - Periodic Notifications

    private func schedulePeriodicNotifications() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)
        let previousYear = currentYear - 1

        for vehicle in vehicles {
            // Schedule mileage reminder if needed
            if let lastUpdate = vehicle.mileageUpdatedAt {
                // Schedule based on last update date
                NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: lastUpdate)
            } else {
                // Never updated - schedule from now
                NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)
            }

            // Calculate previous year's total cost for yearly roundup
            let vehicleLogs = serviceLogs.filter { $0.vehicle?.id == vehicle.id }
            let previousYearLogs = vehicleLogs.filter {
                calendar.component(.year, from: $0.performedDate) == previousYear
            }
            let previousYearCost = previousYearLogs.compactMap { $0.cost }.reduce(0, +)

            // Schedule yearly roundup if there's data
            NotificationService.shared.scheduleYearlyRoundup(
                for: vehicle,
                previousYearCost: previousYearCost,
                previousYear: previousYear
            )
        }
    }

    // MARK: - Sample Data

    private func seedSampleDataIfNeeded() {
        guard vehicles.isEmpty else { return }

        // --- Vehicle 1: Daily Driver (Camry) ---
        let camry = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500,
            vin: "4T1BF1FK5CU123456",
            tireSize: "215/55R17",
            oilType: "0W-20 Synthetic",
            notes: "Purchased certified pre-owned. Runs great!",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2026
        )
        modelContext.insert(camry)

        for service in Service.sampleServices(for: camry) {
            modelContext.insert(service)
        }
        for log in ServiceLog.sampleLogs(for: camry) {
            modelContext.insert(log)
        }
        for snapshot in MileageSnapshot.sampleSnapshots(for: camry) {
            modelContext.insert(snapshot)
        }

        // --- Vehicle 2: Weekend Car (MX-5) ---
        let mx5 = Vehicle(
            name: "Weekend Car",
            make: "Mazda",
            model: "MX-5",
            year: 2020,
            currentMileage: 18200,
            vin: "JM1NDAD75L0123789",
            tireSize: "205/45R17",
            oilType: "0W-20 Synthetic",
            notes: "Garage kept. Summer tires only.",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)
        )
        modelContext.insert(mx5)

        for service in Service.sampleServicesCompact(for: mx5) {
            modelContext.insert(service)
        }
        for log in ServiceLog.sampleLogsCompact(for: mx5) {
            modelContext.insert(log)
        }

        appState.selectedVehicle = camry
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
