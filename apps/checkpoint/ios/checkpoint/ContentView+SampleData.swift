//
//  ContentView+SampleData.swift
//  checkpoint
//
//  The sample garage the onboarding tour spotlights, and its cleanup.
//

import SwiftUI
import SwiftData

extension ContentView {

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
