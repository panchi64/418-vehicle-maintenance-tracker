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
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int = 0
    var currentMileage: Int = 0
    var vin: String?

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

    /// Calculate daily miles pace from mileage snapshots
    /// Returns nil if insufficient data (less than 7 days)
    var dailyMilesPace: Double? {
        MileageSnapshot.calculateDailyPace(from: mileageSnapshots ?? [])
    }

    /// Check if we have enough data for pace calculation (7+ days)
    var hasSufficientPaceData: Bool {
        dailyMilesPace != nil
    }

    /// Pace result with confidence metadata
    var paceResult: PaceResult? {
        MileageSnapshot.calculatePaceResult(from: mileageSnapshots ?? [])
    }

    /// Confidence level of the pace data
    var paceConfidence: ConfidenceLevel? {
        paceResult?.confidence
    }

    /// Maximum days since last update before we stop trusting estimates
    private static let maxEstimationDays = 60

    /// Estimated current mileage based on driving pace (in miles)
    /// Returns nil if insufficient pace data or stale data (>60 days)
    var estimatedMileage: Int? {
        guard let pace = dailyMilesPace,
              let daysSince = daysSinceMileageUpdate,
              daysSince <= Self.maxEstimationDays,
              daysSince > 0 else { return nil }

        let estimatedDriven = pace * Double(daysSince)
        return currentMileage + Int(round(estimatedDriven))
    }

    /// Returns estimated mileage if available, otherwise actual mileage (in miles)
    var effectiveMileage: Int {
        estimatedMileage ?? currentMileage
    }

    /// Whether the mileage displayed is estimated (vs actual)
    var isUsingEstimatedMileage: Bool {
        estimatedMileage != nil
    }

    /// Days since mileage was last updated
    var daysSinceMileageUpdate: Int? {
        guard let updatedAt = mileageUpdatedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: updatedAt, to: .now).day
    }

    /// Whether to show the mileage update prompt (never updated or 14+ days)
    var shouldPromptMileageUpdate: Bool {
        guard let days = daysSinceMileageUpdate else {
            return true // Never updated
        }
        return days >= 14
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

    // MARK: - Marbete Computed Properties

    /// Days threshold for "due soon" status (60 days for marbete)
    private static let marbeteDueSoonThreshold = 60

    /// Whether marbete expiration is configured (requires both month AND year)
    var hasMarbeteExpiration: Bool {
        marbeteExpirationMonth != nil && marbeteExpirationYear != nil
    }

    /// The last day of the marbete expiration month
    var marbeteExpirationDate: Date? {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDay = Calendar.current.date(from: components) else { return nil }

        // Get the last day of the month
        guard let lastDay = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: firstDay
        ) else { return nil }

        return lastDay
    }

    /// Days until marbete expiration (negative if expired)
    var daysUntilMarbeteExpiration: Int? {
        guard let expirationDate = marbeteExpirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: expirationDate)).day
    }

    /// Marbete status using 60-day "due soon" threshold
    var marbeteStatus: ServiceStatus {
        guard hasMarbeteExpiration else { return .neutral }
        guard let days = daysUntilMarbeteExpiration else { return .neutral }

        if days < 0 {
            return .overdue
        } else if days <= Self.marbeteDueSoonThreshold {
            return .dueSoon
        } else {
            return .good
        }
    }

    /// Formatted marbete expiration string (e.g., "March 2025")
    var marbeteExpirationFormatted: String? {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return nil }

        let monthName = Calendar.current.monthSymbols[month - 1]
        return "\(monthName) \(year)"
    }

    /// Urgency score for marbete (for sorting with services)
    /// Lower score = more urgent
    var marbeteUrgencyScore: Int {
        guard hasMarbeteExpiration else { return Int.max }
        return daysUntilMarbeteExpiration ?? Int.max
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
        self.tireSize = tireSize
        self.oilType = oilType
        self.notes = notes
        self.mileageUpdatedAt = mileageUpdatedAt
        self.marbeteExpirationMonth = marbeteExpirationMonth
        self.marbeteExpirationYear = marbeteExpirationYear
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
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2026
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
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                marbeteExpirationMonth: 3,
                marbeteExpirationYear: 2026
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
