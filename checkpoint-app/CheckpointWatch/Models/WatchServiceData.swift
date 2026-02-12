//
//  WatchServiceData.swift
//  CheckpointWatch
//
//  Codable data types shared between iPhone and Apple Watch via WatchConnectivity
//  iPhone is source of truth — Watch stores lightweight JSON copies
//

import Foundation

// MARK: - Vehicle Data (iPhone → Watch)

struct WatchVehicleData: Codable, Sendable {
    let vehicleID: String
    let vehicleName: String
    let currentMileage: Int
    let estimatedMileage: Int?
    let isEstimated: Bool
    let services: [WatchService]
    let updatedAt: Date

    /// Whether data is stale (older than 1 hour)
    var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > 3600
    }
}

// MARK: - Service Data

struct WatchService: Codable, Identifiable, Sendable {
    /// Uses serviceID (iPhone-side UUID) when available, falls back to composite ID
    var id: String { serviceID ?? "\(vehicleID)_\(name)" }

    let vehicleID: String
    let serviceID: String?
    let name: String
    let status: WatchServiceStatus
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}

// MARK: - Service Status

enum WatchServiceStatus: String, Codable, Sendable {
    case overdue, dueSoon, good, neutral
}

// MARK: - Watch → iPhone Messages

/// Message sent from Watch to iPhone to update mileage
struct WatchMileageUpdate: Codable, Sendable {
    let vehicleID: String
    let newMileage: Int
    let timestamp: Date

    static let messageKey = "updateMileage"
}

/// Message sent from Watch to iPhone to mark a service as done
struct WatchMarkServiceDone: Codable, Sendable {
    let vehicleID: String
    let serviceID: String?
    let serviceName: String
    let mileageAtService: Int
    let performedDate: Date

    static let messageKey = "markServiceDone"
}

// MARK: - iPhone → Watch Context

/// Application context sent from iPhone to Watch
struct WatchApplicationContext: Codable, Sendable {
    let vehicleData: WatchVehicleData?
    let lastUpdated: Date

    static let contextKey = "watchContext"

    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.contextKey: data]
    }

    static func from(dictionary: [String: Any]) -> WatchApplicationContext? {
        guard let data = dictionary[contextKey] as? Data else { return nil }
        return try? JSONDecoder().decode(WatchApplicationContext.self, from: data)
    }
}
