//
//  PendingOdometerUpdate.swift
//  VehicleSharing
//
//  An odometer reading queued by a companion app (Biombo) for Checkpoint to
//  validate and commit on its next foreground.
//

import Foundation

/// A reading queued by Biombo for Checkpoint to apply. Checkpoint stays the
/// source of truth: it decides whether to commit this (e.g. rejecting
/// nonsensical values) and owns the resulting `MileageSnapshot`.
public struct PendingOdometerUpdate: Codable, Sendable, Identifiable, Equatable {
    /// Unique id for the queued update, so duplicates can be de-duplicated.
    public let id: UUID
    /// The target vehicle's UUID string.
    public let vehicleID: String
    /// The reading, in **miles** (already converted from the user's unit).
    public let mileage: Int
    /// When the reading was entered.
    public let recordedAt: Date

    public init(
        id: UUID = UUID(),
        vehicleID: String,
        mileage: Int,
        recordedAt: Date
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.mileage = mileage
        self.recordedAt = recordedAt
    }
}
