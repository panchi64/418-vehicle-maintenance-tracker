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
    var name: String = ""
    var dueDate: Date?
    var dueMileage: Int?
    var lastPerformed: Date?
    var lastMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var notificationID: String?
    var notes: String?

    var vehicle: Vehicle?

    @Relationship(deleteRule: .cascade, inverse: \ServiceLog.service)
    var logs: [ServiceLog]? = []

    init(
        name: String,
        dueDate: Date? = nil,
        dueMileage: Int? = nil,
        lastPerformed: Date? = nil,
        lastMileage: Int? = nil,
        intervalMonths: Int? = nil,
        intervalMiles: Int? = nil,
        notificationID: String? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.lastPerformed = lastPerformed
        self.lastMileage = lastMileage
        self.intervalMonths = intervalMonths
        self.intervalMiles = intervalMiles
        self.notificationID = notificationID
        self.notes = notes
    }
}

// MARK: - Service Status

/// Whether this service has due-date or due-mileage tracking configured.
/// Services without tracking are log-only (neutral) and should not appear in upcoming lists.
extension Service {
    var hasDueTracking: Bool {
        dueDate != nil || dueMileage != nil
    }
}

/// Derive due deadlines from intervals, anchored to a reference point.
/// This is the single source of truth for the "interval → deadline" contract.
/// - For intervals with positive values: sets dueDate/dueMileage relative to anchor.
/// - For nil/zero intervals: clears the corresponding deadline.
extension Service {
    func deriveDueFromIntervals(anchorDate: Date, anchorMileage: Int) {
        if let months = intervalMonths, months > 0 {
            dueDate = Calendar.current.date(byAdding: .month, value: months, to: anchorDate)
        } else {
            dueDate = nil
        }
        if let miles = intervalMiles, miles > 0 {
            dueMileage = anchorMileage + miles
        } else {
            dueMileage = nil
        }
    }
}

/// Recalculate due dates after a service is marked as completed.
/// - For recurring services (with intervals): advances dueDate/dueMileage to the next occurrence.
/// - For non-recurring services: clears dueDate/dueMileage so the service becomes neutral.
extension Service {
    func recalculateDueDates(performedDate: Date, mileage: Int) {
        lastPerformed = performedDate
        lastMileage = mileage
        deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
    }
}

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
    @MainActor
    func status(currentMileage: Int, currentDate: Date = .now) -> ServiceStatus {
        // Check if overdue by date
        if let dueDate = dueDate, currentDate > dueDate {
            return .overdue
        }

        // Check if overdue by mileage
        if let dueMileage = dueMileage, currentMileage > dueMileage {
            return .overdue
        }

        // Check if due soon using customizable thresholds
        // For mileage-tracked services: use mileage threshold
        // For date-only services: use date threshold
        let mileageThreshold = DueSoonSettings.shared.mileageThreshold
        let daysThreshold = DueSoonSettings.shared.daysThreshold

        if let dueMileage = dueMileage {
            // Mileage-tracked service: only use mileage for "due soon" check
            let milesUntilDue = dueMileage - currentMileage
            if milesUntilDue <= mileageThreshold && milesUntilDue >= 0 {
                return .dueSoon
            }
        } else if let dueDate = dueDate {
            // Date-only service (no mileage tracking): use date for "due soon" check
            let daysUntilDue = Calendar.current.dateComponents([.day], from: currentDate, to: dueDate).day ?? 0
            if daysUntilDue <= daysThreshold && daysUntilDue >= 0 {
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
    /// Full set of 8 services for a daily driver (Camry) — covers all statuses
    static func sampleServices(for vehicle: Vehicle) -> [Service] {
        let calendar = Calendar.current

        // dueSoon (by date + mileage)
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

        // good
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

        // overdue (by date + mileage)
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

        // good
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

        // good
        let cabinAirFilter = Service(
            name: "Cabin air filter",
            dueDate: calendar.date(byAdding: .month, value: 3, to: .now),
            dueMileage: vehicle.currentMileage + 7000,
            lastPerformed: calendar.date(byAdding: .month, value: -9, to: .now),
            lastMileage: vehicle.currentMileage - 5000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        cabinAirFilter.vehicle = vehicle

        // good (long interval)
        let transmissionFluid = Service(
            name: "Transmission fluid",
            dueDate: calendar.date(byAdding: .month, value: 12, to: .now),
            dueMileage: vehicle.currentMileage + 20000,
            lastPerformed: calendar.date(byAdding: .month, value: -2, to: .now),
            lastMileage: vehicle.currentMileage - 1500,
            intervalMonths: 24,
            intervalMiles: 30000
        )
        transmissionFluid.vehicle = vehicle

        // dueSoon (date-only, no mileage)
        let batteryCheck = Service(
            name: "Battery check",
            dueDate: calendar.date(byAdding: .day, value: 18, to: .now),
            lastPerformed: calendar.date(byAdding: .month, value: -6, to: .now),
            intervalMonths: 6
        )
        batteryCheck.vehicle = vehicle

        // neutral (no due date or mileage)
        let wiperBlades = Service(
            name: "Wiper blades",
            lastPerformed: calendar.date(byAdding: .month, value: -14, to: .now)
        )
        wiperBlades.vehicle = vehicle

        return [oilChange, tireRotation, brakeInspection, airFilter,
                cabinAirFilter, transmissionFluid, batteryCheck, wiperBlades]
    }

    /// Compact set of 3 services for a secondary vehicle (MX-5)
    static func sampleServicesCompact(for vehicle: Vehicle) -> [Service] {
        let calendar = Calendar.current

        // good
        let oilChange = Service(
            name: "Oil change",
            dueDate: calendar.date(byAdding: .day, value: 60, to: .now),
            dueMileage: vehicle.currentMileage + 2000,
            lastPerformed: calendar.date(byAdding: .month, value: -4, to: .now),
            lastMileage: vehicle.currentMileage - 2200,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        oilChange.vehicle = vehicle

        // dueSoon
        let tireRotation = Service(
            name: "Tire rotation",
            dueDate: calendar.date(byAdding: .day, value: 15, to: .now),
            dueMileage: vehicle.currentMileage + 500,
            lastPerformed: calendar.date(byAdding: .month, value: -5, to: .now),
            lastMileage: vehicle.currentMileage - 2500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        tireRotation.vehicle = vehicle

        // good (long interval)
        let brakeInspection = Service(
            name: "Brake inspection",
            dueDate: calendar.date(byAdding: .month, value: 8, to: .now),
            dueMileage: vehicle.currentMileage + 6000,
            lastPerformed: calendar.date(byAdding: .month, value: -4, to: .now),
            lastMileage: vehicle.currentMileage - 3000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        brakeInspection.vehicle = vehicle

        return [oilChange, tireRotation, brakeInspection]
    }
}
