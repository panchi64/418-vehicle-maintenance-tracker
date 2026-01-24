//
//  Vehicle.swift
//  checkpoint
//
//  SwiftData model for vehicles
//

import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID = UUID()
    var name: String
    var make: String
    var model: String
    var year: Int
    var currentMileage: Int
    var vin: String?

    @Relationship(deleteRule: .cascade, inverse: \Service.vehicle)
    var services: [Service] = []

    @Relationship(deleteRule: .cascade, inverse: \ServiceLog.vehicle)
    var serviceLogs: [ServiceLog] = []

    var displayName: String {
        if name.isEmpty {
            return "\(year) \(make) \(model)"
        }
        return name
    }

    init(
        name: String = "",
        make: String,
        model: String,
        year: Int,
        currentMileage: Int = 0,
        vin: String? = nil
    ) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = currentMileage
        self.vin = vin
    }
}

// MARK: - Sample Data

extension Vehicle {
    static var sampleVehicle: Vehicle {
        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        )
        return vehicle
    }

    static var sampleVehicles: [Vehicle] {
        [
            Vehicle(
                name: "Daily Driver",
                make: "Toyota",
                model: "Camry",
                year: 2022,
                currentMileage: 32500
            ),
            Vehicle(
                name: "Weekend Car",
                make: "Mazda",
                model: "MX-5",
                year: 2020,
                currentMileage: 18200
            )
        ]
    }
}
