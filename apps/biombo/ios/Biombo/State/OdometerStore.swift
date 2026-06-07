import Foundation
import Observation
import VehicleSharing

/// Reads vehicle odometers published by Checkpoint and queues updates back to
/// it via the shared App Group. Checkpoint is the source of truth; this store
/// only mirrors the published state and appends pending readings.
@MainActor
@Observable
final class OdometerStore {
    private(set) var vehicles: [SharedVehicleOdometer] = []
    var selectedID: String?

    var hasVehicles: Bool { !vehicles.isEmpty }

    /// The vehicle to display — the explicit selection, falling back to the first.
    var selectedVehicle: SharedVehicleOdometer? {
        if let selectedID, let match = vehicles.first(where: { $0.id == selectedID }) {
            return match
        }
        return vehicles.first
    }

    /// Re-read the published odometers. Safe to call on every foreground.
    func refresh() {
        vehicles = VehicleOdometerBridge.readVehicles()
        if selectedID == nil || !vehicles.contains(where: { $0.id == selectedID }) {
            selectedID = vehicles.first?.id
        }
    }

    /// Queue an odometer reading (entered in `vehicle.distanceUnit`) for
    /// Checkpoint to apply on its next foreground, and optimistically reflect it
    /// locally so the card updates immediately.
    func submit(displayValue: Int, for vehicle: SharedVehicleOdometer, at date: Date = Date()) {
        let miles = vehicle.distanceUnit.toMiles(displayValue)
        VehicleOdometerBridge.queueUpdate(
            PendingOdometerUpdate(vehicleID: vehicle.id, mileage: miles, recordedAt: date)
        )

        guard let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        vehicles[index] = vehicles[index].applyingReading(miles, at: date)
    }
}
