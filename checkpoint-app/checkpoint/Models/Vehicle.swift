//
//  Vehicle.swift
//  checkpoint
//
//  SwiftData model for vehicles
//

import Foundation
import SwiftData

@Model
final class Vehicle: Identifiable {
    var id: UUID = UUID()
    var name: String
    var make: String
    var model: String
    var year: Int
    var currentMileage: Int
    var vin: String?

    // Specifications
    var tireSize: String?
    var oilType: String?

    // Mileage tracking
    var mileageUpdatedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Service.vehicle)
    var services: [Service] = []

    @Relationship(deleteRule: .cascade, inverse: \ServiceLog.vehicle)
    var serviceLogs: [ServiceLog] = []

    @Relationship(deleteRule: .cascade, inverse: \MileageSnapshot.vehicle)
    var mileageSnapshots: [MileageSnapshot] = []

    var displayName: String {
        if name.isEmpty {
            return "\(year) \(make) \(model)"
        }
        return name
    }

    /// Calculate daily miles pace from mileage snapshots
    /// Returns nil if insufficient data (less than 7 days)
    var dailyMilesPace: Double? {
        MileageSnapshot.calculateDailyPace(from: mileageSnapshots)
    }

    /// Check if we have enough data for pace calculation (7+ days)
    var hasSufficientPaceData: Bool {
        dailyMilesPace != nil
    }

    /// Days since mileage was last updated
    var daysSinceMileageUpdate: Int? {
        guard let updatedAt = mileageUpdatedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: updatedAt, to: .now).day
    }

    /// Formatted string for last mileage update
    var mileageUpdateDescription: String {
        guard let days = daysSinceMileageUpdate else {
            return "Never updated"
        }
        if days == 0 {
            return "Updated today"
        } else if days == 1 {
            return "Updated yesterday"
        } else {
            return "Updated \(days) days ago"
        }
    }

    /// Truncated VIN for display (last 4 characters)
    var truncatedVIN: String? {
        guard let vin = vin, vin.count >= 4 else { return vin }
        return "..." + String(vin.suffix(4))
    }

    init(
        name: String = "",
        make: String,
        model: String,
        year: Int,
        currentMileage: Int = 0,
        vin: String? = nil,
        tireSize: String? = nil,
        oilType: String? = nil,
        mileageUpdatedAt: Date? = nil
    ) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = currentMileage
        self.vin = vin
        self.tireSize = tireSize
        self.oilType = oilType
        self.mileageUpdatedAt = mileageUpdatedAt
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
