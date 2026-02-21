//
//  Service+Status.swift
//  checkpoint
//
//  Service status computation and display
//

import SwiftUI

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
}
