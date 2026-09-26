//
//  VehicleEntity.swift
//  CheckpointWidget
//
//  AppEntity for vehicle selection in widget configuration. Widget target
//  only. The app declares its own, richer `VehicleEntity` (SwiftData-backed,
//  Spotlight-indexed) in checkpoint/Services/Intents/Entities/. The name is
//  kept here on purpose: widget configurations users already saved reference
//  this type by name, and the two never share a target.
//

import AppIntents

/// Entity representing a vehicle for widget configuration
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
