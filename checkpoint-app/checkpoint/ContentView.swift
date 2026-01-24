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
    @Query private var vehicles: [Vehicle]

    @State private var appState = AppState()

    private var currentVehicle: Vehicle? {
        appState.selectedVehicle ?? vehicles.first
    }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Persistent vehicle header
                VehicleHeader(vehicle: currentVehicle) {
                    appState.showVehiclePicker = true
                }
                .padding(.top, Spacing.sm)
                .revealAnimation(delay: 0.1)

                // Tab content - simple view switch
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
