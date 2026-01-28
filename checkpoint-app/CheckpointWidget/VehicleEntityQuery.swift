//
//  VehicleEntityQuery.swift
//  CheckpointWidget
//
//  EntityQuery for fetching vehicles from App Group UserDefaults
//

import AppIntents

// MARK: - Vehicle List Item

/// Lightweight vehicle data for widget configuration stored in App Group UserDefaults
struct VehicleListItem: Codable, Sendable {
    let id: String
    let displayName: String
}

// MARK: - Vehicle Entity Query

/// Query to fetch vehicles for widget configuration picker
struct VehicleEntityQuery: EntityQuery {
    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let vehicleListKey = "vehicleList"

    func entities(for identifiers: [VehicleEntity.ID]) async throws -> [VehicleEntity] {
        let allVehicles = loadVehicles()
        return allVehicles.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [VehicleEntity] {
        loadVehicles()
    }

    func defaultResult() async -> VehicleEntity? {
        loadVehicles().first
    }

    private func loadVehicles() -> [VehicleEntity] {
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: vehicleListKey) else {
            return []
        }

        do {
            let items = try JSONDecoder().decode([VehicleListItem].self, from: data)
            return items.map { VehicleEntity(id: $0.id, displayName: $0.displayName) }
        } catch {
            print("Widget failed to decode vehicle list: \(error)")
            return []
        }
    }
}
