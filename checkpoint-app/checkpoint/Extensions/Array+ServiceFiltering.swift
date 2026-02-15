//
//  Array+ServiceFiltering.swift
//  checkpoint
//
//  Convenience extension for filtering and sorting services by vehicle
//

import Foundation

extension Array where Element: Service {
    /// Filter services belonging to a given vehicle, sorted by urgency (most urgent first)
    func forVehicle(_ vehicle: Vehicle) -> [Service] {
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace
        return self
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) < $1.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) }
    }

    /// Filter services with due tracking for a vehicle, sorted by urgency (most urgent first).
    /// Excludes log-only / neutral services that have no dueDate or dueMileage.
    func forVehicleUpcoming(_ vehicle: Vehicle) -> [Service] {
        forVehicle(vehicle).filter { $0.hasDueTracking }
    }
}
