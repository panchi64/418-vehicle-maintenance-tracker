//
//  ServiceLog.swift
//  checkpoint
//
//  SwiftData model for completed service records
//

import Foundation
import SwiftData

@Model
final class ServiceLog: Identifiable {
    var id: UUID = UUID()
    var service: Service?
    var vehicle: Vehicle?
    var performedDate: Date
    var mileageAtService: Int
    var cost: Decimal?
    var costCategory: CostCategory?
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ServiceAttachment.serviceLog)
    var attachments: [ServiceAttachment] = []

    var formattedCost: String? {
        guard let cost = cost else { return nil }
        return Formatters.currency.string(from: cost as NSDecimalNumber)
    }

    var daysSincePerformed: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: performedDate, to: Date.now).day ?? 0
        return days
    }

    init(
        service: Service? = nil,
        vehicle: Vehicle? = nil,
        performedDate: Date,
        mileageAtService: Int,
        cost: Decimal? = nil,
        costCategory: CostCategory? = nil,
        notes: String? = nil,
        createdAt: Date = Date.now
    ) {
        self.service = service
        self.vehicle = vehicle
        self.performedDate = performedDate
        self.mileageAtService = mileageAtService
        self.cost = cost
        self.costCategory = costCategory
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data

extension ServiceLog {
    static func sampleLogs(for vehicle: Vehicle, service: Service? = nil) -> [ServiceLog] {
        let calendar = Calendar.current

        // Recent maintenance - oil change
        let oilChange = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -7, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 500,
            cost: 45.99,
            costCategory: .maintenance,
            notes: "Oil change completed at local shop. Used synthetic 0W-20."
        )

        // Maintenance - tire rotation from 2 months ago
        let tireRotation = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -2, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 2000,
            cost: 35.00,
            costCategory: .maintenance,
            notes: "Rotated and balanced all four tires"
        )

        // Repair - brake pads from 4 months ago
        let brakePads = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -4, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 4500,
            cost: 285.00,
            costCategory: .repair,
            notes: "Front brake pads worn. Replaced with ceramic pads."
        )

        // Maintenance - air filter from 6 months ago
        let airFilter = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -6, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 5500,
            cost: 28.50,
            costCategory: .maintenance,
            notes: "Replaced engine air filter"
        )

        // Upgrade - new floor mats from 8 months ago
        let floorMats = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -8, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 7000,
            cost: 149.99,
            costCategory: .upgrade,
            notes: "WeatherTech all-weather floor mats"
        )

        // Repair - battery replacement from 10 months ago
        let battery = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -10, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 9000,
            cost: 175.00,
            costCategory: .repair,
            notes: "Battery died unexpectedly. Replaced with Interstate."
        )

        // Maintenance - coolant flush from 1 year ago
        let coolant = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .year, value: -1, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 12000,
            cost: 95.00,
            costCategory: .maintenance
        )

        return [oilChange, tireRotation, brakePads, airFilter, floorMats, battery, coolant]
    }
}
