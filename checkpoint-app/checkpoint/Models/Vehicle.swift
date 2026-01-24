//
//  Vehicle.swift
//  checkpoint
//
//  SwiftData model for vehicles
//

import Foundation
import SwiftData
import SwiftUI

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

    // Notes
    var notes: String?

    // Mileage tracking
    var mileageUpdatedAt: Date?

    // Vehicle photo (stored as compressed JPEG data)
    @Attribute(.externalStorage)
    var photoData: Data?

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

    /// Returns a SwiftUI Image from the stored photo data
    var photo: Image? {
        guard let data = photoData,
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    /// Returns a UIImage from the stored photo data
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
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
        notes: String? = nil,
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
        self.notes = notes
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
            currentMileage: 32500,
            vin: "4T1BF1FK5CU123456",
            tireSize: "215/55R17",
            oilType: "0W-20 Synthetic",
            notes: "Purchased certified pre-owned. Runs great!",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
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
                currentMileage: 32500,
                vin: "4T1BF1FK5CU123456",
                tireSize: "215/55R17",
                oilType: "0W-20 Synthetic",
                notes: "Purchased certified pre-owned. Runs great!",
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
            ),
            Vehicle(
                name: "Weekend Car",
                make: "Mazda",
                model: "MX-5",
                year: 2020,
                currentMileage: 18200,
                vin: "JM1NDAD75L0123789",
                tireSize: "205/45R17",
                oilType: "0W-20 Synthetic",
                notes: "Garage kept. Summer tires only.",
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)
            )
        ]
    }
}
