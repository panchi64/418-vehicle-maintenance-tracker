//
//  VehicleEntityQuery.swift
//  CheckpointWidget
//
//  EntityQuery for fetching vehicles from App Group UserDefaults.
//  Widget target only — the app has its own SwiftData-backed `VehicleEntity`
//  (checkpoint/Services/Intents/Entities/).
//

import AppIntents

// MARK: - Vehicle List Item

/// Lightweight vehicle data for widget configuration, written by the app's
/// `WidgetDataService.updateVehicleList` (which declares the same shape).
struct VehicleListItem: Codable, Sendable {
    let id: String
    let displayName: String
}

// MARK: - Vehicle Entity Query

/// Query to fetch vehicles for the widget configuration picker
struct VehicleEntityQuery: EntityQuery {
    private let vehicleListKey = WidgetAppGroup.vehicleListKey

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
        guard let userDefaults = WidgetAppGroup.defaults(),
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
