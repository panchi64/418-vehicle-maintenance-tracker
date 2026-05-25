//
//  VehicleEntity.swift
//  CheckpointWidget
//
//  AppEntity for vehicle selection in widget configuration and Siri intents
//  This file should be added to BOTH the main app and widget targets in Xcode
//

import AppIntents

/// Entity representing a vehicle for widget configuration and Siri intent selection
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
