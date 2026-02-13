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

    /// Save a pending completion to App Group UserDefaults
    static func save(_ completion: PendingWidgetCompletion) {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(appGroupID)) in save()")
            return
        }

        var pending = loadAll()
        pending.append(completion)

        if let data = try? JSONEncoder().encode(pending) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }

    /// Load all pending completions from App Group UserDefaults
    static func loadAll() -> [PendingWidgetCompletion] {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(appGroupID)) in loadAll()")
            return []
        }
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([PendingWidgetCompletion].self, from: data)) ?? []
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
