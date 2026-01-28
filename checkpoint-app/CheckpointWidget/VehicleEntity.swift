//
//  VehicleEntity.swift
//  CheckpointWidget
//
//  AppEntity for vehicle selection in widget configuration
//

import AppIntents

/// Entity representing a vehicle for widget configuration selection
struct VehicleEntity: AppEntity {
    let id: String
    let displayName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Vehicle"
    }

    static var defaultQuery = VehicleEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
