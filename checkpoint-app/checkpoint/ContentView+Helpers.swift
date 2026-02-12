//
//  ContentView+Helpers.swift
//  checkpoint
//
//  Helper methods extracted from ContentView
//

import SwiftUI
import SwiftData
import WidgetKit

extension ContentView {
    // MARK: - Vehicle Selection Persistence

    /// Restore the previously selected vehicle from UserDefaults
    func restoreSelectedVehicle() {
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
    func persistSelectedVehicle(_ vehicle: Vehicle?) {
        let vehicleIDString = vehicle?.id.uuidString

        // Save to standard UserDefaults (for app persistence)
        if let idString = vehicleIDString {
            UserDefaults.standard.set(idString, forKey: Self.selectedVehicleIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedVehicleIDKey)
        }

        // Save to shared App Group UserDefaults (for widget access)
        if let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) {
            if let idString = vehicleIDString {
                sharedDefaults.set(idString, forKey: Self.selectedVehicleIDKey)
            } else {
                sharedDefaults.removeObject(forKey: Self.selectedVehicleIDKey)
            }
        }
        // Note: Widget reload happens in updateWidgetData() via WidgetDataService
    }

    // MARK: - Recalls

    /// Fetch recalls for all existing vehicles (called once on app launch)
    func fetchRecallsForAllVehicles() {
        for vehicle in vehicles {
            Task {
                await appState.fetchRecalls(for: vehicle)
            }
        }
    }

    // MARK: - App Icon

    func updateAppIcon() {
        AppIconService.shared.updateIcon(for: currentVehicle, services: services)
    }

    // MARK: - Widget Data

    func updateWidgetData() {
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
    func handlePendingSiriMileageUpdate() {
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

    // MARK: - Widget Completions

    /// Process pending service completions from the widget "Done" button
    func processPendingWidgetCompletions() {
        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)
    }

    // MARK: - Mileage Update

    func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
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
        appState.recordCompletedAction()
    }

    // MARK: - Periodic Notifications

    func schedulePeriodicNotifications() {
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

    func seedSampleDataIfNeeded() {
        guard vehicles.isEmpty else { return }
        seedSampleVehicles()
    }

    /// Seed sample data specifically for the onboarding tour
    func seedSampleDataForTour() {
        guard vehicles.isEmpty else { return }
        seedSampleVehicles()
    }

    func seedSampleVehicles() {
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
        appState.selectedVehicle = camry

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

        // Track sample vehicle IDs for cleanup
        onboardingState.sampleVehicleIDs = [camry.id, mx5.id]
    }

    /// Clear all sample data created during onboarding tour
    func clearSampleData() {
        let idsToRemove = onboardingState.sampleVehicleIDs
        guard !idsToRemove.isEmpty else { return }

        for vehicle in vehicles where idsToRemove.contains(vehicle.id) {
            modelContext.delete(vehicle)
        }
        onboardingState.sampleVehicleIDs = []
        appState.selectedVehicle = nil
    }
}
