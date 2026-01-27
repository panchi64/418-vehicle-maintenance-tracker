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
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontalSwipe = value.translation.width
                            let verticalSwipe = abs(value.translation.height)

                            // Only trigger if horizontal movement dominates
                            guard abs(horizontalSwipe) > verticalSwipe else { return }

                            if horizontalSwipe > 0 {
                                // Swipe right -> go to previous tab
                                appState.selectedTab = appState.selectedTab.previous
                            } else {
                                // Swipe left -> go to next tab
                                appState.selectedTab = appState.selectedTab.next
                            }
                        }
                )

                // Custom tab bar - pinned to bottom
                BrutalistTabBar(selectedTab: $appState.selectedTab)
            }

            // Floating action button overlay
            if currentVehicle != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            appState.showAddService = true
                        }
                        .revealAnimation(delay: 0.5)
                        .padding(.trailing, Spacing.screenHorizontal)
                        .padding(.bottom, 72 + Spacing.md) // Above tab bar
                    }
                }
            }
        }
        .onAppear {
            // Sync selected vehicle on appear
            if appState.selectedVehicle == nil {
                appState.selectedVehicle = vehicles.first
            }
            // Seed sample data if needed
            seedSampleDataIfNeeded()
            // Update app icon based on service status
            updateAppIcon()
            // Update widget data
            updateWidgetData()
            // Schedule mileage reminders and yearly roundups for all vehicles
            schedulePeriodicNotifications()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active || newPhase == .background {
                // Update app icon when entering foreground or going to background
                updateAppIcon()
                // Update widget data
                updateWidgetData()
            }
        }
        .onChange(of: appState.selectedVehicle) { _, _ in
            updateAppIcon()
            updateWidgetData()
        }
        .onChange(of: vehicles) { _, newVehicles in
            // Update selection if current vehicle was deleted
            if let selected = appState.selectedVehicle,
               !newVehicles.contains(where: { $0.id == selected.id }) {
                appState.selectedVehicle = newVehicles.first
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
            AddVehicleView()
        }
        .sheet(isPresented: $appState.showAddService) {
            if let vehicle = currentVehicle {
                AddServiceView(vehicle: vehicle)
            }
        }
        .sheet(item: $appState.selectedService) { service in
            if let vehicle = currentVehicle {
                NavigationStack {
                    ServiceDetailView(service: service, vehicle: vehicle)
                }
            }
        }
        .sheet(isPresented: $appState.showEditVehicle) {
            if let vehicle = currentVehicle {
                EditVehicleView(vehicle: vehicle)
            }
        }
        .sheet(isPresented: $showMileageUpdate) {
            if let vehicle = currentVehicle {
                MileageUpdateSheet(
                    currentMileage: vehicle.currentMileage,
                    onSave: { newMileage in
                        updateMileage(newMileage, for: vehicle)
                    }
                )
                .presentationDetents([.height(280)])
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: currentVehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        if let vehicle = currentVehicle {
            WidgetDataService.shared.updateWidget(for: vehicle)
        } else {
            WidgetDataService.shared.clearWidgetData()
        }
    }

    // MARK: - Mileage Update

    private func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = .now

        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots
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

        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500,
            vin: "4T1BF1FK5CU123456",
            tireSize: "215/55R17",
            oilType: "0W-20 Synthetic",
            notes: "Purchased certified pre-owned. Runs great!",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
        )
        modelContext.insert(vehicle)

        // Add sample services
        let sampleServices = Service.sampleServices(for: vehicle)
        for service in sampleServices {
            modelContext.insert(service)
        }

        // Add sample service logs for the Costs tab
        let sampleLogs = ServiceLog.sampleLogs(for: vehicle)
        for log in sampleLogs {
            modelContext.insert(log)
        }

        appState.selectedVehicle = vehicle
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
