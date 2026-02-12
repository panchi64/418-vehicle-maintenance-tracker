//
//  VehicleEntityQuery.swift
//  CheckpointWidget
//
//  EntityQuery for fetching vehicles from App Group UserDefaults
//  This file should be added to BOTH the main app and widget targets in Xcode
//

import AppIntents

#if !MAIN_APP_TARGET
// MARK: - Vehicle List Item

/// Lightweight vehicle data for widget/Siri configuration stored in App Group UserDefaults
/// Only defined here for the widget target - main app uses WidgetDataService.VehicleListItem
struct VehicleListItem: Codable, Sendable {
    let id: String
    let displayName: String
}
#endif

// MARK: - Vehicle Entity Query

/// Query to fetch vehicles for widget configuration picker and Siri intents
struct VehicleEntityQuery: EntityQuery {
    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let vehicleListKey = "vehicleList"

    /// Pseudo-entity representing "use the app's current vehicle selection"
    private static let matchAppEntity = VehicleEntity(id: "match-app", displayName: "Match App")

    func entities(for identifiers: [VehicleEntity.ID]) async throws -> [VehicleEntity] {
        let allVehicles = loadVehicles()
        return identifiers.compactMap { id in
            if id == "match-app" {
                return Self.matchAppEntity
            }
            return allVehicles.first { $0.id == id }
        }
    }

    func suggestedEntities() async throws -> [VehicleEntity] {
        [Self.matchAppEntity] + loadVehicles()
    }

    func defaultResult() async -> VehicleEntity? {
        Self.matchAppEntity
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
