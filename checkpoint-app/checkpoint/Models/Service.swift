//
//  Service.swift
//  checkpoint
//
//  SwiftData model for vehicle maintenance services
//

import Foundation
import SwiftData

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

