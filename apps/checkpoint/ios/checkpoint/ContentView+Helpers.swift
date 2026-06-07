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
        if let sharedDefaults = AppGroupConstants.iPhoneWidgetDefaults() {
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

        // Publish odometers to the cross-product App Group for Biombo.
        VehicleSharingService.publish(vehicles)
    }

    // MARK: - Companion App (Biombo) Odometer Sync

    /// Apply odometer readings queued by the Biombo companion app, then refresh
    /// derived data so widgets and the shared bridge reflect the new mileage.
    func applyPendingOdometerUpdates() {
        if VehicleSharingService.applyPendingUpdates(in: modelContext) {
            updateAppIcon()
            updateWidgetData()
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
        vehicle.recordMileage(newMileage, source: .manual, in: modelContext)

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
            let previousYearCost = previousYearLogs.honestTotalCost()

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

    /// Seed sample data specifically for the onboarding tour.
    /// If iCloud has already synced real vehicles, use those instead of creating dummy data.
    func seedSampleDataForTour() {
        if vehicles.isEmpty {
            seedSampleVehicles()
        } else {
            // iCloud data arrived during onboarding intro — use real data for tour
            appState.selectedVehicle = vehicles.first
        }
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

        // --- Vehicle 2: Weekend Car (NSX Type R) ---
        let nsx = Vehicle(
            name: "Weekend Car",
            make: "Honda",
            model: "NSX Type R",
            year: 1992,
            currentMileage: 18200,
            vin: "NA1-1200034",
            tireSize: "205/50R15 F, 225/50R16 R",
            oilType: "10W-30",
            notes: "JDM-spec NSX-R. Hand-balanced C30A V6. Garage kept.",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)
        )
        modelContext.insert(nsx)

        for service in Service.sampleServicesCompact(for: nsx) {
            modelContext.insert(service)
        }
        for log in ServiceLog.sampleLogsCompact(for: nsx) {
            modelContext.insert(log)
        }

        // Track sample vehicle IDs for cleanup
        onboardingState.sampleVehicleIDs = [camry.id, nsx.id]
    }

    /// Clear all sample data created during onboarding tour
    func clearSampleData() {
        let idsToRemove = onboardingState.sampleVehicleIDs
        guard !idsToRemove.isEmpty else { return }

        for vehicle in vehicles where idsToRemove.contains(vehicle.id) {
            modelContext.delete(vehicle)
        }
        // Sweep any sample documents that lose their last vehicle link.
        Document.purgeOrphans(in: modelContext)
        onboardingState.sampleVehicleIDs = []
        appState.selectedVehicle = nil
    }
}
