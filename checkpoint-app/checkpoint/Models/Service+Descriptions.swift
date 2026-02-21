//
//  Service+Descriptions.swift
//  checkpoint
//
//  Human-readable descriptions for service due status
//

import Foundation

extension Service {
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

    /// Average cost across all service logs with cost data
    func averageCost(from logs: [ServiceLog]) -> Decimal? {
        let logsWithCost = logs.filter { $0.cost != nil }
        guard !logsWithCost.isEmpty else { return nil }
        let totalCost = logsWithCost.compactMap { $0.cost }.reduce(Decimal.zero, +)
        return totalCost / Decimal(logsWithCost.count)
    }
}
