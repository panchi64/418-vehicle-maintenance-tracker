//
//  PendingWidgetCompletion.swift
//  CheckpointWidget
//
//  Codable struct for pending service completions from widget "Done" button
//  Stored in App Group UserDefaults, processed by main app on foreground
//

import Foundation
import os

private let widgetLogger = Logger(subsystem: "com.418-studio.checkpoint.widget", category: "PendingCompletion")

struct PendingWidgetCompletion: Codable {
    let serviceID: String
    let vehicleID: String
    let performedDate: Date
    let mileageAtService: Int

    static let userDefaultsKey = "pendingWidgetCompletions"
    static let appGroupID = "group.com.418-studio.checkpoint.shared"

    /// TTL for pending completions (7 days)
    private static let ttlSeconds: TimeInterval = 7 * 24 * 60 * 60

    /// Save a pending completion to App Group UserDefaults
    /// Deduplicates by serviceID and prunes expired entries
    static func save(_ completion: PendingWidgetCompletion) {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(appGroupID)) in save()")
            return
        }

        var pending = loadAll()

        // Deduplicate: skip if this serviceID is already pending
        if pending.contains(where: { $0.serviceID == completion.serviceID }) {
            widgetLogger.info("Duplicate pending completion for service \(completion.serviceID), skipping")
            return
        }

        pending.append(completion)

        if let data = try? JSONEncoder().encode(pending) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }

    /// Load all pending completions from App Group UserDefaults, pruning expired entries
    static func loadAll() -> [PendingWidgetCompletion] {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(appGroupID)) in loadAll()")
            return []
        }
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }

        let all = (try? JSONDecoder().decode([PendingWidgetCompletion].self, from: data)) ?? []

        // Prune expired entries (older than TTL)
        let now = Date()
        let valid = all.filter { now.timeIntervalSince($0.performedDate) < ttlSeconds }

        // Persist pruned list if anything was removed
        if valid.count < all.count {
            if let pruned = try? JSONEncoder().encode(valid) {
                userDefaults.set(pruned, forKey: userDefaultsKey)
            }
        }

        return valid
    }

    /// Clear all pending completions from App Group UserDefaults
    static func clearAll() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(appGroupID)) in clearAll()")
            return
        }
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}
