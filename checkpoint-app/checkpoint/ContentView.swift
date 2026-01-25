//
//  ContentView.swift
//  checkpoint
//
//  Root TabView container with persistent vehicle header and FAB
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var vehicles: [Vehicle]
    @Query private var services: [Service]

    @State private var appState = AppState()
    @State private var showMileageUpdate = false

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
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active || newPhase == .background {
                // Update app icon when entering foreground or going to background
                updateAppIcon()
            }
        }
        .onChange(of: appState.selectedVehicle) { _, _ in
            updateAppIcon()
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
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: currentVehicle, services: services)
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
