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
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int = 0
    var currentMileage: Int = 0
    var vin: String?
    var licensePlate: String?

    // Specifications
    var tireSize: String?
    var oilType: String?

    // Notes
    var notes: String?

    // Mileage tracking
    var mileageUpdatedAt: Date?

    // Marbete (PR vehicle registration tag) - optional
    var marbeteExpirationMonth: Int?  // 1-12
    var marbeteExpirationYear: Int?   // e.g., 2025
    var marbeteNotificationID: String?

    @Relationship(deleteRule: .cascade, inverse: \Service.vehicle)
    var services: [Service]? = []

    @Relationship(deleteRule: .cascade, inverse: \ServiceLog.vehicle)
    var serviceLogs: [ServiceLog]? = []

    @Relationship(deleteRule: .cascade, inverse: \MileageSnapshot.vehicle)
    var mileageSnapshots: [MileageSnapshot]? = []

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
        vin: String? = nil,
        licensePlate: String? = nil,
        tireSize: String? = nil,
        oilType: String? = nil,
        notes: String? = nil,
        mileageUpdatedAt: Date? = nil,
        marbeteExpirationMonth: Int? = nil,
        marbeteExpirationYear: Int? = nil
    ) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = currentMileage
        self.vin = vin
        self.licensePlate = licensePlate
        self.tireSize = tireSize
        self.oilType = oilType
        self.notes = notes
        self.mileageUpdatedAt = mileageUpdatedAt
        self.marbeteExpirationMonth = marbeteExpirationMonth
        self.marbeteExpirationYear = marbeteExpirationYear
    }
}

