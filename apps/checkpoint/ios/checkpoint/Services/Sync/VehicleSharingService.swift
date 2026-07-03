//
//  VehicleSharingService.swift
//  checkpoint
//
//  Bridges Checkpoint's vehicle odometers to the cross-product App Group so the
//  Biombo companion app can read them and queue updates. Checkpoint remains the
//  source of truth: it publishes readings and validates/commits queued updates.
//

import Foundation
import SwiftData
import VehicleSharing
import os

private let sharingLogger = Logger(category: "VehicleSharing")

@MainActor
enum VehicleSharingService {
    // MARK: - Publish (Checkpoint → shared)

    /// Publish the current odometer state of all vehicles to the shared App Group.
    /// Called whenever vehicle or mileage data changes (foreground, background,
    /// vehicle switch, mileage update).
    static func publish(_ vehicles: [Vehicle]) {
        let unit = SharedDistanceUnit(rawValue: DistanceSettings.shared.unit.rawValue) ?? .miles
        let shared = vehicles.map { vehicle in
            SharedVehicleOdometer(
                id: vehicle.id.uuidString,
                displayName: vehicle.displayName,
                currentMileage: vehicle.currentMileage,
                estimatedMileage: vehicle.estimatedMileage,
                isEstimated: vehicle.isUsingEstimatedMileage,
                distanceUnit: unit,
                updatedAt: vehicle.mileageUpdatedAt
            )
        }
        VehicleOdometerBridge.publish(shared)
    }

    /// Whether a queued reading should be committed to a vehicle currently at
    /// `currentMileage`. Rejects non-positive readings and readings below the
    /// current value — odometers only move forward, so a lower value is treated
    /// as a stale queue entry or typo rather than corrupting pace history.
    nonisolated static func shouldApply(mileage: Int, toCurrentMileage currentMileage: Int) -> Bool {
        mileage > 0 && mileage >= currentMileage
    }

    // MARK: - Drain (shared → Checkpoint)

    /// Apply odometer readings queued by Biombo. Validates each reading, commits
    /// it via `Vehicle.recordMileage` (source `.biombo`), and saves once.
    ///
    /// - Returns: `true` if any reading was applied, so the caller can refresh
    ///   widgets and re-publish.
    @discardableResult
    static func applyPendingUpdates(in context: ModelContext) -> Bool {
        // Read without removing: the queue is only cleared once the applied
        // readings are durably saved, so a save failure leaves them for the next
        // drain instead of losing them.
        let pending = VehicleOdometerBridge.loadPendingUpdates()
        guard !pending.isEmpty else { return false }

        sharingLogger.info("Applying \(pending.count) pending odometer update(s) from Biombo")

        let vehicles: [Vehicle]
        do {
            vehicles = try context.fetch(FetchDescriptor<Vehicle>())
        } catch {
            sharingLogger.error("Failed to fetch vehicles for pending odometer updates: \(error.localizedDescription)")
            return false
        }

        // Apply each reading in queue order (chronological).
        var applied = false
        for update in pending {
            guard let vehicleID = UUID(uuidString: update.vehicleID),
                  let vehicle = vehicles.first(where: { $0.id == vehicleID }) else {
                sharingLogger.error("Vehicle not found for queued odometer update: \(update.vehicleID)")
                continue
            }
            guard shouldApply(mileage: update.mileage, toCurrentMileage: vehicle.currentMileage) else {
                sharingLogger.info("Ignoring odometer reading \(update.mileage) for \(vehicle.displayName) (non-positive or below current)")
                continue
            }
            vehicle.recordMileage(update.mileage, recordedAt: update.recordedAt, source: .biombo, in: context)
            applied = true
        }

        let readIDs = Set(pending.map(\.id))

        guard applied else {
            // Nothing committed (every reading was stale, non-positive, or for an
            // unknown vehicle). Those can never become valid — odometers only move
            // forward — so drop them rather than let the queue grow unbounded.
            VehicleOdometerBridge.removePendingUpdates(readIDs)
            return false
        }

        do {
            try context.save()
        } catch {
            // Save failed: leave the queue intact so the next foreground retries.
            sharingLogger.error("Failed to save pending odometer updates: \(error.localizedDescription). Leaving queue intact for retry.")
            return false
        }

        // Committed successfully — now remove exactly the entries we read.
        VehicleOdometerBridge.removePendingUpdates(readIDs)
        return true
    }
}
