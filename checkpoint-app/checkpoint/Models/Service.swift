//
//  Service.swift
//  checkpoint
//
//  SwiftData model for vehicle maintenance services
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Service: Identifiable {
    var id: UUID = UUID()
    var name: String
    var dueDate: Date?
    var dueMileage: Int?
    var lastPerformed: Date?
    var lastMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var notificationID: String?

    var vehicle: Vehicle?

    @Relationship(deleteRule: .cascade, inverse: \ServiceLog.service)
    var logs: [ServiceLog] = []

    init(
        name: String,
        dueDate: Date? = nil,
        dueMileage: Int? = nil,
        lastPerformed: Date? = nil,
        lastMileage: Int? = nil,
        intervalMonths: Int? = nil,
        intervalMiles: Int? = nil,
        notificationID: String? = nil
    ) {
        self.name = name
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.lastPerformed = lastPerformed
        self.lastMileage = lastMileage
        self.intervalMonths = intervalMonths
        self.intervalMiles = intervalMiles
        self.notificationID = notificationID
    }
}

// MARK: - Service Status

enum ServiceStatus {
    case overdue
    case dueSoon
    case good
    case neutral

    var color: Color {
        switch self {
        case .overdue: return Theme.statusOverdue
        case .dueSoon: return Theme.statusDueSoon
        case .good: return Theme.statusGood
        case .neutral: return Theme.statusNeutral
        }
    }

    var label: String {
        switch self {
        case .overdue: return "OVERDUE"
        case .dueSoon: return "DUE SOON"
        case .good: return "GOOD"
        case .neutral: return ""
        }
    }
}

extension Service {
    func status(currentMileage: Int, currentDate: Date = .now) -> ServiceStatus {
        // Check if overdue by date
        if let dueDate = dueDate, currentDate > dueDate {
            return .overdue
        }

        // Check if overdue by mileage
        if let dueMileage = dueMileage, currentMileage > dueMileage {
            return .overdue
        }

        // Check if due soon (within 30 days or 500 miles)
        if let dueDate = dueDate {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: currentDate, to: dueDate).day ?? 0
            if daysUntilDue <= 30 && daysUntilDue >= 0 {
                return .dueSoon
            }
        }

        if let dueMileage = dueMileage {
            let milesUntilDue = dueMileage - currentMileage
            if milesUntilDue <= 500 && milesUntilDue >= 0 {
                return .dueSoon
            }
        }

        // Check if we have any due information
        if dueDate != nil || dueMileage != nil {
            return .good
        }

        return .neutral
    }

    var dueDescription: String? {
        if let dueDate = dueDate {
            let days = Calendar.current.dateComponents([.day], from: .now, to: dueDate).day ?? 0
            if days < 0 {
                return "\(abs(days)) days overdue"
            } else if days == 0 {
                return "Due today"
            } else if days == 1 {
                return "Due tomorrow"
            } else {
                return "Due in \(days) days"
            }
        }
        return nil
    }

    @MainActor
    var mileageDescription: String? {
        guard let dueMileage = dueMileage, let vehicle = vehicle else { return nil }
        let milesRemaining = dueMileage - vehicle.currentMileage
        let unit = DistanceSettings.shared.unit
        let displayRemaining = unit.fromMiles(abs(milesRemaining))
        if milesRemaining < 0 {
            return "\(displayRemaining) \(unit.fullName) overdue"
        } else {
            return "or \(displayRemaining) \(unit.fullName)"
        }
    }

    /// Primary description prioritizing miles over days
    /// Mileage is the default tracking method; date is fallback for services where mileage doesn't apply
    @MainActor
    var primaryDescription: String? {
        if let dueMileage = dueMileage, let vehicle = vehicle {
            let milesRemaining = dueMileage - vehicle.currentMileage
            let unit = DistanceSettings.shared.unit
            let displayRemaining = unit.fromMiles(abs(milesRemaining))
            if milesRemaining < 0 {
                return "\(displayRemaining) \(unit.fullName) overdue"
            } else if milesRemaining == 0 {
                return "Due now"
            } else {
                return "\(displayRemaining) \(unit.fullName) remaining"
            }
        }
        return dueDescription  // Fallback to date-based for services without mileage tracking
    }

    /// Returns urgency score for sorting (lower = more urgent)
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - currentDate: Current date (defaults to now)
    ///   - dailyPace: Optional daily driving pace in miles; falls back to 40 mi/day if not provided
    func urgencyScore(currentMileage: Int, currentDate: Date = .now, dailyPace: Double? = nil) -> Int {
        var score = Int.max

        // Date-based urgency
        if let dueDate = dueDate {
            let days = Calendar.current.dateComponents([.day], from: currentDate, to: dueDate).day ?? Int.max
            score = min(score, days)
        }

        // Mileage-based urgency (use actual pace or default 40 miles/day)
        if let dueMileage = dueMileage {
            let milesRemaining = dueMileage - currentMileage
            let effectivePace = dailyPace ?? 40.0
            let daysEquivalent = Int(Double(milesRemaining) / effectivePace)
            score = min(score, daysEquivalent)
        }

        return score
    }

    /// Predict when mileage threshold will be reached based on driving pace
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - dailyPace: Daily driving pace in miles
    /// - Returns: Predicted date when due mileage will be reached, or nil if not applicable
    func predictedDueDate(currentMileage: Int, dailyPace: Double?) -> Date? {
        guard let pace = dailyPace, pace > 0,
              let dueMileage = dueMileage else { return nil }

        let milesRemaining = dueMileage - currentMileage
        guard milesRemaining > 0 else { return nil }

        let daysUntilDue = Int(ceil(Double(milesRemaining) / pace))
        return Calendar.current.date(byAdding: .day, value: daysUntilDue, to: .now)
    }

    /// Returns the earlier of due date or predicted mileage date
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - dailyPace: Daily driving pace in miles
    /// - Returns: The effective due date (whichever comes first), or nil if neither is set
    func effectiveDueDate(currentMileage: Int, dailyPace: Double?) -> Date? {
        let calendarDate = dueDate
        let predictedDate = predictedDueDate(currentMileage: currentMileage, dailyPace: dailyPace)

        switch (calendarDate, predictedDate) {
        case (nil, nil): return nil
        case (let date?, nil): return date
        case (nil, let predicted?): return predicted
        case (let date?, let predicted?): return min(date, predicted)
        }
    }
}

// MARK: - Sample Data

extension Service {
    static func sampleServices(for vehicle: Vehicle) -> [Service] {
        let calendar = Calendar.current

        let oilChange = Service(
            name: "Oil change",
            dueDate: calendar.date(byAdding: .day, value: 12, to: .now),
            dueMileage: vehicle.currentMileage + 500,
            lastPerformed: calendar.date(byAdding: .month, value: -5, to: .now),
            lastMileage: vehicle.currentMileage - 4500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        oilChange.vehicle = vehicle

        let tireRotation = Service(
            name: "Tire rotation",
            dueDate: calendar.date(byAdding: .day, value: 45, to: .now),
            dueMileage: vehicle.currentMileage + 2500,
            lastPerformed: calendar.date(byAdding: .month, value: -3, to: .now),
            lastMileage: vehicle.currentMileage - 2500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        tireRotation.vehicle = vehicle

        let brakeInspection = Service(
            name: "Brake inspection",
            dueDate: calendar.date(byAdding: .day, value: -5, to: .now),
            dueMileage: vehicle.currentMileage - 200,
            lastPerformed: calendar.date(byAdding: .year, value: -1, to: .now),
            lastMileage: vehicle.currentMileage - 12000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        brakeInspection.vehicle = vehicle

        let airFilter = Service(
            name: "Air filter replacement",
            dueDate: calendar.date(byAdding: .month, value: 4, to: .now),
            dueMileage: vehicle.currentMileage + 8000,
            lastPerformed: calendar.date(byAdding: .year, value: -1, to: .now),
            lastMileage: vehicle.currentMileage - 12000,
            intervalMonths: 12,
            intervalMiles: 15000
        )
        airFilter.vehicle = vehicle

        return [oilChange, tireRotation, brakeInspection, airFilter]
    }
}
