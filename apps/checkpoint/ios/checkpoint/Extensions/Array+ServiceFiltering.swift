//
//  Array+ServiceFiltering.swift
//  checkpoint
//
//  Convenience extension for filtering and sorting services by vehicle
//

import Foundation

extension Array where Element: Service {
    /// Filter services belonging to a given vehicle, sorted by urgency (most urgent first)
    ///
    /// Prefer `sortedByUrgency(_:)` when the array already came from a
    /// vehicle-scoped `@Query`: the predicate did the filtering in the store, and
    /// re-checking `$0.vehicle?.id` here faults the relationship once per row.
    func forVehicle(_ vehicle: Vehicle) -> [Service] {
        let vehicleID = vehicle.id
        return filter { $0.vehicle?.id == vehicleID }.sortedByUrgency(vehicle.mileageEstimate)
    }

    /// Sort by urgency (most urgent first) against an already-resolved mileage
    /// estimate.
    ///
    /// Each score is computed once and sorted on. Scoring from inside the
    /// comparator instead costs two `urgencyScore` calls per comparison, each
    /// doing calendar math — O(n log n) date arithmetic for one sort.
    func sortedByUrgency(_ mileage: MileageEstimate) -> [Service] {
        map { service in
            (
                service: service as Service,
                score: service.urgencyScore(currentMileage: mileage.effective, dailyPace: mileage.pace)
            )
        }
        .sorted { $0.score < $1.score }
        .map(\.service)
    }

    /// Filter services with due tracking for a vehicle, sorted by urgency (most urgent first).
    /// Excludes log-only / neutral services that have no dueDate or dueMileage.
    func forVehicleUpcoming(_ vehicle: Vehicle) -> [Service] {
        forVehicle(vehicle).filter { $0.hasDueTracking }
    }
}
