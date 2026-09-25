//
//  Service+Descriptions.swift
//  checkpoint
//
//  Human-readable descriptions for service due status
//

import Foundation

extension Service {
    /// How urgent this service is, in the unit the user actually tracks:
    /// "400 mi overdue", "12 days left". Mileage leads when the service has a
    /// mileage trigger, since that's what the odometer answers; otherwise the
    /// date does. Nil when the service has no due tracking.
    ///
    /// Shared by the list row and the add form's "Completes …" advisory, so
    /// both describe a service identically. Pass the vehicle's *effective*
    /// mileage, the value its status is judged by.
    @MainActor
    func urgencyText(currentMileage: Int, now: Date = .now) -> String? {
        if let dueMileage {
            let miles = dueMileage - currentMileage
            if miles < 0 { return L10n.rowDistanceOverdue(Formatters.mileage(-miles)) }
            if miles == 0 { return L10n.rowDueNow }
            return L10n.rowDistanceLeft(Formatters.mileage(miles))
        }
        if let dueDate {
            let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
            if days < 0 { return L10n.rowDaysOverdue(-days) }
            if days == 0 { return L10n.rowDueToday }
            if days == 1 { return L10n.rowDueTomorrow }
            return L10n.rowDaysLeft(days)
        }
        return nil
    }

    var dueDescription: String? {
        if let dueDate = dueDate {
            let days = Calendar.current.dateComponents([.day], from: .now, to: dueDate).day ?? 0
            if days < 0 {
                return L10n.descDaysOverdue(abs(days))
            } else if days == 0 {
                return L10n.descDueToday
            } else if days == 1 {
                return L10n.descDueTomorrow
            } else {
                return L10n.descDueInDays(days)
            }
        }
        return nil
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
                return L10n.descDistanceOverdue("\(displayRemaining)", unit.fullName)
            } else if milesRemaining == 0 {
                return L10n.descDueNow
            } else {
                return L10n.descDistanceRemaining("\(displayRemaining)", unit.fullName)
            }
        }
        return dueDescription  // Fallback to date-based for services without mileage tracking
    }

    /// Average cost across all standalone service logs with cost data.
    /// Logs bound to a Service Visit are excluded — attributing a visit's
    /// shared total to a single child service would be misleading.
    func averageCost(from logs: [ServiceLog]) -> Decimal? {
        let standaloneLogsWithCost = logs.filter { $0.visit == nil && $0.cost != nil }
        guard !standaloneLogsWithCost.isEmpty else { return nil }
        let totalCost = standaloneLogsWithCost.compactMap { $0.cost }.reduce(Decimal.zero, +)
        return totalCost / Decimal(standaloneLogsWithCost.count)
    }
}
