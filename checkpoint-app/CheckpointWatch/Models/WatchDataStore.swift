//
//  WatchDataStore.swift
//  CheckpointWatch
//
//  Observable data store for Watch app — persists to watch-side App Group UserDefaults
//  iPhone is source of truth; this is a local cache for offline/glanceable access
//

import Foundation
import os

private let storeLogger = Logger(subsystem: "com.418-studio.checkpoint.watch", category: "DataStore")

@Observable
@MainActor
final class WatchDataStore {
    static let shared = WatchDataStore()

    // MARK: - App Group

    static let appGroupID = "group.com.418-studio.checkpoint.watch"
    private static let vehicleDataKey = "watchVehicleData"

    // MARK: - State

    var vehicleData: WatchVehicleData?

    /// Whether data exists but is older than 1 hour
    var isStale: Bool {
        vehicleData?.isStale ?? false
    }

    /// Whether any data is available
    var hasData: Bool {
        vehicleData != nil
    }

    /// Services sorted by urgency (overdue first, then dueSoon, good, neutral)
    var sortedServices: [WatchService] {
        guard let services = vehicleData?.services else { return [] }
        return services.sorted { lhs, rhs in
            lhs.status.sortOrder < rhs.status.sortOrder
        }
    }

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - Persistence

    /// Load vehicle data from watch App Group UserDefaults
    func load() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = defaults.data(forKey: Self.vehicleDataKey) else {
            storeLogger.info("No watch vehicle data in UserDefaults")
            return
        }

        do {
            vehicleData = try JSONDecoder().decode(WatchVehicleData.self, from: data)
            storeLogger.info("Loaded watch data for \(self.vehicleData?.vehicleName ?? "unknown")")
        } catch {
            storeLogger.error("Failed to decode watch vehicle data: \(error.localizedDescription)")
        }
    }

    /// Save vehicle data to watch App Group UserDefaults
    func save(_ data: WatchVehicleData) {
        vehicleData = data

        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            storeLogger.error("Failed to access watch App Group UserDefaults")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: Self.vehicleDataKey)
            storeLogger.info("Saved watch data for \(data.vehicleName)")
        } catch {
            storeLogger.error("Failed to encode watch vehicle data: \(error.localizedDescription)")
        }
    }

    /// Clear all stored data
    func clear() {
        vehicleData = nil
        UserDefaults(suiteName: Self.appGroupID)?.removeObject(forKey: Self.vehicleDataKey)
    }

    // MARK: - Optimistic Updates

    /// Optimistically update mileage locally (before iPhone confirms)
    func updateMileageOptimistically(_ newMileage: Int) {
        guard let current = vehicleData else { return }
        vehicleData = WatchVehicleData(
            vehicleID: current.vehicleID,
            vehicleName: current.vehicleName,
            currentMileage: newMileage,
            estimatedMileage: nil,
            isEstimated: false,
            services: current.services,
            updatedAt: current.updatedAt,
            distanceUnit: current.distanceUnit
        )
    }

    /// Optimistically mark a service as done locally
    /// Prefers serviceID match; falls back to name match for backward compatibility
    func markServiceDoneOptimistically(serviceID: String?, serviceName: String) {
        guard let current = vehicleData else { return }
        let updatedServices = current.services.filter { service in
            if let serviceID, let sid = service.serviceID {
                return sid != serviceID
            }
            return service.name != serviceName
        }
        vehicleData = WatchVehicleData(
            vehicleID: current.vehicleID,
            vehicleName: current.vehicleName,
            currentMileage: current.currentMileage,
            estimatedMileage: current.estimatedMileage,
            isEstimated: current.isEstimated,
            services: updatedServices,
            updatedAt: current.updatedAt,
            distanceUnit: current.distanceUnit
        )
    }
}

// MARK: - Status Sort Order

extension WatchServiceStatus {
    var sortOrder: Int {
        switch self {
        case .overdue: return 0
        case .dueSoon: return 1
        case .good: return 2
        case .neutral: return 3
        }
    }
}
