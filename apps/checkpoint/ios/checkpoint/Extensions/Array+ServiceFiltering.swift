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

    /// The tracked service a newly logged entry named `name` completes, or nil
    /// when the entry should stand on its own.
    ///
    /// A log matches when the vehicle has a service of the same name
    /// (case-insensitive) still on the schedule. Without this, logging an oil
    /// change from [+] created a second "Oil Change" beside the one counting
    /// down — which stayed overdue forever, because nothing completed it.
    ///
    /// Backfill never matches: an entry older than the newest record of that
    /// service is history, and completing the live occurrence with it would
    /// move its schedule backwards. When several occurrences match, the most
    /// urgent is the one the user is resolving.
    func activeMatch(
        named name: String,
        for vehicle: Vehicle,
        performedDate: Date,
        logs: [ServiceLog]
    ) -> Service? {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return nil }

        if let newest = logs.mostRecent(serviceName: needle, vehicle: vehicle),
           newest.performedDate > performedDate {
            return nil
        }

        let vehicleID = vehicle.id
        let candidates = filter { service in
            service.vehicle?.id == vehicleID
                && service.hasDueTracking
                && service.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle
                && (service.lastPerformed ?? .distantPast) <= performedDate
        }
        guard !candidates.isEmpty else { return nil }
        return candidates.sortedByUrgency(vehicle.mileageEstimate).first
    }
}
