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
    var notes: String?
    var createdAt: Date

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
        notes: String? = nil,
        createdAt: Date = Date.now
    ) {
        self.service = service
        self.vehicle = vehicle
        self.performedDate = performedDate
        self.mileageAtService = mileageAtService
        self.cost = cost
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data

extension ServiceLog {
    static func sampleLogs(for vehicle: Vehicle, service: Service? = nil) -> [ServiceLog] {
        let calendar = Calendar.current

        let recentLog = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -7, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 500,
            cost: 45.99,
            notes: "Oil change completed at local shop"
        )

        let olderLog = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .month, value: -6, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 5500,
            cost: 125.50,
            notes: "Tire rotation and brake inspection"
        )

        let noNotesLog = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .year, value: -1, to: .now) ?? .now,
            mileageAtService: vehicle.currentMileage - 12000
        )

        return [recentLog, olderLog, noNotesLog]
    }
}
