//
//  SiriDataProvider.swift
//  checkpoint
//
//  Provides service data for Siri intents by reading from App Groups
//  Mirrors the widget's data access pattern for consistency
//

import Foundation
import os

// MARK: - Siri Service Data Structures

/// Service data formatted for Siri dialog responses
nonisolated struct SiriServiceData {
    let vehicleName: String
    let vehicleID: String
    let currentMileage: Int
    let services: [SiriService]
}

/// Individual service information for Siri responses
nonisolated struct SiriService {
    let name: String
    let status: SiriServiceStatus
    let dueDescription: String
    let daysRemaining: Int?
}

/// Service status for Siri responses
nonisolated enum SiriServiceStatus: String {
    case overdue
    case dueSoon
    case good
    case neutral

    var dialogPrefix: String {
        switch self {
        case .overdue:
            return "Overdue"
        case .dueSoon:
            return "Due soon"
        case .good:
            return "Coming up"
        case .neutral:
            return "Scheduled"
        }
    }
}

// MARK: - Siri Data Provider

/// Reads vehicle and service data from App Groups for Siri intents
nonisolated struct SiriDataProvider {
    private static let logger = Logger(subsystem: "com.418-studio.checkpoint", category: "Siri")
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"
    private static let widgetDataKey = "widgetData"
    private static let vehicleListKey = "vehicleList"

    // MARK: - Public Methods

    /// Load service data for a specific vehicle or the default vehicle
    /// - Parameter vehicleID: Optional vehicle ID. If nil, loads the default (currently selected) vehicle
    /// - Returns: Service data for Siri responses, or nil if no data available
    static func loadServiceData(for vehicleID: String? = nil) -> SiriServiceData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            return nil
        }

        // If a specific vehicle is requested, try to load its data
        if let vehicleID = vehicleID {
            let vehicleKey = "widgetData_\(vehicleID)"
            if let data = userDefaults.data(forKey: vehicleKey) {
                return decodeServiceData(from: data)
            }
        }

        // Fall back to the default widget data (currently selected vehicle)
        if let data = userDefaults.data(forKey: widgetDataKey) {
            return decodeServiceData(from: data)
        }

        return nil
    }

    /// Load list of all vehicles
    /// - Returns: Array of vehicle entities available for selection
    static func loadVehicleList() -> [SiriVehicleInfo] {
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: vehicleListKey) else {
            return []
        }

        do {
            let items = try JSONDecoder().decode([VehicleListItemDTO].self, from: data)
            return items.map { SiriVehicleInfo(id: $0.id, displayName: $0.displayName) }
        } catch {
            logger.error("Failed to decode vehicle list: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Private Methods

    private static func decodeServiceData(from data: Data) -> SiriServiceData? {
        do {
            let widgetData = try JSONDecoder().decode(WidgetDataDTO.self, from: data)

            let services = widgetData.services.map { service in
                SiriService(
                    name: service.name,
                    status: mapStatus(service.status),
                    dueDescription: service.dueDescription,
                    daysRemaining: service.daysRemaining
                )
            }

            return SiriServiceData(
                vehicleName: widgetData.vehicleName,
                vehicleID: "", // Widget data doesn't include vehicle ID
                currentMileage: widgetData.currentMileage,
                services: services
            )
        } catch {
            logger.error("Failed to decode widget data: \(error.localizedDescription)")
            return nil
        }
    }

    private static func mapStatus(_ status: String) -> SiriServiceStatus {
        switch status.lowercased() {
        case "overdue":
            return .overdue
        case "duesoon":
            return .dueSoon
        case "good":
            return .good
        default:
            return .neutral
        }
    }
}

// MARK: - Vehicle Info

/// Lightweight vehicle info for Siri
nonisolated struct SiriVehicleInfo {
    let id: String
    let displayName: String
}

// MARK: - DTOs for Decoding

/// DTO for decoding vehicle list from UserDefaults
private nonisolated struct VehicleListItemDTO: Codable {
    let id: String
    let displayName: String
}

/// DTO for decoding widget data from UserDefaults
private nonisolated struct WidgetDataDTO: Codable {
    let vehicleName: String
    let currentMileage: Int
    let services: [SharedServiceDTO]
    let updatedAt: Date

    /// Handle optional fields for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicleName = try container.decode(String.self, forKey: .vehicleName)
        currentMileage = try container.decodeIfPresent(Int.self, forKey: .currentMileage) ?? 0
        services = try container.decode([SharedServiceDTO].self, forKey: .services)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case vehicleName, currentMileage, services, updatedAt
    }
}

/// DTO for decoding shared service data
private nonisolated struct SharedServiceDTO: Codable {
    let name: String
    let status: String
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}
