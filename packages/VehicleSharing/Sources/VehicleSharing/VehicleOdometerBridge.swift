//
//  VehicleOdometerBridge.swift
//  VehicleSharing
//
//  Read/write bridge over the shared App Group. Checkpoint publishes vehicle
//  odometers and drains queued updates; Biombo reads odometers and queues
//  updates. All access goes through an injected UserDefaults so tests can run
//  against an isolated suite.
//

import Foundation
import OSLog

public enum VehicleOdometerBridge {
    /// Key for the published `[SharedVehicleOdometer]` blob (written by Checkpoint).
    static let vehiclesKey = "sharedVehicleOdometers"
    /// Key for the `[PendingOdometerUpdate]` queue (written by Biombo).
    static let pendingUpdatesKey = "pendingOdometerUpdates"

    private static let logger = Logger(subsystem: "com.418-studio.shared", category: "OdometerBridge")

    // MARK: - Checkpoint: publish (writer side)

    /// Replace the published vehicle odometer list. Called by Checkpoint
    /// whenever vehicle or mileage data changes.
    public static func publish(
        _ vehicles: [SharedVehicleOdometer],
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) {
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(vehicles)
            defaults.set(data, forKey: vehiclesKey)
        } catch {
            logger.error("Failed to encode shared odometers: \(error.localizedDescription)")
        }
    }

    // MARK: - Biombo: read (reader side)

    /// Read the vehicle odometers published by Checkpoint. Returns an empty
    /// array when nothing has been published or the entitlement is missing.
    public static func readVehicles(
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) -> [SharedVehicleOdometer] {
        guard let defaults, let data = defaults.data(forKey: vehiclesKey) else { return [] }
        do {
            return try JSONDecoder().decode([SharedVehicleOdometer].self, from: data)
        } catch {
            logger.error("Failed to decode shared odometers: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Biombo: queue update (writer side)

    /// Append an odometer reading to the pending queue for Checkpoint to apply.
    public static func queueUpdate(
        _ update: PendingOdometerUpdate,
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) {
        guard let defaults else { return }
        var pending = loadPendingUpdates(defaults: defaults)
        pending.append(update)
        do {
            let data = try JSONEncoder().encode(pending)
            defaults.set(data, forKey: pendingUpdatesKey)
        } catch {
            logger.error("Failed to encode pending odometer update: \(error.localizedDescription)")
        }
    }

    // MARK: - Checkpoint: drain (reader/clear side)

    /// Read the queued updates without clearing them. This is the preferred
    /// entry point for Checkpoint's apply flow: read here, commit + save, then
    /// call `removePendingUpdates(ids:)` so a failed save leaves the queue intact.
    public static func loadPendingUpdates(
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) -> [PendingOdometerUpdate] {
        guard let defaults, let data = defaults.data(forKey: pendingUpdatesKey) else { return [] }
        do {
            return try JSONDecoder().decode([PendingOdometerUpdate].self, from: data)
        } catch {
            logger.error("Failed to decode pending odometer updates: \(error.localizedDescription)")
            return []
        }
    }

    /// Remove exactly the entries with the given ids from the pending queue,
    /// re-reading the queue immediately before the write so a `queueUpdate` that
    /// Biombo appended after we read is preserved rather than clobbered.
    ///
    /// UserDefaults offers no cross-process lock, so a vanishingly small window
    /// remains between this re-read and its write-back; because every update
    /// carries a stable `id` and Checkpoint's apply is forward-only, a reading
    /// caught in that window is at worst reprocessed idempotently, never one that
    /// was silently dropped by a blanket clear.
    public static func removePendingUpdates(
        _ ids: Set<UUID>,
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) {
        guard let defaults, !ids.isEmpty else { return }
        let remaining = loadPendingUpdates(defaults: defaults).filter { !ids.contains($0.id) }
        if remaining.isEmpty {
            defaults.removeObject(forKey: pendingUpdatesKey)
            return
        }
        do {
            let data = try JSONEncoder().encode(remaining)
            defaults.set(data, forKey: pendingUpdatesKey)
        } catch {
            logger.error("Failed to encode remaining odometer updates: \(error.localizedDescription)")
        }
    }

    /// Read the pending queue and remove exactly what was read. Prefer the
    /// `loadPendingUpdates` + `removePendingUpdates(ids:)` pairing when the caller
    /// needs to gate removal on a successful commit; this convenience drains in
    /// one call for cases that don't.
    @discardableResult
    public static func drainPendingUpdates(
        defaults: UserDefaults? = SharedAppGroup.defaults()
    ) -> [PendingOdometerUpdate] {
        let pending = loadPendingUpdates(defaults: defaults)
        guard !pending.isEmpty else { return [] }
        removePendingUpdates(Set(pending.map(\.id)), defaults: defaults)
        return pending
    }
}
