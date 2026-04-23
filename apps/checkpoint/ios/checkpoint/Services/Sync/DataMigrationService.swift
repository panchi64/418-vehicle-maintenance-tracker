//
//  DataMigrationService.swift
//  checkpoint
//
//  Service for migrating data from local App Group store to CloudKit-enabled store
//

import Foundation
import SwiftData

/// Result of a migration operation
enum MigrationResult {
    case success(vehicleCount: Int, serviceCount: Int)
    case alreadyCompleted
    case noDataToMigrate
    case error(Error)
}

/// Service for handling data migration from local store to CloudKit
@MainActor
final class DataMigrationService {
    static let shared = DataMigrationService()

    private init() {}

    // MARK: - Migration Check

    /// Check if migration is needed (old App Group store exists and migration not completed)
    func needsMigration() -> Bool {
        // If migration already completed, skip
        if SyncSettings.shared.migrationCompleted {
            return false
        }

        // Check if old store file exists
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.iPhoneWidget) else {
            return false
        }

        let oldStoreURL = containerURL.appendingPathComponent("checkpoint.store")
        return FileManager.default.fileExists(atPath: oldStoreURL.path)
    }

    /// Get the URL of the old App Group store
    func oldStoreURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.iPhoneWidget) else {
            return nil
        }
        return containerURL.appendingPathComponent("checkpoint.store")
    }

    // MARK: - Migration

    /// Migrate data from old local store to new CloudKit-enabled store
    /// - Parameters:
    ///   - sourceContainer: The old ModelContainer (App Group store)
    ///   - destinationContainer: The new ModelContainer (CloudKit-enabled)
    /// - Returns: Migration result indicating success or failure
    func migrateData(
        from sourceContainer: ModelContainer,
        to destinationContainer: ModelContainer
    ) async -> MigrationResult {
        // If already migrated, skip
        if SyncSettings.shared.migrationCompleted {
            return .alreadyCompleted
        }

        let sourceContext = ModelContext(sourceContainer)
        let destContext = ModelContext(destinationContainer)

        do {
            // Fetch all vehicles from source
            let vehicleDescriptor = FetchDescriptor<Vehicle>()
            let vehicles = try sourceContext.fetch(vehicleDescriptor)

            if vehicles.isEmpty {
                // No data to migrate, mark as complete
                SyncSettings.shared.migrationCompleted = true
                return .noDataToMigrate
            }

            var totalServices = 0

            // Migrate each vehicle and its related data
            for vehicle in vehicles {
                // Create new vehicle in destination
                let newVehicle = Vehicle(
                    name: vehicle.name,
                    make: vehicle.make,
                    model: vehicle.model,
                    year: vehicle.year,
                    currentMileage: vehicle.currentMileage,
                    vin: vehicle.vin,
                    licensePlate: vehicle.licensePlate,
                    tireSize: vehicle.tireSize,
                    oilType: vehicle.oilType,
                    notes: vehicle.notes,
                    mileageUpdatedAt: vehicle.mileageUpdatedAt,
                    marbeteExpirationMonth: vehicle.marbeteExpirationMonth,
                    marbeteExpirationYear: vehicle.marbeteExpirationYear
                )

                destContext.insert(newVehicle)

                // Migrate services
                for service in vehicle.services ?? [] {
                    let newService = Service(
                        name: service.name,
                        dueDate: service.dueDate,
                        dueMileage: service.dueMileage,
                        lastPerformed: service.lastPerformed,
                        lastMileage: service.lastMileage,
                        intervalMonths: service.intervalMonths,
                        intervalMiles: service.intervalMiles,
                        notificationID: service.notificationID,
                        notes: service.notes
                    )
                    newService.vehicle = newVehicle

                    destContext.insert(newService)
                    totalServices += 1
                }

                // Migrate service logs
                for log in vehicle.serviceLogs ?? [] {
                    let newLog = ServiceLog(
                        service: log.service != nil ? nil : nil, // Service relationship needs separate handling
                        vehicle: newVehicle,
                        performedDate: log.performedDate,
                        mileageAtService: log.mileageAtService,
                        cost: log.cost,
                        costCategory: log.costCategory,
                        notes: log.notes,
                        createdAt: log.createdAt
                    )

                    destContext.insert(newLog)

                    // Migrate attachments
                    for attachment in log.attachments ?? [] {
                        let newAttachment = ServiceAttachment(
                            serviceLog: newLog,
                            data: attachment.data,
                            thumbnailData: attachment.thumbnailData,
                            fileName: attachment.fileName,
                            mimeType: attachment.mimeType,
                            createdAt: attachment.createdAt
                        )
                        destContext.insert(newAttachment)
                    }
                }

                // Migrate mileage snapshots
                for snapshot in vehicle.mileageSnapshots ?? [] {
                    let newSnapshot = MileageSnapshot(
                        vehicle: newVehicle,
                        mileage: snapshot.mileage,
                        recordedAt: snapshot.recordedAt,
                        source: snapshot.source
                    )
                    destContext.insert(newSnapshot)
                }
            }

            // Save destination context
            try destContext.save()

            // Mark migration as complete
            SyncSettings.shared.migrationCompleted = true

            return .success(vehicleCount: vehicles.count, serviceCount: totalServices)

        } catch {
            return .error(error)
        }
    }

    // MARK: - Cleanup

    /// Delete the old App Group store after successful migration
    /// Call this only after confirming the new store is working correctly
    func deleteOldStore() throws {
        guard let storeURL = oldStoreURL() else { return }

        let fileManager = FileManager.default

        // Delete main store file
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }

        // Also delete related files (WAL, SHM for SQLite)
        let walURL = storeURL.appendingPathExtension("wal")
        let shmURL = storeURL.appendingPathExtension("shm")

        if fileManager.fileExists(atPath: walURL.path) {
            try fileManager.removeItem(at: walURL)
        }
        if fileManager.fileExists(atPath: shmURL.path) {
            try fileManager.removeItem(at: shmURL)
        }
    }
}
