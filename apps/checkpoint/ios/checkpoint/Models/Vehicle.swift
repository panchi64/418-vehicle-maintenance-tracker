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

    @Relationship(deleteRule: .cascade, inverse: \ServiceVisit.vehicle)
    var serviceVisits: [ServiceVisit]? = []

    /// Documents linked to this vehicle. Many-to-many — a single file may be
    /// linked to multiple vehicles. `.nullify` keeps the file alive when one
    /// linked vehicle is deleted; the orphan sweep in `Document.purgeOrphans`
    /// removes documents that no longer belong anywhere.
    @Relationship(deleteRule: .nullify, inverse: \ServiceAttachment.vehicles)
    var documents: [ServiceAttachment]? = []

    var displayName: String {
        if name.isEmpty {
            return identityLine
        }
        return name
    }

    /// "2022 Toyota Camry", or "Toyota Camry" when the year is unknown. Year is
    /// optional on the vehicle forms and stored as 0 when skipped, which must
    /// never render as "0 Toyota Camry".
    var identityLine: String {
        let parts = [hasModelYear ? String(year) : nil, make, model]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    /// Whether a model year was entered. 0 is the stored "unknown".
    var hasModelYear: Bool { year > 0 }

    /// A plausible model year: 1900 through two years from now. Shared by the
    /// add and edit forms so they accept the same values.
    static func isPlausibleModelYear(_ year: Int, now: Date = .now) -> Bool {
        let maxYear = Calendar.current.component(.year, from: now) + 2
        return (1900...maxYear).contains(year)
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

